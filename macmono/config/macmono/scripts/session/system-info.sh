#!/usr/bin/env bash
v=/sys/class/dmi/id
p() { printf '%s\t%s\n' "$1" "$2"; }
p vendor  "$(cat $v/sys_vendor 2>/dev/null)"
p product "$(cat $v/product_name 2>/dev/null)"
p cpu     "$(sed -n 's/^model name[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo 2>/dev/null | head -n1)"
p threads "$(nproc 2>/dev/null)"
p cores   "$(lscpu -p=core,socket 2>/dev/null | grep -v '^#' | sort -u | wc -l)"
p gpu     "$(lspci 2>/dev/null | grep -iE 'vga|3d controller|display controller' | head -n1 | sed -e 's/^[^ ]* [^:]*: //' -e 's/ (rev [0-9a-f]*)//')"
p memkb   "$(sed -n 's/^MemTotal:[[:space:]]*\([0-9]*\).*/\1/p' /proc/meminfo 2>/dev/null)"
p disk    "$(df -kP / 2>/dev/null | awk 'NR==2 {print $2" "$3}')"
p hypr    "$(hyprctl version 2>/dev/null | head -n1)"
p qs      "$(qs --version 2>/dev/null | head -n1)"
vram="$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | sort -n | tail -n1)"
if [ -z "$vram" ] && command -v nvidia-smi >/dev/null 2>&1; then
    mib="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)"
    case "$mib" in ''|*[!0-9]*) ;; *) vram=$((mib * 1048576)) ;; esac
fi
p gpuvram "$vram"
