//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import "core"
import "services"
import "wallpaper"
import "menubar"
import "cc"
import "launcher"
import "notif"
import "capture"
import "clipboard"
import "power"
import "osd"
import "calendar"
import "media"
import "cheatsheet"
import "lock"

// macmono: shell monochrome ala macOS
// Struktur diperbaiki:
//  - services/ berisi subsystem (audio, hypr overview, privacy, ipc)
//  - core/Sys.qml jadi fasad state + orchestrator, bukan tempat semua logic
//  - IPC resmi lewat qs ipc call shell <fn>
ShellRoot {
    // Services (singleton-ish, hidup sepanjang shell)
    Ipc {}

    // Surfaces
    Wallpaper {}
    MenuBar {}
    TrayMenu {}
    Launcher {}
    Clipboard {}
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
