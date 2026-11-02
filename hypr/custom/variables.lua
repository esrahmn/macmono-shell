-- >>> macmono >>>
-- Shell yang dijalankan saat login (folder di ~/.config/quickshell). Ganti ke "ii" buat balik ke end4.
hl.env("qsConfig", "macmono")

-- macmono nggak punya settings.qml, jadi Super+I langsung ke app pengaturan biasa
settingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'systemsettings' 'gnome-control-center' 'better-control'"
-- <<< macmono <<<
