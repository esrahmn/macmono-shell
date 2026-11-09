#!/usr/bin/env bash
# Equalizer sistem lewat Easy Effects (CLI -b dan -l dicek ke wiki "Command Line Options" dan
# source command_line_parser.cpp Easy Effects 8.x).
#   enable   baca preset JSON dari stdin, simpan sebagai preset output "macmono-eq", matikan
#            bypass global, lalu muat preset itu. MENGGANTI preset output yang sedang aktif.
#   disable  nyalakan bypass global (semua efek mati). File preset di disk tidak diubah.
# Exit: 0 ok | 2 salah pakai | 3 Easy Effects belum jalan | 4 belum terpasang | 1 gagal lain
set -u
umask 077
NAME="macmono-eq"

if command -v easyeffects >/dev/null 2>&1; then
  EE=(easyeffects)
  DIR="${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects"
elif command -v flatpak >/dev/null 2>&1 && flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1; then
  EE=(flatpak run com.github.wwmm.easyeffects)
  DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects"
else
  echo "Easy Effects is not installed." >&2; exit 4
fi
pgrep -x easyeffects >/dev/null 2>&1 || { echo "Easy Effects is not running." >&2; exit 3; }

ee() { timeout 8 "${EE[@]}" "$@" >/dev/null 2>&1; }

case "${1:-}" in
enable)
  json="$(cat)"
  case "$json" in *'"equalizer#0"'*) ;; *) echo "Invalid equalizer preset." >&2; exit 2 ;; esac
  mkdir -p "$DIR/output"
  tmp="$(mktemp "$DIR/output/.${NAME}.XXXXXX")" || exit 1
  printf '%s\n' "$json" > "$tmp"
  mv -f "$tmp" "$DIR/output/$NAME.json"
  ee -b 2
  sleep 0.2
  ee -l "$NAME" || { echo "Easy Effects did not accept the preset." >&2; exit 1; }
  ;;
disable)
  ee -b 1 || { echo "Could not bypass Easy Effects." >&2; exit 1; }
  ;;
*) echo "usage: $0 enable|disable" >&2; exit 2 ;;
esac
