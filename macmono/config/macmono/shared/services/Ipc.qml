import Quickshell
import Quickshell.Io
import "../../core"

Scope {
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void { Sys.toggleLauncher(); }
        function toggleCommandPalette(): void { Sys.toggleCommandPalette(); }
        function toggleCC(): void { Sys.toggleCC(); }
        function toggleClipboard(): void { Sys.toggleClipboard(); }
        function toggleWallpaper(): void { Sys.toggleWallpaper(); }
        function togglePower(): void { Sys.togglePower(); }
        function toggleCalendar(): void { Sys.toggleCalendar(); }
        function toggleMedia(): void { Sys.toggleMedia(); }
        function toggleCheat(): void { Sys.toggleCheat(); }
        function toggleSettings(): void { Sys.toggleSettings(); }
        function lock(): void { Sys.lock(); }
        function refresh(): void { Sys.refresh(); }
        function power(act: string): void { Sys.power(act); }

        function setBrightness(v: real): void { Sys.setBrightness(v); }
        function setVolume(v: real): void { Sys.setVolume(v); }
        function toggleMic(): void { Sys.toggleMic(); }
        function toggleNightLight(): void { Sys.toggleNightLight(); }

        function isLauncherOpen(): bool { return Sys.launcherOpen; }
        function isCCOpen(): bool { return Sys.ccOpen; }
        function isSettingsOpen(): bool { return Sys.settingsOpen; }
        function focusedScreen(): string { return Sys.focusedScreenName(); }
    }

    IpcHandler {
        target: "control"
        function toggle(): void { Sys.toggleCC(Sys.focusedScreenName()); }
        function recordingStarted(): void { Sys.recordingStarted(); }
        function recordingCancelled(): void { Sys.recordingCancelled(); }
    }

    IpcHandler {
        target: "capture"
        function region(): void { Sys.screenshot("copy", false); }
        function ocr(): void { Sys.screenshot("ocr", false); }
        function regionFromPanel(): void { Sys.screenshot("copy", true); }
        function ocrFromPanel(): void { Sys.screenshot("ocr", true); }
    }

    IpcHandler {
        target: "record"
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
        function increment(): void { Sys.setBrightness(Sys.brightness + Settings.brightnessStep); }
        function decrement(): void { Sys.setBrightness(Sys.brightness - Settings.brightnessStep); }
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
