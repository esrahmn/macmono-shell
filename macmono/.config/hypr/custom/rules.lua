-- 1. Pengaturan efek blur global
-- (harus lewat hl.config; "hl.decoration = {...}" hanya mengisi variabel Lua dan tidak mengatur Hyprland)
hl.config({
    decoration = {
        blur = {
            enabled = true,
            size = 4,
            passes = 3,
            new_optimizations = true,
            xray = true,
        },
    },
})

-- 2. Semua window: nyalakan blur dan buat agak transparan
-- Blur hanya terlihat kalau window tembus pandang, dan rule ini juga menimpa
-- rule bawaan dotfiles yang mungkin mematikan blur untuk semua class.
-- Harus ditaruh SEBELUM pengecualian di bawah.
hl.window_rule({
    match = { class = ".*" },
    no_blur = false,
    opacity = "0.85 0.85",
})

-- 3. Pengecualian untuk Google Chrome
hl.window_rule({
    match = { class = "^(google-chrome)$" },
               no_blur = true,
               opaque = true,
               opacity = "1.0 1.0",
})

-- 4. Pengecualian untuk Steam client
hl.window_rule({
    match = { class = "^(steam)$" },
               no_blur = true,
               opaque = true,
               opacity = "1.0 1.0",
})

-- 5. Pengecualian untuk semua game Steam (Proton/Wine/Native)
hl.window_rule({
    match = { class = "^(steam_app_.*)$" },
               no_blur = true,
               opaque = true,
               opacity = "1.0 1.0",
})

-- 6. Pengecualian untuk Gamescope
hl.window_rule({
    match = { class = "^(gamescope)$" },
               no_blur = true,
               opaque = true,
               opacity = "1.0 1.0",
})

-- >>> macmono >>>
-- Rule bawaan end4 cuma kena namespace "quickshell:*", jadi layer macmono perlu rule sendiri.
local mmAll   = "^macmono:.*$"
local mmBlur  = "^macmono:(menubar|cc|notif|calendar|media|launcher|clipboard|power|traymenu|cheatsheet)$"
local mmPanel = "^macmono:(menubar|cc|notif|calendar|media)$"
local mmModal = "^macmono:(launcher|clipboard|power|traymenu|cheatsheet)$"

-- Animasi buka/tutup dikerjain di QML. Animasi layer Hyprland (fade + popin) dimatiin,
-- karena itu yang bikin blur "ketinggalan" waktu panel ditutup.
hl.layer_rule({ match = { namespace = mmAll },   no_anim = true })
-- end4 nyalain xray untuk SEMUA layer (namespace ".*"). Dengan xray, blur cuma nampilin
-- wallpaper, bukan window di belakang panel. Dimatiin buat semua layer macmono.
hl.layer_rule({ match = { namespace = mmAll },   xray = false })

hl.layer_rule({ match = { namespace = mmBlur },  blur = true })
-- popup tray menu (anak layer menubar) ikut diblur
hl.layer_rule({ match = { namespace = "^macmono:menubar$" }, blur_popups = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = mmPanel }, ignore_alpha = 0.2 })
-- Launcher, clipboard & picker: cuma kartunya yang di-blur (alpha >= 0.56), latar redup (0.40) nggak ikut
hl.layer_rule({ match = { namespace = mmModal }, ignore_alpha = 0.5 })
-- Power menu memakai veil nyaris transparan sebagai area blur, tanpa meredupkan layar.
hl.layer_rule({ match = { namespace = "^macmono:power$" }, ignore_alpha = 0.0 })
-- Cheatsheet memakai veil transparan untuk blur dan kartu Theme.panel sebagai permukaan.
hl.layer_rule({ match = { namespace = "^macmono:cheatsheet$" }, ignore_alpha = 0.0 })
-- macmono:selector (pemilih area screenshot), macmono:wallpaper & macmono:wallpaper-picker: tanpa blur
-- (picker nutup layar penuh pakai preview wallpaper, jadi blur di belakangnya cuma buang GPU)

-- Semua window floating (Dolphin, pavucontrol, dialog, dll.) muncul di tengah layar, bukan cuma kitty.
hl.window_rule({ match = { float = true }, center = true })
-- Pengecualian: Picture-in-Picture dibiarkan di posisinya sendiri
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, center = false })

-- Overview: window di workspace lain tetap dapat frame (video/game nggak "pause" waktu di-peek).
-- App yang lagi diam nggak ikut menggambar ulang, jadi bebannya kecil. Hapus dua baris ini kalau baterai terasa lebih boros.
hl.window_rule({ match = { class = ".*" }, render_unfocused = true })
hl.config({ misc = { render_unfocused_fps = 24 } })
-- <<< macmono <<<
