import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int debounceMs: 80
    property int ddcDebounceMs: 250

    property real brightness: 0.5
    property bool brightnessOk: false
    property string brightnessBackend: ""
    property int ddcMax: 100
    property int brightnessRevision: 0
    property int refreshRevision: 0

    function setBrightness(v) {
        brightnessRevision++;
        brightness = Math.max(0.01, Math.min(1, v));
        brightSetDebounce.restart();
    }

    function refresh() {
        if (!brightGet.running && !brightSet.running && !brightSetDebounce.running) {
            refreshRevision = brightnessRevision;
            brightGet.running = true;
        }
    }

    Timer {
        id: brightSetDebounce
        interval: root.brightnessBackend === "ddc" ? root.ddcDebounceMs : root.debounceMs
        onTriggered: {
            if (brightSet.running) { restart(); return; }
            if (root.brightnessBackend === "ddc") {
                brightSet.exec([
                    "ddcutil", "--noverify", "setvcp", "10",
                    String(Math.round(root.brightness * root.ddcMax))
                ]);
            } else {
                brightSet.exec([
                    "brightnessctl", "--class", "backlight", "set",
                    Math.round(root.brightness * 100) + "%", "-q"
                ]);
            }
        }
    }

    Process {
        id: brightGet
        command: ["sh", "-c",
            "brightnessctl -m -c backlight 2>/dev/null | grep -q . && exec brightnessctl -m -c backlight; " +
            "command -v ddcutil >/dev/null && ddcutil getvcp 10 --brief 2>/dev/null | awk '$1 == \"VCP\" { print \"ddc,\" $4 \",\" $5 }'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.refreshRevision !== root.brightnessRevision)
                    return;
                const f = text.trim().split(",");
                if (f[0] === "ddc" && f.length >= 3) {
                    root.ddcMax = parseInt(f[2]) || 100;
                    root.brightness = (parseInt(f[1]) || 0) / root.ddcMax;
                    root.brightnessBackend = "ddc";
                    root.brightnessOk = true;
                } else if (f.length >= 4) {
                    root.brightness = parseInt(f[3]) / 100;
                    root.brightnessBackend = "backlight";
                    root.brightnessOk = true;
                }
            }
        }
    }

    Process {
        id: brightSet
        onExited: (code) => {
            if (code !== 0)
                console.error("Failed to set brightness (exit code " + code + ")");
        }
    }

    Component.onCompleted: refresh()
}
