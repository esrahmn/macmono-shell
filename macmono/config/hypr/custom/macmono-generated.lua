-- Dibuat oleh macmono Settings. Jangan edit manual: bakal ditimpa.
-- Satu file untuk semua setelan macmono; tiap bagian ditulis terpisah.
-- >>> macmono:monitors

hl.monitor({ output = "eDP-1", mode = "1920x1080@60.00", position = "0x0", scale = 1, transform = 0 })
-- <<< macmono:monitors
-- >>> macmono:input
hl.config({
    input = {
        sensitivity = 0.00,
        repeat_rate = 25,
        repeat_delay = 600,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = false,
            scroll_factor = 1.00,
        }
    },
})
-- <<< macmono:input
