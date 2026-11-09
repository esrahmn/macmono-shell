#!/usr/bin/env python3
"""Pastikan `def` di core/settings/SettingsSchema.qml sama dengan nilai bawaan di core/settings/Settings.qml.

Jalankan dari akar proyek: python3 scripts/development/check-settings-defaults.py
Keluar dengan kode 1 kalau ada yang beda atau ada kunci yang tidak ada di Settings.qml.
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
        print(f"  {key}: tidak ada di Settings.qml")
        problems += 1
        continue
    if json.loads(raw) != defaults[key]:
        print(f"  {key}: schema={raw} Settings.qml={defaults[key]}")
        problems += 1

# Opsi yang sengaja tidak ada di UI (timing/guard/debounce) tetap dipakai kode dan bisa diubah lewat
# ~/.config/macmono/settings.json. Cukup hitung, jangan dicetak satu-satu.
hidden = set(defaults) - set(re.findall(r'key: "(\w+)"', schema))
if hidden:
    print(f"  ({len(hidden)} opsi sengaja tidak ada di UI; tetap bisa diubah lewat settings.json)")

print("OK" if problems == 0 else f"{problems} masalah")
sys.exit(1 if problems else 0)
