#!/usr/bin/env bash
# macmono design consistency check (DESIGN.md section 9 + phase P6).
# Run from anywhere:  scripts/development/check-design.sh [--legacy]
#   --legacy  list files still using the old pattern (P6 ratchet)
# Exit 0 = clean, 1 = violations. WARN does not fail the run.

set -u
cd "$(dirname "$0")/../.." || exit 2

fail=0
red()   { printf '\033[31m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
amber() { printf '\033[33m%s\033[0m' "$1"; }

# rule <title> <result>  — empty result = pass
rule() {
    if [ -z "$2" ]; then
        printf '%s  %s\n' "$(green ok)  " "$1"
    else
        printf '%s  %s\n' "$(red FAIL)" "$1"
        printf '%s\n' "$2" | sed 's/^/        /'
        fail=1
    fi
}
warn() {
    if [ -z "$2" ]; then
        printf '%s  %s\n' "$(green ok)  " "$1"
    else
        printf '%s  %s\n' "$(amber WARN)" "$1"
        printf '%s\n' "$2" | sed 's/^/        /'
    fi
}

echo "== DESIGN.md section 9"
rule "raw numbers (pixelSize/radius/duration)" \
    "$(grep -rnE 'pixelSize: *[0-9]|[^a-zA-Z]radius: *[2-9]|duration: *[0-9]' features shared)"
rule "raw SpringAnimation and font weights" \
    "$(grep -rnE 'SpringAnimation|Font\.(DemiBold|Medium|Normal|Bold)' features shared)"
rule "raw ColorAnimation (use TweenColor)" \
    "$(grep -rn 'ColorAnimation' features shared | grep -v TweenColor)"
# Two recorded exceptions in DESIGN.md (Audit P5): SettingsNightPreview, SettingsAbout.
rule "colors outside Theme" \
    "$(grep -rnE 'Qt\.rgba\(|"#[0-9a-fA-F]{3,8}"' features shared | grep -v 'readonly property' \
        | grep -v -e 'SettingsNightPreview.qml:[0-9]*: *return Qt.rgba(c(r)' -e 'SettingsAbout.qml:[0-9]*:.*: Qt.rgba(1, 1, 1, 0)$')"

echo "== Token"
defined=$({ grep -oE 'readonly property [a-zA-Z]+ [A-Za-z0-9_]+' core/theme/Theme.qml | awk '{print $4}'
    grep -oE '^ *function [A-Za-z0-9_]+' core/theme/Theme.qml | awk '{print $2}'; } | sort -u)
used=$(grep -rhoE --include='*.qml' 'Theme\.[A-Za-z0-9_]+' features shared core | sed 's/^Theme\.//' | sort -u)
rule "Theme.* used but not defined" "$(comm -13 <(printf '%s\n' "$defined") <(printf '%s\n' "$used"))"
rule "unused Theme tokens" "$(for t in $defined; do
        grep -rqE "Theme\.$t\b" features shared core --include='*.qml' || \
        grep -qE "\b$t\b" <(grep -vE 'readonly property' core/theme/Theme.qml) || echo "$t"
    done)"

echo "== Hygiene"
rule "leftover .bak files" "$(find . -name '*.bak*' -o -name '*.orig' | sed 's|^\./||')"
warn "properties starting with on+Uppercase (may be parsed as signal handlers)" \
    "$(grep -rnE 'property +[A-Za-z.]+ +on[A-Z]' features shared core)"

echo "== P6: shared components (ratchet: the legacy list may only shrink)"
# Remove a name from this list whenever a file finishes migrating.
LEGACY_PANEL="
features/overview/Overview.qml
features/lock/LockMedia.qml
features/clipboard/Clipboard.qml
features/media/MediaPopup.qml
features/cheatsheet/Cheatsheet.qml
features/launcher/LauncherMenu.qml
features/notifications/Notifs.qml
features/settings/components/SettingsPanel.qml
features/emojiPicker/EmojiPicker.qml
features/controlCenter/ControlCenter.qml
features/wallpaper/Wallpaper.qml
"
LEGACY_KEYCAP="
features/settings/components/SettingsKeys.qml
"

panel_files=$(grep -rl 'radius: Theme.radiusPanel' features shared | xargs grep -l 'color: Theme.panel' \
    | grep -v '^shared/components/Panel.qml$' | sort)
rule "hand-written panel frame (use Panel)" \
    "$(comm -23 <(printf '%s\n' "$panel_files") <(printf '%s\n' "$LEGACY_PANEL" | sed '/^$/d' | sort))"
keycap_files=$(grep -rl 'Theme.cheatsheetKeycap' features shared | grep -v '^shared/components/UiKeycap.qml$' | sort)
rule "hand-written keycap (use UiKeycap)" \
    "$(comm -23 <(printf '%s\n' "$keycap_files") <(printf '%s\n' "$LEGACY_KEYCAP" | sed '/^$/d' | sort))"
# Already-clean files still listed as legacy: remind to tidy the list.
warn "stale Panel legacy list (already migrated, remove from list)" \
    "$(comm -13 <(printf '%s\n' "$panel_files") <(printf '%s\n' "$LEGACY_PANEL" | sed '/^$/d' | sort))"

if [ "${1:-}" = "--legacy" ]; then
    echo; echo "Not yet migrated to Panel ($(printf '%s\n' "$LEGACY_PANEL" | sed '/^$/d' | wc -l)):"
    printf '%s\n' "$LEGACY_PANEL" | sed '/^$/d;s/^/  /'
    echo "Not yet migrated to UiKeycap:"
    printf '%s\n' "$LEGACY_KEYCAP" | sed '/^$/d;s/^/  /'
fi

echo
if [ "$fail" -eq 0 ]; then echo "$(green PASS)"; else echo "$(red FAIL)"; fi
exit "$fail"
