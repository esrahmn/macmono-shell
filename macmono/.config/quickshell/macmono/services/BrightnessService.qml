import QtQuick
import Quickshell
import Quickshell.Io

// Brightness subsystem.
// - Laptop backlight: brightnessctl
// - External monitor: ddcutil (VCP 10)
// UI hanya baca property / panggil setBrightness(); tidak spawn Process sendiri.
Scope {
    id: root

    property real brightness: 0.5
    property bool brightnessOk: false
    property string brightnessBackend: ""   // "backlight" | "ddc"
    property int ddcMax: 100

    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v));
        if (brightnessBackend === "ddc")
            ddcSetDebounce.restart();
        else
            brightSet.exec(["brightnessctl", "--class", "backlight", "set", Math.round(brightness * 100) + "%", "-q"]);
    }

    function refresh() {
        if (!brightGet.running)
            brightGet.running = true;
    }

    Timer {
        id: ddcSetDebounce
        interval: 250
        onTriggered: {
            if (brightSet.running) { restart(); return; }
            brightSet.exec([
                "ddcutil", "--noverify", "setvcp", "10",
                String(Math.round(root.brightness * root.ddcMax))
            ]);
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

    Process { id: brightSet }

    Component.onCompleted: refresh()
}
