//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import "core"
import "components"
import "modules"
import "services"
import "lock"

// macmono: shell monochrome ala macOS
// Layout:
//  - modules/ contains top-level shell surfaces and feature panels
//  - components/ contains reusable visual components
//  - core/ contains shared state, settings, theme, and shortcuts
//  - services/ contains system integrations and background services
//  - scripts/, config/, and data/ keep non-QML resources separate
//  - IPC is exposed through `qs ipc call shell <fn>`
ShellRoot {
    // Services (singleton-ish, hidup sepanjang shell)
    Ipc {}

    // Surfaces
    Wallpaper {}
    MenuBar {}
    TrayMenu {}
    Launcher {}
    Clipboard {}
    EmojiPicker {}
    PowerMenu {}
    Osd {}
    Calendar {}
    MediaPopup {}
    Cheatsheet {}
    ControlCenter {}
    Notifs {}
    RegionSelector {}
    Shortcuts {}
    LockScreen {}
}
