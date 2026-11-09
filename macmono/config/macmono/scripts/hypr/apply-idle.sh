#!/usr/bin/env bash
# Tulis ~/.config/hypr/hypridle.conf dari tiga angka (menit), lalu mulai ulang hypridle.
#   apply <lock> <screen_off> <suspend>     0 = langkah itu dimatikan
# Kalau hypridle nggak mau jalan lagi: file lama dikembalikan dan hypridle dijalankan ulang (exit 1).
# Sintaks listener/general dicek ke wiki.hypr.land (Hypr Ecosystem > hypridle): timeout dalam detik,
# on-timeout, on-resume. Isi perintahnya sama persis dengan hypridle.conf bawaan macmono.
set -u
umask 077
F="$HOME/.config/hypr/hypridle.conf"
B="$F.macmono.bak"
# Folder shell macmono, dihitung dari lokasi skrip ini (scripts/hypr/ -> naik dua tingkat).
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() { echo "pakai: $0 apply <lock_menit> <layar_mati_menit> <suspend_menit>  (0 = mati)" >&2; exit 2; }
[ "${1:-}" = apply ] || usage
valid() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -le 600 ]; }
for v in "${2:-}" "${3:-}" "${4:-}"; do valid "$v" || { echo "nilai menit tidak valid: '${v}'" >&2; exit 2; }; done
LOCK=$2; OFF=$3; SUSP=$4

gen() {
  cat <<'EOF'
# Dibuat oleh macmono Settings > Power. Jangan edit manual: bakal ditimpa.
# Lock utama = lock QML macmono (instan, shell udah hidup).
# Kalau qs lagi mati / crash, `qs ipc call` gagal -> jatuh ke hyprlock lewat lock.sh.
EOF
  printf '$lock_cmd = qs -c macmono ipc call lock activate || bash "%s/features/lock/scripts/lock.sh"\n' "$SHELL_DIR"
  cat <<'EOF'
$suspend_cmd = systemctl suspend || loginctl suspend

general {
    lock_cmd = $lock_cmd
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = qs -c macmono ipc call lock focus
    inhibit_sleep = 3
}
EOF
  if [ "$LOCK" -gt 0 ]; then
    cat <<EOF

listener {
    timeout = $((LOCK * 60)) # ${LOCK}min
    on-timeout = loginctl lock-session
}
EOF
  fi
  if [ "$OFF" -gt 0 ]; then
    cat <<EOF

listener {
    timeout = $((OFF * 60)) # ${OFF}min
    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
}
EOF
  fi
  if [ "$SUSP" -gt 0 ]; then
    cat <<EOF

listener {
    timeout = $((SUSP * 60)) # ${SUSP}min
    on-timeout = \$suspend_cmd
}
EOF
  fi
}

hypr_sig() {
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then printf '%s' "$HYPRLAND_INSTANCE_SIGNATURE"; return; fi
  ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -n1
}
start_idle() {
  local sig; sig="$(hypr_sig)"
  HYPRLAND_INSTANCE_SIGNATURE="$sig" setsid -f hypridle >/dev/null 2>&1
}
# hypridle nggak punya reload, jadi dimatikan lalu dinyalakan lagi. Kalau ada yang menyalakannya
# sendiri (mis. unit systemd dengan Restart=), jangan bikin proses kedua.
restart_idle() {
  pkill -x hypridle 2>/dev/null
  sleep 1
  pgrep -x hypridle >/dev/null || start_idle
  sleep 0.8
  pgrep -x hypridle >/dev/null
}

mkdir -p "$(dirname "$F")"
tmp="$(mktemp "${F}.XXXXXX")" || exit 2
gen > "$tmp"
if [ -f "$F" ]; then cp -f "$F" "$B"; fi
cat "$tmp" > "$F"   # tulis lewat path (bukan mv) supaya symlink dotfiles tetap utuh
rm -f "$tmp"

if ! restart_idle; then
  echo "hypridle gagal jalan dengan config baru; config lama dikembalikan." >&2
  if [ -f "$B" ]; then cat "$B" > "$F"; fi
  restart_idle || true
  exit 1
fi
