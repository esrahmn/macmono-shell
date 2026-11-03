#!/usr/bin/env bash
set -euo pipefail

devices="$(hyprctl -j devices)"
if jq -e '[.keyboards[]? | select((.capsLock // .capslock // .caps_lock) == true)] | length > 0' <<<"$devices" >/dev/null; then
    printf 'Caps Lock is on'
fi
