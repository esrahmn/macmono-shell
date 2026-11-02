#!/bin/sh
# macmono: logout bertahap, dengan log di ~/.local/state/macmono/session.log
# 1) tutup semua window pelan-pelan  2) Hyprland exit  3) kalau masih hidup: uwsm stop
# 4) loginctl terminate-session (BUKAN terminate-user)  5) pkill
log="$HOME/.local/state/macmono/session.log"
mkdir -p "$(dirname "$log")"
exec >>"$log" 2>&1
echo "=== logout $(date) ==="
echo "XDG_SESSION_ID=$XDG_SESSION_ID HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"

alive() { pgrep -x Hyprland >/dev/null 2>&1; }

echo "step 1: close windows"
hyprctl clients -j 2>&1 | jq -r '.[].address' 2>&1 | while read -r a; do
    [ -n "$a" ] && hyprctl dispatch "hl.dsp.window.close({ window = \"address:$a\" })"
done
sleep 0.7

echo "step 2: hyprland exit"
hyprctl dispatch 'hl.dsp.exit()'
sleep 2
alive || { echo "hyprland exited"; exit 0; }

echo "step 3: uwsm"
if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then
    uwsm stop
    sleep 3
    alive || exit 0
fi

echo "step 4: terminate-session"
[ -n "$XDG_SESSION_ID" ] && loginctl terminate-session "$XDG_SESSION_ID"
sleep 3
alive || exit 0

echo "step 5: pkill"
pkill -x Hyprland
sleep 2
pkill -9 -x Hyprland
