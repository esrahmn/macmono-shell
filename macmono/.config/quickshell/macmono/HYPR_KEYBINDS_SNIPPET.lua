-- macmono Quickshell keybinds (Hyprland Lua config)
-- Tempel ke ~/.config/hypr/custom/keybinds.lua atau gabungkan ke keybinds utama.
-- Butuh: qs (quickshell) di PATH, config name = macmono

local qs = "qs -c macmono ipc call"

-- Launcher / overview
hl.bind("SUPER", hl.dsp.exec_cmd(qs .. " shell toggleLauncher"), { description = "macmono: Launcher" })
hl.bind("SUPER + Tab", hl.dsp.exec_cmd(qs .. " shell toggleLauncher"), { description = "macmono: Overview/Launcher" })

-- Panels
hl.bind("SUPER + A", hl.dsp.exec_cmd(qs .. " shell toggleCC"), { description = "macmono: Control Center" })
hl.bind("SUPER + V", hl.dsp.exec_cmd(qs .. " shell toggleClipboard"), { description = "macmono: Clipboard" })
hl.bind("SUPER + M", hl.dsp.exec_cmd(qs .. " shell toggleMedia"), { description = "macmono: Media" })
hl.bind("SUPER + Slash", hl.dsp.exec_cmd(qs .. " shell toggleCheat"), { description = "macmono: Cheatsheet" })
hl.bind("SUPER + N", hl.dsp.exec_cmd(qs .. " shell toggleCalendar"), { description = "macmono: Calendar" })

-- Session
hl.bind("SUPER + L", hl.dsp.exec_cmd(qs .. " shell lock"), { description = "macmono: Lock" })

-- Capture / record (sesuaikan kalau function capture beda namanya)
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(qs .. " capture region"), { description = "macmono: Region screenshot" })

-- Catatan:
-- GlobalShortcut di Shortcuts.qml (searchToggleRelease, dll) TETAP jalan
-- kalau keybind Hyprland masih pakai: bind = ..., global, quickshell:searchToggleRelease
-- Keduanya bisa dipakai berdampingan; IPC di atas lebih eksplisit & mudah di-debug.
