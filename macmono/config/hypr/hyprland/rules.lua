-- ######## Window rules ########


-- Floating
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, float = true })
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, center = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } })

-- Move
-- stupid dolphin copy
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })

-- Tiling
-- Ignore app maximize requests so restored window states do not override tiling.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Picture-in-Picture
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = { "(monitor_w*0.73)", "(monitor_h*0.72)" } })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = { "(monitor_w*0.25)", "(monitor_h*0.25)" } })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true })

-- Screen sharing
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, float = true })
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, pin = true })
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" } })

-- No shadow for tiled windows
hl.window_rule({ match = { float = false }, no_shadow = true })

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
-- Tool bantu di luar macmono: tanpa animasi.
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })   -- slurp
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

-- ######## macmono (default shell) ########
-- Preferensi blur/opacity + layer rule namespace macmono:*.
-- (Pengaturan blur global ada di general.lua.)

-- Semua window: blur + sedikit transparan
hl.window_rule({
    match = { class = ".*" },
    no_blur = false,
    opacity = "0.80 0.80",
})

-- Exception: browser & game tetap solid
hl.window_rule({
    match = { class = "^(org.vinegarhq.Sober)$" },
               no_blur = true,
               opaque = true,
               opacity = "1.0 1.0",
})
hl.window_rule({
    match = { class = "^(google-chrome)$" },
    no_blur = true,
    opaque = true,
    opacity = "1.0 1.0",
})
hl.window_rule({
    match = { class = "^(steam)$" },
    no_blur = true,
    opaque = true,
    opacity = "1.0 1.0",
})
hl.window_rule({
    match = { class = "^(steam_app_.*)$" },
    no_blur = true,
    opaque = true,
    opacity = "1.0 1.0",
})
hl.window_rule({
    match = { class = "^(gamescope)$" },
    no_blur = true,
    opaque = true,
    opacity = "1.0 1.0",
})

-- Layer shell macmono (namespace bukan quickshell:*)
local mmAll   = "^macmono:.*$"
local mmBlur  = "^macmono:(menubar|cc|notif|calendar|media|launcher|clipboard|power|traymenu|cheatsheet|settings)$"
local mmPanel = "^macmono:(menubar|cc|notif|calendar|media|cheatsheet|settings)$"
local mmModal = "^macmono:(launcher|clipboard|power|traymenu)$"

-- Animasi panel diurus QML; matikan animasi layer Hyprland biar blur tidak "nyangkut"
hl.layer_rule({ match = { namespace = mmAll }, no_anim = true })
-- xray bikin blur cuma nampilin wallpaper; pastikan mati untuk panel macmono
hl.layer_rule({ match = { namespace = mmAll }, xray = false })

hl.layer_rule({ match = { namespace = mmBlur }, blur = true })
hl.layer_rule({ match = { namespace = "^macmono:menubar$" }, blur_popups = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = mmPanel }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = mmModal }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "^macmono:power$" }, ignore_alpha = 0.0 })
-- selector / wallpaper picker: full-screen preview, tanpa blur

-- Floating window rata-rata di tengah (kecuali PiP)
hl.window_rule({ match = { float = true }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, center = false })

-- Overview: window di workspace lain tetap render (video/game tidak "pause" saat peek)
hl.window_rule({ match = { class = ".*" }, render_unfocused = true })
