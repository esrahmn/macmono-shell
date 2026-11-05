import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Privacy indicators (mic / camera / screen recording / screencast).
// Sebelumnya polling agresif lewat fuser + pidof di Sys.qml.
// Sekarang:
//  - mic & screencast = pure reactive dari Pipewire (no Process)
//  - camera & external recorder = Process hanya saat dibutuhkan + debounce
Scope {
    id: root

    // ---- mic (reactive, no Process) ----
    readonly property bool micInUse: Pipewire.nodes.values.some(n => {
        if (!n.isStream || n.isSink || !n.audio) return false;
        const app = String(n.properties?.["application.name"] ?? n.properties?.["node.name"] ?? n.name ?? "").toLowerCase();
        return !/easyeffects|pavucontrol|cava|quickshell|pipewire|wireplumber/.test(app);
    })

    // ---- screencast via xdg-desktop-portal (reactive) ----
    readonly property bool screencast: Pipewire.nodes.values.some(n => {
        const p = n.properties ?? {};
        const mc = String(p["media.class"] ?? "");
        const who = (String(n.name ?? "") + " " + String(p["application.name"] ?? "") + " " + String(p["node.name"] ?? "")).toLowerCase();
        return mc === "Video/Source" && /xdp|portal|screencast/.test(who);
    })

    // ---- camera & external recorders (polled, tapi lebih hemat) ----
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

    // Poll lebih jarang (3.5s) dan hanya kalau shell masih hidup.
    // Sebelumnya interval jauh lebih pendek + banyak generation tracking yang rumit.
    Timer {
        interval: 3500
        running: true
        repeat: true
        onTriggered: if (!checkProc.running) checkProc.running = true
    }

    // Paksa cek sekali saat startup
    Component.onCompleted: checkProc.running = true
}
