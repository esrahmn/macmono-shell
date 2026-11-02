#!/usr/bin/env bash
# Pilih area layar lalu cari lewat Google Lens.
# PERHATIAN: gambar diunggah ke host publik uguu.se supaya Lens bisa membukanya.
umask 077
dir="${XDG_RUNTIME_DIR:-/tmp}"
img="$(mktemp --suffix=.png "$dir/snip-search.XXXXXX")" || exit 1
trap 'rm -f "$img"' EXIT

geom="$(slurp)" || exit 0          # dibatalkan -> keluar tanpa mengunggah apa pun
[ -n "$geom" ] || exit 0
grim -g "$geom" "$img" || exit 1

link="$(curl -sf -F "files[]=@$img" 'https://uguu.se/upload' | jq -r '.files[0].url // empty')"
if [ -z "$link" ]; then
    notify-send -u normal "Google Lens" "Failed to upload image" 2>/dev/null
    exit 1
fi
xdg-open "https://lens.google.com/uploadbyurl?url=${link}"
