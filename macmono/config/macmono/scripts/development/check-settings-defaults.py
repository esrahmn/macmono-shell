#!/usr/bin/env python3
"""Check that `def` values in core/settings/SettingsSchema.qml match the defaults in core/settings/Settings.qml.

Run from the project root: python3 scripts/development/check-settings-defaults.py
Exits with code 1 if anything differs or a key is missing from Settings.qml.
"""
import json
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent.parent
settings = (root / "core/settings/Settings.qml").read_text()
schema = (root / "core/settings/SettingsSchema.qml").read_text()

defaults = {}
for m in re.finditer(r'readonly property \w+ (\w+): SettingsStore\.v\("\w+", (.+)\)\s*$', settings, re.M):
    defaults[m.group(1)] = json.loads(m.group(2))

problems = 0
for m in re.finditer(r'\{ key: "(\w+)".*?def: (\[.*?\]|[^,}\s]+)', schema, re.S):
    key, raw = m.group(1), m.group(2)
    if "liveAction" in m.group(0):
        continue
    if key not in defaults:
        print(f"  {key}: missing from Settings.qml")
        problems += 1
        continue
    if json.loads(raw) != defaults[key]:
        print(f"  {key}: schema={raw} Settings.qml={defaults[key]}")
        problems += 1

hidden = set(defaults) - set(re.findall(r'key: "(\w+)"', schema))
if hidden:
    print(f"  ({len(hidden)} options are intentionally not in the UI; they can still be changed via settings.json)")

print("OK" if problems == 0 else f"{problems} problem(s)")
sys.exit(1 if problems else 0)
