# MacMono

Modular desktop shell built with Quickshell / Qt 6.12.

## Structure

- `shell.qml` — shell entry point and top-level surface composition.
- `core/` — settings, system facade, theme, and shortcuts. `core/qmldir` exposes stable singleton names.
- `features/` — feature-owned QML surfaces and their private components, scripts, config, and data.
- `shared/` — reusable components, system services, and shared assets.
- `scripts/` — session, capture, and development utilities.
- `docs/` — migration audits and historical changelogs.

## Settings System

The Settings System remains in `core/settings/`: `Settings.qml`, `SettingsStore.qml`, and `SettingsSchema.qml`. The root `core/qmldir` keeps the existing singleton names available to feature QML through `import "../../core"` (adjust relative path from each feature).

## Run

Run Quickshell using the same launch command and environment used by your existing setup. This refactor changes file organization and resource paths; it does not intentionally change feature behavior.

## Validation

Run `python3 scripts/development/check-settings-defaults.py` from this directory to compare Settings defaults with the Settings UI schema.
