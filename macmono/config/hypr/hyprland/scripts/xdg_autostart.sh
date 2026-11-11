#!/usr/bin/env bash
exec python3 - "$@" <<'PY'
import os, subprocess, configparser, glob
desk = os.environ.get("XDG_CURRENT_DESKTOP", "Hyprland").split(":")[0] or "Hyprland"
home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
sysd = (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":")
dirs = [os.path.join(d, "autostart") for d in [home] + sysd]
seen, run = set(), []
for d in dirs:
    for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
        name = os.path.basename(f)
        if name in seen: continue
        seen.add(name)
        c = configparser.RawConfigParser(strict=False, interpolation=None)
        try: c.read(f, encoding="utf-8")
        except Exception: continue
        if not c.has_section("Desktop Entry"): continue
        g = lambda k: c.get("Desktop Entry", k, fallback="").strip()
        if g("Hidden").lower() == "true": continue
        if g("X-GNOME-Autostart-enabled").lower() == "false": continue
        if g("Type") not in ("", "Application"): continue
        only = [x for x in g("OnlyShowIn").split(";") if x]
        no = [x for x in g("NotShowIn").split(";") if x]
        if only and desk not in only: continue
        if desk in no: continue
        if not g("Exec"): continue
        run.append(f)
for f in run:
    if os.environ.get("DRY"): print(f)
    else: subprocess.Popen(["dex", f], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
