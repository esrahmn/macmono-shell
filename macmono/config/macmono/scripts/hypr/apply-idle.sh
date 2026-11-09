#!/usr/bin/env bash
set -u
umask 077
F="$HOME/.config/hypr/hypridle.conf"
B="$F.macmono.bak"
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() { echo "usage: $0 apply <lock_minutes> <screen_off_minutes> <suspend_minutes>  (0 = off)" >&2; exit 2; }
[ "${1:-}" = apply ] || usage
valid() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -le 600 ]; }
for v in "${2:-}" "${3:-}" "${4:-}"; do valid "$v" || { echo "invalid minute value: '${v}'" >&2; exit 2; }; done
LOCK=$2; OFF=$3; SUSP=$4

gen() {
  cat <<'EOF'



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
cat "$tmp" > "$F"
rm -f "$tmp"

if ! restart_idle; then
  echo "hypridle failed to start with the new config; old config restored." >&2
  if [ -f "$B" ]; then cat "$B" > "$F"; fi
  restart_idle || true
  exit 1
fi
