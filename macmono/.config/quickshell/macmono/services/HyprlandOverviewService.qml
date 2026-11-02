import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Snapshot client + monitor Hyprland yang dipakai Launcher dan Overview.
// `active` diatur dari Sys.qml (aktif selama launcher terbuka); UI tetap memakai Sys.hyprClients / Sys.hyprMonitors.
// Pakai Scope (bukan QtObject) supaya boleh punya anak (Process, Timer, Connections).
Scope {
    id: root

    property bool active: false
    property var clients: []
    property var monitors: []
    property bool refreshAgain: false

    readonly property var events: [
        "openwindow", "closewindow", "movewindowv2", "changefloatingmode",
        "workspacev2", "fullscreen", "windowtitlev2", "focusedmonv2", "moveworkspacev2"
    ]

    function refresh() {
        if (hyprGet.running) {
            refreshAgain = true;
            return;
        }
        hyprGet.running = true;
    }

    Process {
        id: hyprGet
        command: ["bash", "-c", "printf '{\"clients\":%s,\"monitors\":%s}' \"$(hyprctl -j clients)\" \"$(hyprctl -j monitors)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.clients = data.clients || [];
                    root.monitors = data.monitors || [];
                } catch (e) {
                    // hyprctl ngasih JSON rusak: pertahankan snapshot terakhir yang valid.
                }
            }
        }
        onExited: {
            if (root.refreshAgain) {
                root.refreshAgain = false;
                hyprDebounce.restart();
            }
        }
    }

    Timer {
        id: hyprDebounce
        interval: 60
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.active && root.events.includes(event.name)) hyprDebounce.restart();
        }
    }
}
