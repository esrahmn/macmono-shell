import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int panelCloseDelayMs: 380

    property string runtimeDir: ""

    signal startRequested()

    function scheduleStart() {
        if (capturing || capturePending) return;
        delay.restart();
    }

    property bool capturing: false
    property bool capturePending: false
    property string captureScreen: ""
    property string captureMode: "copy"
    property string captureFile: ""
    property var captureTargets: ({})

    function startCapture(screenName) {
        if (capturing || capturePending) return;
        const screen = screenName;
        if (!screen) {
            Quickshell.execDetached(["notify-send", "-a", "Screenshot", "-u", "critical",
                "Screenshot failed", "No focused screen"]);
            return;
        }
        captureScreen = screen;
        captureFile = runtimeDir + "/shot-" + captureScreen + ".png";
        capturePending = true;
        targetsGet.running = true;
        grimProc.exec(["sh", "-c",
            "umask 077; mkdir -p \"$1\" && exec grim -o \"$2\" \"$3\"",
            "sh", runtimeDir, captureScreen, captureFile]);
    }
    function cancelCapture() {
        capturing = false;
        Quickshell.execDetached(["rm", "-f", captureFile]);
    }
    function finishCapture(x, y, w, h) {
        capturing = false;
        if (w < 2 || h < 2) { cancelCapture(); return; }
        const geo = Math.round(w) + "x" + Math.round(h) + "+" + Math.round(x) + "+" + Math.round(y);
        const script = captureMode === "ocr"
            ? "set -o pipefail; input=$1; geometry=$2; trap 'rm -f \"$input\"' EXIT; " +
              "M=$(command -v magick || command -v convert) || { notify-send -a Screenshot -u critical 'OCR failed' 'ImageMagick is not installed'; exit 1; }; " +
              "command -v tesseract >/dev/null && command -v wl-copy >/dev/null || { notify-send -a Screenshot -u critical 'OCR failed' 'Tesseract or wl-copy is not installed'; exit 1; }; " +
              "langs=$(tesseract --list-langs 2>/dev/null | awk 'NR > 1 { print $1 }' | paste -sd+ -); " +
              "[ -n \"$langs\" ] || { notify-send -a Screenshot -u critical 'OCR failed' 'No OCR language data installed'; exit 1; }; " +
              "if \"$M\" \"$input\" -crop \"$geometry\" +repage png:- | tesseract stdin stdout -l \"$langs\" | wl-copy; then " +
              "notify-send -a Screenshot 'Text copied' 'OCR result is on the clipboard'; " +
              "else notify-send -a Screenshot -u critical 'OCR failed' 'The image could not be processed or the text could not be copied'; exit 1; fi"
            : "set -o pipefail; input=$1; geometry=$2; trap 'rm -f \"$input\"' EXIT; " +
              "M=$(command -v magick || command -v convert) || { notify-send -a Screenshot -u critical 'Screenshot failed' 'ImageMagick is not installed'; exit 1; }; " +
              "pictures=$(xdg-user-dir PICTURES 2>/dev/null); [ -n \"$pictures\" ] || pictures=\"$HOME/Pictures\"; " +
              "d=\"$pictures/Screenshots\"; mkdir -p \"$d\" || { notify-send -a Screenshot -u critical 'Screenshot failed' 'Could not create the Screenshots folder'; exit 1; }; " +
              "out=\"$d/Screenshot_$(date +%Y-%m-%d_%H.%M.%S).png\"; " +
              "\"$M\" \"$input\" -crop \"$geometry\" +repage \"$out\" || { notify-send -a Screenshot -u critical 'Screenshot failed' 'Could not crop the image'; exit 1; }; " +
              "if wl-copy < \"$out\"; then notify-send -a Screenshot -i \"$out\" 'Screenshot copied' \"$out\"; " +
              "else notify-send -a Screenshot -u critical 'Screenshot saved' \"Could not copy to clipboard: $out\"; fi"
        Quickshell.execDetached(["bash", "-c", script, "bash", captureFile, geo]);
    }
    Timer { id: delay; interval: root.panelCloseDelayMs; onTriggered: root.startRequested() }
    Process {
        id: grimProc
        onExited: (code) => {
            root.capturePending = false;
            if (code === 0) root.capturing = true;
            else Quickshell.execDetached(["notify-send", "-a", "Screenshot", "Screenshot failed", "grim could not capture the screen"]);
        }
    }
    Process {
        id: targetsGet
        command: ["bash", "-c", "printf '{\"clients\":%s,\"monitors\":%s,\"layers\":%s}' \"$(hyprctl -j clients)\" \"$(hyprctl -j monitors)\" \"$(hyprctl -j layers)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.captureTargets = JSON.parse(text); }
                catch (e) { root.captureTargets = ({}); }
            }
        }
    }

}
