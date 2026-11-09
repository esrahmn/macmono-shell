import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    property bool active: false
    property var clients: []
    property var monitors: []
    property bool pendingRefresh: false
    property bool lastOk: true
    readonly property int debounceMs: 80

    readonly property var relevantEvents: [
        "openwindow", "closewindow", "movewindowv2", "changefloatingmode",
        "workspacev2", "fullscreen", "windowtitlev2", "focusedmonv2",
        "moveworkspacev2", "createworkspacev2", "destroyworkspacev2",
        "monitoraddedv2", "monitorremovedv2"
    ]

    function refresh() {
        if (hyprGet.running) {
            pendingRefresh = true;
            return;
        }
        hyprGet.running = true;
    }

    Process {
        id: hyprGet
        command: ["bash", "-c",
            "printf '{\"clients\":%s,\"monitors\":%s}' \"$(hyprctl -j clients 2>/dev/null || echo '[]')\" \"$(hyprctl -j monitors 2>/dev/null || echo '[]')\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.clients = Array.isArray(data.clients) ? data.clients : [];
                    root.monitors = Array.isArray(data.monitors) ? data.monitors : [];
                    root.lastOk = true;
                } catch (e) {
                    root.lastOk = false;
                }
            }
        }
        onExited: {
            if (root.pendingRefresh) {
                root.pendingRefresh = false;
                debounce.restart();
            }
        }
    }

    Timer {
        id: debounce
        interval: root.debounceMs
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.active
        function onRawEvent(event) {
            if (root.relevantEvents.indexOf(event.name) !== -1)
                debounce.restart();
        }
    }

    onActiveChanged: {
        if (active) refresh();
    }
}
