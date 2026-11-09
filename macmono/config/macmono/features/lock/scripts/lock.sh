#!/usr/bin/env bash
pidof hyprlock >/dev/null && exit 0

here="$(cd "$(dirname "$0")" && pwd)"
state="$HOME/.local/state/macmono"
mkdir -p "$state"
src="${1-$(cat "$state/wallpaper" 2>/dev/null)}"
mono="${2-$(cat "$state/wallpaper_mono" 2>/dev/null)}"
[ "$mono" = 0 ] || mono=1
export MACMONO_MONO="$mono"

M="$(command -v magick || command -v convert)"

read -r nmon primary res < <(hyprctl monitors 2>/dev/null | awk '
    /^Monitor /                     { c++; n = $2 }
    /^[[:space:]]+[0-9]+x[0-9]+@/   { split($1, a, "@"); r = a[1] }
    /focused: yes/ && !f            { f = 1; fn = n; fr = r }
    END                             { print c + 0, (fn ? fn : "-"), (fr ? fr : "-") }')
[[ "$res" =~ ^[0-9]+x[0-9]+$ ]] || res="1920x1080"

bg=""
baked=0
if [ -n "$src" ] && [ -f "$src" ]; then
    if [ -n "$M" ]; then
        key="v2|$src|$mono|$res|$(stat -c %Y "$src")"
        bg="$state/lock-bg.jpg"
        if [ ! -s "$bg" ] || [ "$(<"$state/lock-bg.key")" != "$key" ] 2>/dev/null; then
            gray=()
            [ "$mono" = 1 ] && gray=(-colorspace Gray)
            "$M" "$src" -resize "${res}^" -gravity center -extent "$res" "${gray[@]}" \
                -resize 25% -blur 0x4 -resize "${res}!" \
                -modulate 55 -quality 90 "jpg:$bg.part" 2>/dev/null \
                && mv "$bg.part" "$bg" \
                && printf '%s' "$key" > "$state/lock-bg.key"
            rm -f "$bg.part"
        fi
        [ -s "$bg" ] && baked=1
    else
        bg="$src"
    fi
    [ -s "$bg" ] || { bg=""; baked=0; }
fi

avatar=""
for f in "$HOME/.face" "$HOME/.face.icon" "/var/lib/AccountsService/icons/$USER"; do
    if [ -d "$f" ]; then
        img=$(find "$f" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n1)
        [ -n "$img" ] && { avatar="$img"; break; }
    elif [ -f "$f" ] && [ -s "$f" ]; then
        avatar="$f"; break
    fi
done

if [ -n "$avatar" ] && [ -n "$M" ]; then
    akey="$avatar|$(stat -Lc '%Y-%s' "$avatar" 2>/dev/null)"
    small="$state/lock-avatar.png"
    if [ ! -s "$small" ] || [ "$(<"$state/lock-avatar.key")" != "$akey" ] 2>/dev/null; then
        "$M" "${avatar}[0]" -auto-orient -resize 256x256^ -gravity center -extent 256x256 "png:$small.part" 2>/dev/null \
            && mv "$small.part" "$small" \
            && printf '%s' "$akey" > "$state/lock-avatar.key"
        rm -f "$small.part"
    fi
    [ -s "$small" ] && avatar="$small"
fi

has_player=0
playerctl -l 2>/dev/null | grep -q . && has_player=1

art="$state/lock-art-none.png"
if [ "$has_player" = 1 ]; then
    for f in "$state"/lock-art-*.png; do
        [ -s "$f" ] && [ "$f" != "$state/lock-art-none.png" ] && { art="$f"; break; }
    done
    (bash "$here/music.sh" art >/dev/null 2>&1 &)
fi

fontcache="$state/lock-font"
if [ -f "$fontcache" ]; then
    fam="$(<"$fontcache")"
else
    fam=$(fc-list : family 2>/dev/null | tr ',' '\n' | grep -m1 -xE 'Inter|Inter Variable|Inter Var')
    printf '%s' "$fam" > "$fontcache"
fi

conf="$state/hyprlock.conf"
args=()
if [ -n "$bg" ]; then
    args+=(-e "/@BG@/c\\    path = $bg")
fi
if [ "$baked" = 1 ]; then
    args+=(-e "/@BLUR@/c\\    blur_passes = 0"
           -e "/@BRIGHT@/c\\    brightness = 1.0"
           -e "/@NOISE@/c\\    noise = 0")
fi
if [ -n "$avatar" ]; then
    args+=(-e "/@AVATAR@/c\\    path = $avatar" -e '/#initials-begin/,/#initials-end/d')
else
    args+=(-e '/#avatar-begin/,/#avatar-end/d')
fi
[ "$has_player" = 1 ] || args+=(-e '/#media-begin/,/#media-end/d')
args+=(-e "s|@HERE@|$here|g; s|@STATE@|$state|g; s|@ART@|$art|g")
[ -n "$fam" ] && args+=(-e "s/^\(\s*font_family = \)Inter\s*$/\1$fam/")
if [ "$nmon" -gt 1 ] 2>/dev/null && [ "$primary" != "-" ]; then
    args+=(-e "/^background/,/^}/!s/^\(\s*monitor =\)\s*$/\1 $primary/")
fi

sed "${args[@]}" "$here/../config/hyprlock.conf" > "$conf"

exec hyprlock -c "$conf"
