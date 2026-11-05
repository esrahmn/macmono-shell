import Quickshell
import Quickshell.Io
import "../core"

// IPC fasad macmono — selaras dengan Shortcuts.qml + record.sh
//
// qs -c macmono ipc call shell toggleLauncher
// qs -c macmono ipc call capture region
// qs -c macmono ipc call record start area none
// qs -c macmono ipc call control recordingStarted   (dipakai record.sh)
Scope {
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void { Sys.toggleLauncher(); }
        function toggleCC(): void { Sys.toggleCC(); }
        function toggleClipboard(): void { Sys.toggleClipboard(); }
        function toggleWallpaper(): void { Sys.toggleWallpaper(); }
        function togglePower(): void { Sys.togglePower(); }
        function toggleCalendar(): void { Sys.toggleCalendar(); }
        function toggleMedia(): void { Sys.toggleMedia(); }
        function toggleCheat(): void { Sys.toggleCheat(); }
        function lock(): void { Sys.lock(); }
        function refresh(): void { Sys.refresh(); }
        function power(act: string): void { Sys.power(act); }

        function setBrightness(v: real): void { Sys.setBrightness(v); }
        function setVolume(v: real): void { Sys.setVolume(v); }
        function toggleMic(): void { Sys.toggleMic(); }
        function toggleNightLight(): void { Sys.toggleNightLight(); }

        function isLauncherOpen(): bool { return Sys.launcherOpen; }
        function isCCOpen(): bool { return Sys.ccOpen; }
        function focusedScreen(): string { return Sys.focusedScreenName(); }
    }

    // record.sh memanggil: qs -c macmono ipc call control recordingStarted
    IpcHandler {
        target: "control"
        function toggle(): void { Sys.toggleCC(Sys.focusedScreenName()); }
        function recordingStarted(): void { Sys.recordingStarted(); }
        function recordingCancelled(): void { Sys.recordingCancelled(); }
    }

    IpcHandler {
        target: "capture"
        // Region selector (layar dibekukan dulu)
        function region(): void { Sys.screenshot("copy", false); }
        function ocr(): void { Sys.screenshot("ocr", false); }
        // Dari panel (tutup panel dulu biar tidak ikut ter-capture)
        function regionFromPanel(): void { Sys.screenshot("copy", true); }
        function ocrFromPanel(): void { Sys.screenshot("ocr", true); }
    }

    IpcHandler {
        target: "record"
        // mode: full | area ; audio: none | system | mic
        function start(mode: string, audio: string): void {
            const m = (mode === "area" || mode === "full") ? mode : "full";
            const a = (audio === "system" || audio === "mic") ? audio : "none";
            Sys.recordStart(m, a);
        }
        function stop(): void { Sys.recordStop(); }
        function isActive(): bool { return Sys.recActive; }
        function isPending(): bool { return Sys.recStartPending; }
    }

    IpcHandler {
        target: "wifi"
        function toggle(): void { Sys.toggleWifi(); }
        function scan(): void { Sys.scanWifi(); }
        function disconnect(): void { Sys.disconnectWifi(); }
        function name(): string { return Sys.wifiName; }
        function isOn(): bool { return Sys.wifiOn; }
    }

    IpcHandler {
        target: "brightness"
        function increment(): void { Sys.setBrightness(Sys.brightness + 0.05); }
        function decrement(): void { Sys.setBrightness(Sys.brightness - 0.05); }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Sys.toggleWallpaper(); }
        function random(): void { Sys.randomWallpaper(); }
    }

    IpcHandler {
        target: "lock"
        function activate(): void { Sys.lock(); }
        function focus(): void {
            if (typeof Sys.lockRefocus === "function")
                Sys.lockRefocus();
            else
                Sys.lock();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Sys.toggleLauncher(); }
    }

    IpcHandler {
        target: "cliphistService"
        function update(): void {
            if (typeof Sys.clipboardUpdated === "function")
                Sys.clipboardUpdated();
        }
    }
}
