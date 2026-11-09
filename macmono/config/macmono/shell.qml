//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import "core"
import "core/shortcuts"
import "shared/components"
import "shared/services"
import "features/battery"
import "features/calendar"
import "features/cheatsheet"
import "features/clipboard"
import "features/controlCenter"
import "features/emojiPicker"
import "features/launcher"
import "features/commandPalette"
import "features/lock"
import "features/media"
import "features/menubar"
import "features/notifications"
import "features/osd"
import "features/overview"
import "features/power"
import "features/regionSelector"
import "features/settings"
import "features/tools"
import "features/tray"
import "features/wallpaper"

// macmono: modular desktop shell.
//  - core/ owns settings, theme, system facade, and shortcuts
//  - features/ owns feature surfaces and feature-private components/resources
//  - shared/ owns reusable UI components, system services, and assets
//  - scripts/ owns session, capture, and development utilities
//  IPC remains exposed through `qs ipc call shell <fn>`.
ShellRoot {
    // Services (singleton-ish, hidup sepanjang shell)
    Ipc {}

    // Surfaces
    Wallpaper {}
    MenuBar {}
    TrayMenu {}
    Launcher {}
    CommandPalette {}
    Clipboard {}
    EmojiPicker {}
    PowerMenu {}
    Osd {}
    Calendar {}
    MediaPopup {}
    Cheatsheet {}
    SettingsApp {}
    ControlCenter {}
    Notifs {}
    RegionSelector {}
    Shortcuts {}
    LockScreen {}
}
