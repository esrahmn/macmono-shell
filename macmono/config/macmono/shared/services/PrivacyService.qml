import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: root

    property int activePollMs: 2000
    property bool cameraPossible: false

    readonly property bool micInUse: Pipewire.nodes.values.some(n => {
        if (!n.isStream || n.isSink || !n.audio) return false;
        const app = String(n.properties?.["application.name"] ?? n.properties?.["node.name"] ?? n.name ?? "").toLowerCase();
        return !/easyeffects|pavucontrol|cava|quickshell|pipewire|wireplumber/.test(app);
    })

    readonly property bool screencast: Pipewire.nodes.values.some(n => {
        const p = n.properties ?? {};
        const mc = String(p["media.class"] ?? "");
        const who = (String(n.name ?? "") + " " + String(p["application.name"] ?? "") + " " + String(p["node.name"] ?? "")).toLowerCase();
        return mc === "Video/Source" && /xdp|portal|screencast/.test(who);
    })

    property bool camInUse: false
    property bool recordingProc: false

    Process {
        id: checkProc
        command: ["sh", "-c",
            "c=0; for d in /dev/video*; do [ -e \"$d\" ] || continue; fuser -s \"$d\" 2>/dev/null && { c=1; break; }; done; " +
            "r=0; pidof wf-recorder gpu-screen-recorder wl-screenrec >/dev/null 2>&1 && r=1; echo \"$c $r\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                if (f.length >= 2) {
                    root.camInUse = f[0] === "1";
                    root.recordingProc = f[1] === "1";
                }
            }
        }
    }

    readonly property bool shouldPoll: cameraPossible || camInUse || recordingProc
    Timer {
        interval: root.activePollMs
        running: root.shouldPoll
        repeat: true
        onTriggered: if (!checkProc.running) checkProc.running = true
    }

    Component.onCompleted: checkProc.running = true
}
