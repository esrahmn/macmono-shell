import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../settings"
import "../system"

Scope {
    id: root

    property bool superMightTrigger: true
    property real superPressedAt: 0
    property var wsAtPress: null
    property var winAtPress: null

    function armSuper() {
        superPressedAt = Date.now();
        wsAtPress = Hyprland.focusedWorkspace?.id ?? null;
        winAtPress = ToplevelManager.activeToplevel;
    }

    function releaseSuper() {
        const pressedAt = superPressedAt;
        superPressedAt = 0;
        if (!superMightTrigger) { superMightTrigger = true; return; }
        if (Sys.overviewOpen) return;
        if (pressedAt > 0) {
            if (Date.now() - pressedAt > Settings.superTapMaxMs) return;
            if ((Hyprland.focusedWorkspace?.id ?? null) !== wsAtPress) return;
            if (ToplevelManager.activeToplevel !== winAtPress) return;
        }
        Sys.toggleLauncherMenu();
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "macmono: toggle launcher when Super is released"
        onPressed: root.armSuper()
        onReleased: root.releaseSuper()
    }
    GlobalShortcut {
        name: "workspaceNumber"
        description: "macmono: record when Super is pressed"
        onPressed: root.armSuper()
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "macmono: cancel launcher toggle (Super is part of a combo)"
        onPressed: root.superMightTrigger = false
    }
    GlobalShortcut { name: "searchToggle"; description: "macmono: toggle launcher"; onPressed: Sys.toggleLauncherMenu() }

    GlobalShortcut { name: "lock"; description: "macmono: lock screen"; onPressed: Sys.lock() }
    GlobalShortcut { name: "lockFocus"; description: "macmono: refocus lock after resume"; onPressed: Sys.lockRefocus() }

    GlobalShortcut { name: "sidebarLeftToggle";   description: "macmono: calendar & notifications"; onPressed: Sys.toggleCalendar(Sys.focusedScreenName()) }
    GlobalShortcut { name: "mediaControlsToggle"; description: "macmono: media controls";        onPressed: Sys.toggleMedia() }
    GlobalShortcut { name: "settingsToggle";      description: "macmono: system settings";    onPressed: Sys.toggleSettings() }
    GlobalShortcut { name: "cheatsheetToggle";    description: "macmono: shortcut list";      onPressed: Sys.toggleCheat() }
    GlobalShortcut { name: "sidebarRightToggle";  description: "macmono: control center";  onPressed: Sys.toggleCC(Sys.focusedScreenName()) }
    GlobalShortcut { name: "wallpaperSelectorToggle"; description: "macmono: wallpaper picker"; onPressed: Sys.toggleWallpaper() }
    GlobalShortcut { name: "wallpaperSelectorRandom"; description: "macmono: random wallpaper"; onPressed: Sys.randomWallpaper() }
    GlobalShortcut { name: "regionScreenshot";    description: "macmono: screenshot";       onPressed: Sys.screenshot("copy", false) }
    GlobalShortcut { name: "barToggle";           description: "macmono: toggle menubar";    onPressed: Sys.barVisible = !Sys.barVisible }

    function sh(cmd) {
        closeAll();
        Sys.spawn(["bash", "-c", cmd]);
    }
    function closeAll() { Sys.closeCCQuiet(); }

    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "macmono: clipboard history"
        onPressed: Sys.toggleClipboard()
    }
    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "macmono: emoji picker"
        onPressed: Sys.toggleEmoji()
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "macmono: window overview"
        onPressed: Sys.toggleOverview()
    }
    GlobalShortcut {
        name: "sessionToggle"
        description: "macmono: power menu"
        onPressed: Sys.togglePower()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "macmono: Google Lens from a screen area"
        onPressed: root.sh("pidof slurp || \"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland/scripts/snip_to_search.sh\"")
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "macmono: OCR screen area to clipboard"
        onPressed: Sys.screenshot("ocr", false)
    }

}
