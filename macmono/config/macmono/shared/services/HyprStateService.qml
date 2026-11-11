import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Turns Hyprland's event socket (read through Quickshell) into small, ready-to-use state:
//   layoutCode / layoutCount  active keyboard layout, for the bar indicator
//   fullscreen                the focused workspace has a fullscreen window (pause decorative work)
//   configReloaded()          Hyprland finished reloading its config
// Events only trigger a refresh. The data itself is read with hyprctl, debounced, and
// nothing runs unless an event arrives.
Scope {
    id: root

    property string layoutCode: ""
    property int layoutCount: 1
    property bool fullscreen: false
    signal configReloaded()

    readonly property string layoutScript: Quickshell.shellDir + "/scripts/session/kb-layout.sh"
    readonly property int debounceMs: 80
    readonly property var fullscreenEvents: [
        "workspacev2", "focusedmonv2", "activewindowv2",
        "openwindow", "closewindow", "movewindowv2"
    ]

    property var codeCache: ({})
    property string pendingKey: ""
    property bool layoutPending: false
    property bool fullscreenPending: false

    Component.onCompleted: {
        refreshLayout();
        refreshFullscreen();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // The event object is reused by Quickshell: read everything inside the handler.
            const name = event.name;
            if (name === "activelayout") {
                layoutDebounce.restart();
            } else if (name === "fullscreen") {
                // 1 / 0 for the active window. The query below confirms it for the workspace.
                root.fullscreen = String(event.data).trim() === "1";
                fsDebounce.restart();
            } else if (name === "configreloaded") {
                layoutDebounce.restart();
                fsDebounce.restart();
                root.configReloaded();
            } else if (root.fullscreenEvents.indexOf(name) !== -1) {
                fsDebounce.restart();
            }
        }
    }

    Timer { id: layoutDebounce; interval: root.debounceMs; onTriggered: root.refreshLayout() }
    Timer { id: fsDebounce; interval: root.debounceMs; onTriggered: root.refreshFullscreen() }

    // ---- keyboard layout ----
    function refreshLayout() {
        if (devProc.running || codeProc.running) { layoutPending = true; return; }
        devProc.running = true;
    }
    function layoutIdle() {
        if (layoutPending && !devProc.running && !codeProc.running) {
            layoutPending = false;
            layoutDebounce.restart();
        }
    }
    function handleDevices(text) {
        let main = null;
        try {
            const kbs = JSON.parse(text).keyboards ?? [];
            main = kbs.find(k => k.main) ?? kbs[0] ?? null;
        } catch (e) { main = null; }
        if (!main) return;

        const layouts = String(main.layout ?? "");
        const variants = String(main.variant ?? "");
        const active = String(main.active_keymap ?? "");
        layoutCount = Math.max(1, layouts.split(",").filter(s => s.trim() !== "").length);

        // The long name -> short code lookup is cached: a layout switch only runs the script once.
        const key = active + "|" + layouts + "|" + variants;
        if (codeCache[key] !== undefined) { layoutCode = codeCache[key]; return; }
        pendingKey = key;
        codeProc.command = ["bash", layoutScript, active, layouts, variants];
        codeProc.running = true;
    }

    Process {
        id: devProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector { onStreamFinished: root.handleDevices(text) }
        onExited: root.layoutIdle()
    }
    Process {
        id: codeProc
        stdout: StdioCollector {
            onStreamFinished: {
                const code = text.trim();
                if (code === "") return;
                root.codeCache[root.pendingKey] = code;
                root.layoutCode = code;
            }
        }
        onExited: root.layoutIdle()
    }

    // ---- fullscreen ----
    function refreshFullscreen() {
        if (fsProc.running) { fullscreenPending = true; return; }
        fsProc.running = true;
    }
    Process {
        id: fsProc
        command: ["hyprctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const w = JSON.parse(text);
                    // If the field is ever missing, keep the value the event gave.
                    if (typeof w.hasfullscreen === "boolean") root.fullscreen = w.hasfullscreen;
                } catch (e) {}
            }
        }
        onExited: if (root.fullscreenPending) { root.fullscreenPending = false; fsDebounce.restart(); }
    }
}
