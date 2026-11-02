#!/usr/bin/env bash
# Jalankan hyprlock dengan tema macmono.
#   $1 = path wallpaper macmono (boleh kosong -> pakai screenshot layar)
#   $2 = 1 kalau mode Monochrome nyala (wallpaper lock dibikin abu-abu juga)
pidof hyprlock >/dev/null && exit 0

here="$(cd "$(dirname "$0")" && pwd)"
state="$HOME/.local/state/macmono"
mkdir -p "$state"
src="$1"
mono="${2:-1}"

# ---------- latar: wallpaper (di-cache, cuma diproses ulang kalau wallpaper/mode berubah)
bg=""
if [ -n "$src" ] && [ -f "$src" ]; then
    key="$src|$mono|$(stat -c %Y "$src")"
    M="$(command -v magick || command -v convert)"
    if [ -n "$M" ]; then
        bg="$state/lock-bg.png"
        if [ ! -s "$bg" ] || [ "$(cat "$state/lock-bg.key" 2>/dev/null)" != "$key" ]; then
            if [ "$mono" = 1 ]; then
                "$M" "$src" -resize '2560x1440^' -colorspace Gray "$bg" 2>/dev/null
            else
                "$M" "$src" -resize '2560x1440^' "$bg" 2>/dev/null
            fi
            printf '%s' "$key" > "$state/lock-bg.key"
        fi
    else
        bg="$src"
    fi
    [ -s "$bg" ] || bg=""
fi

# ---------- avatar
avatar=""
for f in "$HOME/.face" "$HOME/.face.icon" "/var/lib/AccountsService/icons/$USER"; do
    if [ -d "$f" ]; then
        # ~/.face berupa FOLDER: ambil gambar pertama di dalamnya
        img=$(find "$f" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n1)
        [ -n "$img" ] && { avatar="$img"; break; }
    elif [ -f "$f" ] && [ -s "$f" ]; then
        avatar="$f"; break
    fi
done

# ---------- rakit config dari template
conf="$state/hyprlock.conf"
cp "$here/hyprlock.conf" "$conf"
[ -n "$bg" ] && sed -i "/@BG@/c\\    path = $bg" "$conf"
if [ -n "$avatar" ]; then
    sed -i "/@AVATAR@/c\\    path = $avatar" "$conf"
    sed -i '/#initials-begin/,/#initials-end/d' "$conf"
else
    sed -i '/#avatar-begin/,/#avatar-end/d' "$conf"
fi

# font: pakai nama keluarga Inter yang benar-benar terpasang ("Inter" atau "Inter Variable")
fam=$(fc-list : family 2>/dev/null | tr ',' '\n' | grep -m1 -xE 'Inter|Inter Variable|Inter Var')
[ -n "$fam" ] && sed -i "s/^\(\s*font_family = \)Inter\s*$/\1$fam/" "$conf"

exec hyprlock -c "$conf"
