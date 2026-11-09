#!/bin/sh
# macmono: logout bertahap, dengan log di ~/.local/state/macmono/session.log
# 1) tutup semua window pelan-pelan  2) Hyprland exit
# 3) loginctl terminate-session (BUKAN terminate-user)  4) pkill
log="$HOME/.local/state/macmono/session.log"
mkdir -p "$(dirname "$log")"
exec >>"$log" 2>&1
echo "=== logout $(date) ==="
echo "XDG_SESSION_ID=$XDG_SESSION_ID HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"

alive() { pgrep -x Hyprland >/dev/null 2>&1; }

# Cara yang disarankan wiki Hyprland: hyprshutdown minta aplikasi keluar dengan rapi, baru keluar dari Hyprland.
# Kalau nggak terpasang atau macet lebih dari 20 detik, lanjut ke langkah bertahap di bawah.
if command -v hyprshutdown >/dev/null 2>&1; then
    echo "step 0: hyprshutdown"
    hyprshutdown >/dev/null 2>&1
    for _ in $(seq 1 100); do
        alive || { echo "hyprland exited via hyprshutdown"; exit 0; }
        sleep 0.2
    done
    echo "hyprshutdown timeout, lanjut fallback"
fi

echo "step 1: close windows"
hyprctl clients -j 2>&1 | jq -r '.[].address' 2>&1 | while read -r a; do
    [ -n "$a" ] && hyprctl dispatch "hl.dsp.window.close({ window = \"address:$a\" })"
done
sleep 0.7

echo "step 2: hyprland exit"
hyprctl dispatch 'hl.dsp.exit()'
sleep 2
alive || { echo "hyprland exited"; exit 0; }

echo "step 3: terminate-session"
[ -n "$XDG_SESSION_ID" ] && loginctl terminate-session "$XDG_SESSION_ID"
sleep 3
alive || exit 0

echo "step 4: pkill"
pkill -x Hyprland
sleep 2
pkill -9 -x Hyprland
