#!/usr/bin/env bash
# Tulis ~/.config/hypr/custom/macmono-generated.lua dengan aman.
#
# SATU file generated untuk semua setelan macmono. Isinya dibagi jadi blok bertanda:
#   -- >>> macmono:monitors
#   ...
#   -- <<< macmono:monitors
# Tiap bagian cuma menimpa blok miliknya, jadi menulis monitor nggak menghapus input.
# Jangan bikin file generated kedua: bagian baru = blok baru di file yang sama.
#
#   apply [detik]   isi blok baru dibaca dari stdin; backup, reload, cek error.
#                   Kalau ada error baru: otomatis balik ke versi lama (exit 1).
#                   Kalau [detik] diisi: tanpa "confirm" dalam waktu itu, balik otomatis
#                   (proses terpisah, jadi tetap balik walau shell macet).
#                   Balik otomatis / restore cuma mengembalikan blok milik --section itu,
#                   jadi apply bagian lain di tengah jalan (mis. input saat monitor masih
#                   menunggu konfirmasi) nggak ikut terbatalkan atau tertukar.
#   confirm         tandai perubahan diterima (batalkan balik otomatis).
#   restore         balik ke versi sebelumnya sekarang juga (blok --section saja).
# Opsi di depan: --section <nama>  nama blok yang ditulis (default: monitors).
# Lihat Hypr: hyprctl reload + hyprctl configerrors (dicek ke wiki 0.57).
set -u
umask 077

SECTION="monitors"
while [ $# -gt 0 ]; do
    case "$1" in
    --section) SECTION="${2:-}"; shift 2 ;;
    *) break ;;
    esac
done
case "$SECTION" in
'' | *[!a-z]*) echo "section harus huruf kecil a-z" >&2; exit 2 ;;
esac

cmd="${1:-}"
[ $# -gt 0 ] && shift

DIR="$HOME/.config/hypr/custom"
F="$DIR/macmono-generated.lua"
B="$F.bak"
LEGACY="$DIR/macmono-generated-input.lua"
RT="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR kosong}/macmono"
P="$RT/generated.$SECTION.pending"   # ada = bagian ini menunggu konfirmasi (isi = token apply)
PREV="$RT/generated.$SECTION.prev"   # isi blok sebelum apply terakhir
PREVHAS="$RT/generated.$SECTION.had" # ada = blok itu memang sudah ada sebelum apply

errs() { hyprctl configerrors 2>&1 | sed '/^[[:space:]]*$/d'; }
reload() { hyprctl reload >/dev/null 2>&1; sleep 0.7; }
# Balik seluruh file ke backup. Dipakai saat apply barusan gagal (backup baru dibuat sedetik lalu,
# jadi aman). Jangan dipakai untuk watchdog/restore: backup bisa sudah ditimpa apply bagian lain.
rollback_all() {
    rm -f "$P"
    if [ -f "$B" ]; then mv -f "$B" "$F"; else rm -f "$F"; fi
    reload
}
# Balik blok $SECTION saja ke isi sebelum apply; blok bagian lain dibiarkan.
rollback() {
    rm -f "$P"
    if [ ! -f "$PREV" ] || [ ! -f "$F" ]; then rollback_all; return; fi
    local had=0 tmp
    [ -f "$PREVHAS" ] && had=1
    tmp="$(mktemp "$RT/rb.XXXXXX")" || return 1
    awk -v n="$SECTION" -v prev="$PREV" -v had="$had" '
        $0 == "-- >>> macmono:" n {
            skipping = 1
            if (had) {
                print
                while ((getline line < prev) > 0) print line
                close(prev)
                print "-- <<< macmono:" n
            }
            next
        }
        $0 == "-- <<< macmono:" n { skipping = 0; next }
        skipping { next }
        { print }
    ' "$F" > "$tmp"
    cat "$tmp" > "$F"
    rm -f "$tmp"
    reload
}

begin() { printf -- '-- >>> macmono:%s\n' "$1"; }
end() { printf -- '-- <<< macmono:%s\n' "$1"; }

has_block() {
    [ -f "$2" ] && grep -qxF -- "-- >>> macmono:$1" "$2"
}
block() {
    [ -f "$2" ] || return 0
    awk -v n="$1" '
        $0 == "-- >>> macmono:" n { inblk = 1; next }
        $0 == "-- <<< macmono:" n { inblk = 0; next }
        inblk { print }
    ' "$2"
}

case "$cmd" in
apply)
    mkdir -p "$DIR" "$RT"
    body="$(mktemp "$RT/body.XXXXXX")" || exit 2
    cat > "$body"

    # Sumber blok lama. File lama tanpa penanda = format lama (seluruh isinya monitor),
    # dan file generated-input yang lama diserap jadi blok "input" supaya setelan user hilang.
    seed="$(mktemp "$RT/seed.XXXXXX")" || exit 2
    if [ -f "$F" ] && grep -q '^-- >>> macmono:' "$F"; then
        cp -f "$F" "$seed"
    else
        {
            if [ -f "$F" ]; then begin monitors; sed '/^-- Dibuat oleh macmono/d' "$F"; end monitors; fi
            if [ -f "$LEGACY" ]; then begin input; sed '/^-- Dibuat oleh macmono/d' "$LEGACY"; end input; fi
        } > "$seed"
    fi

    extras="$(grep -h '^-- >>> macmono:[a-z]*$' "$seed" 2>/dev/null | sed 's/^-- >>> macmono://' | grep -vxE 'monitors|input' | tr '\n' ' ')"
    names="monitors input $extras"
    case " $names " in
    *" $SECTION "*) ;;
    *) names="$names $SECTION" ;;
    esac

    out="$(mktemp "$RT/out.XXXXXX")" || exit 2
    {
        printf '%s\n' "-- Dibuat oleh macmono Settings. Jangan edit manual: bakal ditimpa."
        printf '%s\n' "-- Satu file untuk semua setelan macmono; tiap bagian ditulis terpisah."
        for n in $names; do
            if [ "$n" = "$SECTION" ]; then
                begin "$n"
                sed '/^-- Dibuat oleh macmono/d' "$body"
                end "$n"
            elif has_block "$n" "$seed"; then
                begin "$n"
                block "$n" "$seed"
                end "$n"
            fi
        done
    } > "$out"

    # Foto isi blok lama buat rollback per bagian. Kalau bagian ini masih menunggu konfirmasi
    # (apply kedua sebelum confirm), foto lama dipertahankan: baliknya tetap ke versi asli.
    if [ ! -f "$P" ]; then
        rm -f "$PREV" "$PREVHAS"
        block "$SECTION" "$seed" > "$PREV"
        has_block "$SECTION" "$seed" && : > "$PREVHAS"
    fi

    before="$(errs)"
    if [ -f "$F" ]; then cp -f "$F" "$B"; else rm -f "$B"; fi
    cat "$out" > "$F" # lewat path (bukan mv) supaya symlink dotfiles tetap utuh
    rm -f "$out" "$body" "$seed"

    reload
    after="$(errs)"
    if [ "$after" != "$before" ]; then
        printf '%s\n' "$after" >&2
        rollback_all
        exit 1
    fi

    # Konsolidasi: file generated lama sudah diserap ke dalam blok, jadi dibuang.
    rm -f "$LEGACY" "$LEGACY.bak"

    if [ -n "${1:-}" ]; then
        tok="$$-$(date +%s%N)"
        printf '%s' "$tok" > "$P"
        setsid -f bash "$0" --section "$SECTION" watchdog "$1" "$tok" >/dev/null 2>&1
    else
        rm -f "$P"
    fi
    ;;
watchdog)
    sleep "${1:-15}"
    # Token harus sama: watchdog dari apply lama nggak boleh membatalkan apply yang lebih baru.
    [ -f "$P" ] && [ "$(cat "$P" 2>/dev/null)" = "${2:-}" ] && rollback
    ;;
confirm) rm -f "$P" ;;
restore) rollback ;;
*)
    echo "pakai: $0 [--section nama] apply [detik] | confirm | restore" >&2
    exit 2
    ;;
esac
