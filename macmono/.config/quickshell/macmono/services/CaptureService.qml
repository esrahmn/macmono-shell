import QtQuick
import Quickshell
import Quickshell.Io

// Screenshot pipeline (ala end4): grim membekukan layar -> pemilih area di RegionSelector
// -> crop pakai magick -> wl-copy (copy) atau tesseract (ocr).
// State, Timer, dan Process-nya tinggal di sini; UI tetap memakai fasad Sys.capturing /
// Sys.captureFile / Sys.captureTargets / Sys.captureMode / Sys.finishCapture().
Scope {
    id: root

    property string runtimeDir: ""      // diisi Sys: folder 0700 untuk file sementara

    // Minta Sys memulai capture. Dipakai untuk mode closeFirst: layar fokus di-resolve
    // pada saat itu juga, setelah panel benar-benar hilang dari layar.
    signal startRequested()

    function scheduleStart() {
        if (capturing || capturePending) return;
        delay.restart();
    }

    // =====================================================================
    //  Screenshot ala end4: layar dibekukan dulu pakai grim (panel yang lagi
    //  kebuka ikut kerekam), lalu area dipilih di RegionSelector, crop pakai magick.
    // =====================================================================
    property bool capturing: false      // RegionSelector lagi tampil
    property bool capturePending: false // grim lagi jalan
    property string captureScreen: ""
    property string captureMode: "copy" // "copy" | "ocr"
    property string captureFile: ""
    property var captureTargets: ({})   // hasil hyprctl: { clients, monitors, layers }

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
        // umask 077 -> folder 0700 dan file 0600
        grimProc.exec(["sh", "-c",
            "umask 077; mkdir -p \"$1\" && exec grim -o \"$2\" \"$3\"",
            "sh", runtimeDir, captureScreen, captureFile]);
    }
    function cancelCapture() {
        capturing = false;
        Quickshell.execDetached(["rm", "-f", captureFile]);
    }
    // x, y, w, h dalam piksel fisik (sudah dikali scale monitor)
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
    Timer { id: delay; interval: 380; onTriggered: root.startRequested() }   // tunggu panel selesai menutup (components/Reveal.qml)
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
