-- >>> macmono >>>
hl.on("hyprland.start", function()
    -- Di end4, polkit agent disediakan quickshell ii. macmono nggak punya, jadi
    -- jalankan agent biasa HANYA kalau shell-nya macmono (biar nggak dobel sama ii).
    hl.exec_cmd("[ \"$qsConfig\" = macmono ] && ~/.config/hypr/hyprland/scripts/launch_first_available.sh " ..
        "'/usr/lib/polkit-kde-authentication-agent-1' " ..
        "'/usr/lib/hyprpolkitagent/hyprpolkitagent' " ..
        "'/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1'")
end)
-- <<< macmono <<<
