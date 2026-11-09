#!/bin/bash
# macmono: shell hidup -> Sys.qml yang ngurus peringatan baterai. Skrip ini cuma cadangan.
# (BAT_TEST tetap jalan buat ngetes notifikasi manual)
if [ -z "${BAT_TEST:-}" ]; then
    pgrep -x qs >/dev/null 2>&1 && exit 0
    pgrep -x quickshell >/dev/null 2>&1 && exit 0
fi
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -z "$bat" ] && exit 0
if [ -n "$BAT_TEST" ]; then
  cap=$BAT_TEST; st=Discharging
else
  cap=$(cat "$bat/capacity"); st=$(cat "$bat/status")
fi
[ "$st" = "Discharging" ] || exit 0
if [ "$cap" -le 5 ]; then
  notify-send -u critical "Baterai kritis" "Sisa ${cap}%, colok charger sekarang"
elif [ "$cap" -le 15 ]; then
  notify-send -u normal "Baterai tipis" "Sisa ${cap}%"
fi
