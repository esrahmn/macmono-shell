//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import "core"
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
// wallpaper + menubar + launcher/overview + clipboard + control center + notifikasi + screenshot
ShellRoot {
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
