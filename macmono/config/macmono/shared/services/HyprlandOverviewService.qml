import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Snapshot client + monitor Hyprland untuk Launcher / Overview.
//  - Hanya refresh saat dibutuhkan (active) atau ada event relevan
//  - Debounce supaya event beruntun jadi satu refresh
//  - Nggak spawn Process dobel
//  - Fallback aman kalau hyprctl gagal / JSON rusak
Scope {
    id: root

    property bool active: false
    property var clients: []
    property var monitors: []
    property bool pendingRefresh: false
    property bool lastOk: true
    readonly property int debounceMs: 80   // gabung event beruntun jadi satu refresh

    // Event yang memang mengubah daftar window / workspace / monitor
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
        // Satu kali panggil, dua data. Lebih hemat daripada dua Process terpisah.
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
                    // Jangan timpa data bagus dengan yang rusak
                    root.lastOk = false;
                }
            }
        }
        onExited: {
            if (root.pendingRefresh) {
                root.pendingRefresh = false;
                // Debounce sedikit biar tidak spam saat banyak event beruntun
                debounce.restart();
            }
        }
    }

    Timer {
        id: debounce
        interval: root.debounceMs
        onTriggered: root.refresh()
    }

    // Hanya dengarkan event saat overview/launcher aktif.
    // Ini penghematan besar dibanding selalu reaktif.
    Connections {
        target: Hyprland
        enabled: root.active
        function onRawEvent(event) {
            if (root.relevantEvents.indexOf(event.name) !== -1)
                debounce.restart();
        }
    }

    // Saat baru diaktifkan, ambil snapshot segar
    onActiveChanged: {
        if (active) refresh();
    }
}
