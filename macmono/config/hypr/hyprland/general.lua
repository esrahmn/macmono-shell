hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.2
})

hl.gesture({
    fingers = 3,
    direction = "swipe",
    action = "move"
})
hl.gesture({
    fingers = 3,
    direction = "pinch",
    action = "fullscreen"
})
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})

hl.config({
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        resize_on_border = true,

        no_focus_fallback = true,
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true
        }
    },
    decoration = {
        rounding       = 11,
        rounding_power = 2,

        active_opacity   = 1,
        inactive_opacity = 1,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled           = true,
            size              = 2,
            passes            = 1,
            vibrancy          = 0.1696,
            new_optimizations = true,
            xray              = false,
        },
    },
    animations = {
        enabled = true
    },
    dwindle = {
        preserve_split = true,
    },
})

hl.curve("wind",         { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
hl.curve("winIn",        { type = "bezier", points = { {0.1,  1.1},  {0.1,  1.1}  } })
hl.curve("winOut",       { type = "bezier", points = { {0.3,  -0.3}, {0,    1}    } })
hl.curve("liner",        { type = "bezier", points = { {1,    1},    {1,    1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5,  0.5},  {0.75, 1.0}  } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6,    bezier = "wind",        style = "slide"     })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,    bezier = "winIn",       style = "slide"     })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,    bezier = "winOut",      style = "slide"     })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,    bezier = "wind",        style = "slide"     })
hl.animation({ leaf = "border",      enabled = true, speed = 1,    bezier = "liner"                            })
hl.animation({ leaf = "layers",      enabled = true, speed = 6,    bezier = "wind",        style = "popin 90%" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 6,    bezier = "winIn",       style = "popin 90%" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5,    bezier = "winOut",      style = "popin 90%" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,    bezier = "wind"                             })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 1.73, bezier = "almostLinear"                     })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 1.46, bezier = "almostLinear"                     })
hl.animation({ leaf = "fade",        enabled = true, speed = 3.03, bezier = "almostLinear"                     })


hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = false,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        }
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 2,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = false,
        initial_workspace_tracking = false,
        focus_on_activate = true,
        render_unfocused_fps = 24
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1
    },

    xwayland = {
        force_zero_scaling = true
    }
})
