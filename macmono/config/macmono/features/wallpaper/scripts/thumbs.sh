#!/bin/sh
out="$HOME/.cache/macmono/thumbs"
mkdir -p "$out"
im=magick; command -v magick >/dev/null || im=convert
command -v "$im" >/dev/null || exit 0
for f in "$@"; do
    key=$(printf '%s' "$f" | md5sum | cut -c1-32)
    t="$out/$key.jpg"
    [ -s "$t" ] && continue
    nice -n 19 "$im" "$f[0]" -auto-orient -thumbnail '480x270^' -gravity center -extent 480x270 -quality 85 "$t" 2>/dev/null
done
