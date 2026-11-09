pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "../../shared/services"
import "../settings"
import "../theme"

Singleton {
    id: root

    PrivacyService {
        id: privacy
        activePollMs: Settings.privacyPollActiveMs
        cameraPossible: root.camWindowOpen
    }
    BrightnessService { id: brightnessSvc; debounceMs: Settings.brightnessDebounceMs; ddcDebounceMs: Settings.brightnessDdcDebounceMs }
    WifiService {
        id: wifiSvc
        statusPollMs: Settings.wifiStatusPollMs
        connectTimeoutMs: Settings.wifiConnectTimeoutMs
        maxNetworks: Settings.wifiMaxNetworks
    }
    WallpaperService {
        id: wallpaperSvc
        stateStore: stateStore
        searchDirs: Settings.wallpaperDirs
        scanDepth: Settings.wallpaperScanDepth
        maxFiles: Settings.wallpaperMaxFiles
    }
    MediaVisualizerService {
        id: mediaVisualizer
        enabled: Settings.visualizerEnabled
        wanted: Settings.visualizerInBar || Settings.visualizerInPopup
        forceRun: root.visualizerPreview
        gain: Settings.visualizerGain
    }
    StateStore { id: stateStore }
    DisplayService { id: displaySvc }
    WeatherService {
        id: weatherSvc
        placeName: Settings.weatherName
        lat: Settings.weatherLat
        lon: Settings.weatherLon
        unit: Settings.weatherUnit
        cacheMin: Settings.weatherCacheMin
    }
    property alias weather: weatherSvc
    property alias display: displaySvc
    HyprSyncService {
        id: hyprSyncSvc
        inputValues: ({
            sensitivity: Settings.inputSensitivity, repeatRate: Settings.inputRepeatRate, repeatDelay: Settings.inputRepeatDelayMs,
            naturalScroll: Settings.inputNaturalScroll, tapToClick: Settings.inputTapToClick,
            disableWhileTyping: Settings.inputDisableWhileTyping, clickfinger: Settings.inputClickfinger,
            scrollFactor: Settings.inputScrollFactor,
            kbLayouts: Settings.inputKbLayouts, kbVariants: Settings.inputKbVariants, kbOptions: Settings.inputKbOptions
        })
        idleMinutes: ({ lock: Settings.idleLockMin, screenOff: Settings.idleScreenOffMin, suspend: Settings.idleSuspendMin })
    }
    property alias hyprSync: hyprSyncSvc
    EqualizerService { id: eqSvc }
    property alias eq: eqSvc
    SystemInfoService { id: systemInfoSvc }

    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("HOME") + "/.cache")) + "/macmono"

    readonly property string osName: systemInfoSvc.osName
    readonly property string kernelVersion: systemInfoSvc.kernelVersion
    readonly property string architecture: systemInfoSvc.architecture
    function uptimeSeconds() { return systemInfoSvc.uptimeSeconds(); }
    readonly property var systemDetails: systemInfoSvc.details
    function loadSystemDetails() { systemInfoSvc.loadDetails(); }

    property bool barVisible: true
    property bool ccOpen: false
    property string ccScreen: ""
    property real ccClosedAt: 0
    property bool launcherOpen: false
    property string launcherScreen: ""
    property bool commandPaletteOpen: false
    property string commandPaletteScreen: ""
    property bool wallpaperOpen: false
    property string wallpaperScreen: ""
    property bool clipboardOpen: false
    property bool emojiOpen: false
    property string emojiScreen: ""
    property bool trayMenuOpen: false
    property var trayMenuItem: null
    property string trayMenuScreen: ""
    property real trayMenuX: 0
    function openTrayMenu(item, screenName, x) {
        if (Date.now() - trayClosedAt < Settings.trayReopenGuardMs) return;
        closeCCQuiet();
        trayMenuItem = item; trayMenuScreen = screenName; trayMenuX = x; trayMenuOpen = true;
    }
    property real trayClosedAt: 0
    onTrayMenuOpenChanged: if (!trayMenuOpen) trayClosedAt = Date.now()
    property string avatar: ""
    Process {
        running: true
        command: ["bash", "-c", "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do " +
        "[ -s \"$f\" ] && [ ! -d \"$f\" ] && { echo \"$f\"; exit 0; }; " +
        "[ -d \"$f\" ] && i=$(find \"$f\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort | head -n1) && " +
        "[ -n \"$i\" ] && { echo \"$i\"; exit 0; }; done"]
        stdout: StdioCollector {
            onStreamFinished: root.avatar = this.text.trim()
        }
    }

    readonly property bool micInUse: privacy.micInUse
    readonly property bool camInUse: privacy.camInUse
    readonly property bool recordingProc: privacy.recordingProc
    readonly property bool screencast: privacy.screencast
    readonly property bool recording: (privacy.recordingProc && !recActive) || privacy.screencast

    property int recordingGeneration: 0

    property bool recActive: false
    property bool recStartPending: false
    property bool recStopping: false
    property int recStatusGeneration: 0
    property string recStartMode: "full"
    property string recStartAudio: "none"
    property real recStartedAt: 0
    property int recSeconds: 0
    readonly property string recLabel: {
        const s = recSeconds, m = Math.floor(s / 60), h = Math.floor(m / 60);
        return (h > 0 ? h + ":" + String(m % 60).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0");
    }
    Timer {
        interval: 1000; repeat: true
        running: root.recActive
        onTriggered: root.recSeconds = Math.floor((Date.now() - root.recStartedAt) / 1000)
    }
    function recordStart(mode, audio) {
        if (recActive || recStartPending) return;
        recordingGeneration++;
        recStartPending = true;
        recStartMode = mode || "full";
        recStartAudio = audio || "none";
        closeCCQuiet();
        recordStartDelay.restart();
        recStartTimeout.interval = recStartMode === "area" ? Settings.recordStartTimeoutAreaMs : Settings.recordStartTimeoutMs;
        recStartTimeout.restart();
    }
    function recordStop() {
        recordingGeneration++;
        recActive = false;
        recStopping = true;
        recStopGrace.restart();
        Quickshell.execDetached(["bash", Quickshell.shellDir + "/scripts/capture/record.sh", "stop"]);
    }
    function recordingStarted() {
        recordingGeneration++;
        recStartPending = false;
        recStartTimeout.stop();
        if (!recActive) {
            recStartedAt = Date.now();
            recSeconds = 0;
        }
        recActive = true;
    }
    function recordingCancelled() {
        recordingGeneration++;
        recStartPending = false;
        recStartTimeout.stop();
    }
    Timer {
        id: recStartTimeout
        onTriggered: {
            if (!root.recStartPending) return;
            root.recStartPending = false;
            root.recStatusGeneration = root.recordingGeneration;
            recStatus.running = true;
        }
    }
    Timer { id: recStopGrace; interval: Settings.recordStopGraceMs; onTriggered: root.recStopping = false }
    Timer {
        id: recordStartDelay
        interval: Settings.panelCloseDelayMs
        onTriggered: {
            root.spawn(["bash", Quickshell.shellDir + "/scripts/capture/record.sh", "start", root.recStartMode, root.recStartAudio]);
        }
    }
    Process {
        id: recStatus
        command: ["bash", Quickshell.shellDir + "/scripts/capture/record.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const on = text.trim().startsWith("1");
                if (root.recStatusGeneration === root.recordingGeneration) {
                    if (on && !root.recActive) { root.recStartedAt = Date.now(); root.recSeconds = 0; }
                    root.recActive = on;
                }
            }
        }
    }
    property int batWarned: 100
    function batNotify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency,
            "-h", "string:x-canonical-private-synchronous:macmono-battery", title, body]);
    }
    function checkBattery() {
        if (!batAvailable) return;
        const pct = Math.round(batPercent * 100);
        if (batCharging) { batWarned = 100; return; }
        for (const lvl of Settings.batteryWarnLevels) {
            if (pct <= lvl && batWarned > lvl) {
                batWarned = lvl;
                batNotify(lvl <= Settings.batteryCriticalLevel ? "critical" : "normal",
                          lvl <= Settings.batteryCriticalLevel ? "Battery critically low" : "Battery low",
                          pct + "% remaining. Plug in your charger.");
                return;
            }
        }
    }
    onBatPercentChanged: checkBattery()
    property bool batChargingKnown: false
    onBatChargingChanged: {
        if (!batAvailable) return;
        if (batChargingKnown) batNotify("low", batCharging ? "Charging" : "On battery", Math.round(batPercent * 100) + "%");
        batChargingKnown = true;
        checkBattery();
    }
    Timer { interval: Settings.batteryStartupDelayMs; running: true; onTriggered: { root.batChargingKnown = true; root.checkBattery(); } }

    property bool calendarOpen: false
    property string calendarScreen: ""
    property real calendarClosedAt: 0
    onCalendarOpenChanged: if (!calendarOpen) calendarClosedAt = Date.now(); else notifUnread = 0
    function toggleCalendar(screenName) {
        if (Date.now() - calendarClosedAt < Settings.panelReopenGuardMs) return;
        if (calendarOpen) { calendarOpen = false; return; }
        closeCCQuiet();
        calendarScreen = screenName || focusedScreenName();
        calendarOpen = true;
    }

    readonly property int mediaPopupWidth: Theme.mediaPopupWidth
    property bool mediaOpen: false
    property string mediaScreen: ""
    property real mediaPopupRightMargin: Theme.space16
    function toggleMedia(screenName, rightMargin) {
        if (mediaOpen) { mediaOpen = false; return; }
        closeCCQuiet();
        mediaScreen = screenName || focusedScreenName();
        mediaPopupRightMargin = rightMargin ?? Theme.space16;
        mediaOpen = true;
    }
    property bool settingsOpen: false
    property bool visualizerPreview: false
    property bool soundMeterActive: false
    property string settingsScreen: ""
    function toggleSettings() {
        if (settingsOpen) { settingsOpen = false; return; }
        closeCCQuiet();
        cheatOpen = false;
        settingsScreen = focusedScreenName();
        settingsOpen = true;
    }
    property bool cheatOpen: false
    property string cheatScreen: ""
    function toggleCheat() {
        if (cheatOpen) { cheatOpen = false; return; }
        closeCCQuiet();
        settingsOpen = false;
        cheatScreen = focusedScreenName();
        cheatOpen = true;
    }

    property var notifHistory: []
    property int notifUnread: 0
    property int notifSeq: 0
    function pushNotif(n) {
        const item = { id: ++notifSeq, app: n.appName || "", summary: n.summary || "", body: n.body || "", time: Date.now() };
        notifHistory = [item].concat(notifHistory).slice(0, Settings.notifHistoryMax);
        if (!calendarOpen) notifUnread++;
    }
    function removeNotif(id) { notifHistory = notifHistory.filter(x => x.id !== id); }
    function clearNotifs() { notifHistory = []; notifUnread = 0; }
    property bool notifLoaded: false
    onNotifHistoryChanged: if (notifLoaded) notifSave.restart()
    Timer { id: notifSave; interval: Settings.notifSaveDelayMs; onTriggered: notifFile.setText(JSON.stringify(root.notifHistory)) }
    FileView {
        id: notifFile
        path: Quickshell.env("HOME") + "/.local/state/macmono/notifications.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const list = JSON.parse(text());
                if (Array.isArray(list)) {
                    root.notifHistory = list.slice(0, Settings.notifHistoryMax);
                    root.notifSeq = list.reduce((m, x) => Math.max(m, x.id || 0), 0);
                }
            } catch (e) {}
            root.notifLoaded = true;
        }
        onLoadFailed: root.notifLoaded = true
    }

    property bool powerOpen: false
    property string powerScreen: ""
    signal clipboardUpdated()
    property string clipboardScreen: ""

    function focusedScreenName() {
        return Hyprland.focusedMonitor?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
    }

    function toggleCC(screenName) {
        if (Date.now() - ccClosedAt < Settings.panelReopenGuardMs) return;
        if (ccOpen && ccScreen === screenName) { ccOpen = false; return; }
        closeCCQuiet();
        ccScreen = screenName || focusedScreenName();
        ccOpen = true;
    }
    function closeCC() { ccOpen = false; ccClosedAt = Date.now(); }
    onCcOpenChanged: if (ccOpen) { refresh(); calendarOpen = false; mediaOpen = false; cheatOpen = false; settingsOpen = false; }

    function toggleLauncher() {
        if (launcherOpen) { launcherOpen = false; return; }
        closeCCQuiet();
        launcherScreen = focusedScreenName();
        launcherOpen = true;
    }
    function toggleCommandPalette() {
        if (commandPaletteOpen) { commandPaletteOpen = false; return; }
        closeCCQuiet();
        settingsOpen = false;
        commandPaletteScreen = focusedScreenName();
        commandPaletteOpen = true;
    }

    function toggleWallpaper() {
        if (wallpaperOpen) { wallpaperOpen = false; return; }
        closeCCQuiet();
        wallpaperScreen = focusedScreenName();
        loadWallpapers();
        wallpaperOpen = true;
    }
    function openWallpaper() {
        closeCCQuiet();
        wallpaperScreen = focusedScreenName();
        loadWallpapers();
        wallpaperOpen = true;
    }

    property string pendingDispatch: ""
    function closeAndDispatch(cmd) {
        if (!cmd) return;
        pendingDispatch = cmd;
        closeCCQuiet();
        launcherOpen = false;
        dispatchDelay.restart();
    }
    Timer {
        id: dispatchDelay
        interval: Settings.focusSettleDelayMs
        onTriggered: {
            if (root.pendingDispatch) {
                Hyprland.dispatch(root.pendingDispatch);
                root.pendingDispatch = "";
            }
        }
    }

    function toggleClipboard() {
        if (clipboardOpen) { clipboardOpen = false; return; }
        closeCCQuiet();
        clipboardScreen = focusedScreenName();
        clipboardOpen = true;
    }
    function toggleEmoji() {
        if (emojiOpen) { emojiOpen = false; return; }
        closeCCQuiet();
        emojiScreen = focusedScreenName();
        emojiOpen = true;
    }

    HyprlandOverviewService { id: hyprOverview; active: root.launcherOpen }
    readonly property var hyprClients: hyprOverview.clients

    readonly property var camApps: ["chrome", "chromium", "brave", "vivaldi", "opera", "edge", "firefox",
        "zen", "zoom", "teams", "skype", "discord", "vesktop", "webcord", "slack", "telegram", "signal",
        "obs", "obsproject", "cheese", "guvcview", "kamoso"]
    readonly property bool camWindowOpen: {
        try {
            const tl = Hyprland.toplevels;
            const list = (tl && tl.values) ? tl.values : [];
            const apps = root.camApps;
            for (let i = 0; i < list.length; i++) {
                const t = list[i];
                const ipc = (t && t.lastIpcObject) ? t.lastIpcObject : null;
                const name = String((ipc && ipc.class) || (t && t.title) || "");
                const tokens = name.toLowerCase().split(/[^a-z0-9]+/);
                for (let k = 0; k < tokens.length; k++)
                    if (apps.indexOf(tokens[k]) >= 0) return true;
            }
            return false;
        } catch (e) {
            return false;
        }
    }
    readonly property var hyprMonitors: hyprOverview.monitors
    function refreshHypr() { hyprOverview.refresh(); }
    onLauncherOpenChanged: if (launcherOpen) { refreshHypr(); calendarOpen = false; mediaOpen = false; cheatOpen = false; }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var now: clock.date

    AudioService { id: audioService; meterWanted: root.soundMeterActive }
    readonly property var sink: audioService.sink
    readonly property real volume: audioService.volume
    readonly property bool muted: audioService.muted
    readonly property bool micMuted: audioService.micMuted
    readonly property var outputDevices: audioService.outputDevices
    function setVolume(v) { audioService.setVolume(v); }
    function toggleMic() { audioService.toggleMic(); }
    readonly property var source: audioService.source
    readonly property var inputDevices: audioService.inputDevices
    readonly property var streams: audioService.streams
    readonly property real sourceVolume: audioService.sourceVolume
    function nodeLabel(n) { return audioService.nodeLabel(n); }
    function streamName(n) { return audioService.streamName(n); }
    function setOutput(node) { audioService.setOutput(node); }
    function setSource(node) { audioService.setSource(node); }
    function setMuted(m) { audioService.setMuted(m); }
    function setSourceMuted(m) { audioService.setSourceMuted(m); }
    function setSourceVolume(v) { audioService.setSourceVolume(v); }
    function setStreamVolume(n, v) { audioService.setStreamVolume(n, v); }
    function setStreamMuted(n, m) { audioService.setStreamMuted(n, m); }
    readonly property string testSoundStatus: audioService.testStatus
    readonly property bool testSoundRunning: audioService.testRunning
    function toggleTestSound() { audioService.toggleTestSound(); }
    readonly property real inputLevel: audioService.inputLevel
    readonly property bool inputMeterAvailable: audioService.meterAvailable
    readonly property var mediaVisualizerLevels: mediaVisualizer.levels

    function mediaPlayer(players, preferredIndex) {
        if (!players || players.length === 0) return null;
        if (preferredIndex >= 0 && preferredIndex < players.length) return players[preferredIndex];
        for (const player of players) if (player.isPlaying) return player;
        return players[0];
    }
    function formatMediaTime(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "0:00";
        seconds = Math.floor(seconds);
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60), s = seconds % 60;
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s).padStart(2, "0");
    }

    readonly property bool batAvailable: UPower.displayDevice.isLaptopBattery
    readonly property real batPercent: UPower.displayDevice.percentage ?? 1
    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batSeconds: batCharging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty

    function batText() {
        const pct = Math.round(batPercent * 100) + "%";
        if (batPercent >= 0.995 && !batCharging) return pct + " · Full";
        const s = batSeconds;
        if (!s || s <= 0) return pct + (batCharging ? " · Charging" : "");
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        const t = (h > 0 ? h + "h " : "") + m + "m";
        return pct + " · " + t + (batCharging ? " to full" : " left");
    }

    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property var profile: PowerProfiles.profile
    readonly property string profileLabel: profile === PowerProfile.PowerSaver ? "Saver"
        : profile === PowerProfile.Performance ? "Performance" : "Balanced"
    readonly property string profileGlyph: profile === PowerProfile.PowerSaver ? "leaf"
        : profile === PowerProfile.Performance ? "bolt" : "balance"
    function setProfile(p) { PowerProfiles.profile = p; }
    function cycleProfile() {
        const profiles = hasPerformance
            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            : [PowerProfile.PowerSaver, PowerProfile.Balanced];
        const currentIndex = profiles.indexOf(profile);
        setProfile(profiles[(currentIndex + 1) % profiles.length]);
    }

    readonly property real brightness: brightnessSvc.brightness
    readonly property bool brightnessOk: brightnessSvc.brightnessOk
    readonly property string brightnessBackend: brightnessSvc.brightnessBackend
    function setBrightness(v) { brightnessSvc.setBrightness(v); }

    property bool dnd: false
    property bool keepAwake: false
    property bool nightLight: false
    function toggleNightLight() {
        nightLight = !nightLight;
        applyNightLight();
    }
    function applyNightLight() {
        spawn(["bash", "-c",
            "pidof hyprsunset >/dev/null || (hyprsunset >/dev/null 2>&1 &) ; sleep 0.4; hyprctl hyprsunset temperature " + (nightLight ? Settings.nightLightKelvin : Settings.nightLightOffKelvin)]);
    }
    function setNightLight(on) {
        const v = !!on;
        if (nightLight === v) return;
        nightLight = v;
        applyNightLight();
    }

    NightLightSchedule {
        id: nightLightSchedule
        enabled: Settings.nightLightSchedule
        lat: Settings.weatherLat
        lon: Settings.weatherLon
        onWindowChanged: (on) => root.setNightLight(on)
    }

    readonly property int sunriseMin: nightLightSchedule.sunriseMin
    readonly property int sunsetMin: nightLightSchedule.sunsetMin
    readonly property bool sunTimesValid: nightLightSchedule.valid

    property bool togglesLoaded: false
    onDndChanged: if (togglesLoaded) saveState("dnd", dnd ? "1" : "0")

    DndSchedule {
        id: dndSchedule
        enabled: Settings.dndScheduleEnabled
        startMin: Settings.dndStartMin
        endMin: Settings.dndEndMin
        onWindowChanged: (on) => { root.dnd = on; }
    }

    function notifIsMuted(app) {
        const name = String(app ?? "").trim().toLowerCase();
        if (name === "") return false;
        const list = Settings.notifMutedApps ?? [];
        for (let i = 0; i < list.length; i++)
            if (String(list[i]).trim().toLowerCase() === name) return true;
        return false;
    }
    onKeepAwakeChanged: if (togglesLoaded) saveState("keep_awake", keepAwake ? "1" : "0")
    onNightLightChanged: if (togglesLoaded) saveState("night_light", nightLight ? "1" : "0")
    Process {
        id: togglesRead
        command: ["sh", "-c", "d=\"$HOME/.local/state/macmono\"; for f in dnd keep_awake night_light; do cat \"$d/$f\" 2>/dev/null || printf 0; echo; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.split("\n").map(l => l.trim() === "1");
                root.dnd = v[0] ?? false;
                root.keepAwake = v[1] ?? false;
                root.nightLight = v[2] ?? false;
                if (root.nightLight) root.applyNightLight();
                root.togglesLoaded = true;
            }
        }
    }

    function spawn(argv, cwd) {
        const args = Array.from(argv ?? []);
        if (args.length === 0) return;
        if (cwd) Quickshell.execDetached({ command: args, workingDirectory: cwd });
        else Quickshell.execDetached(args);
    }

    AutostartService { id: autostartService }
    readonly property var autostart: autostartService

    BackupService { id: backupService }
    readonly property var backup: backupService

    readonly property string termScript:
        "term_run() { for t in \"${TERMINAL:-}\" xdg-terminal-exec kitty foot alacritty wezterm konsole; do " +
        "[ -n \"$t\" ] && command -v \"$t\" >/dev/null 2>&1 || continue; " +
        "case \"$t\" in xdg-terminal-exec) exec \"$t\" \"$@\";; wezterm) exec wezterm start -- \"$@\";; *) exec \"$t\" -e \"$@\";; esac; done; " +
        "notify-send -a macmono -u critical 'No terminal found' 'Set $TERMINAL or install kitty, foot or alacritty'; }; "
    function runInTerminal(args, hold) {
        const cmd = hold
            ? ["bash", "-c", "\"$@\"; echo; read -r -p 'Press Enter to close…' _", "bash"].concat(args)
            : args;
        spawn(["sh", "-c", termScript + "term_run \"$@\"", "sh"].concat(cmd));
    }

    readonly property bool wifiOn: wifiSvc.wifiOn
    readonly property string wifiName: wifiSvc.wifiName
    readonly property string wifiActiveUuid: wifiSvc.wifiActiveUuid
    readonly property int wifiSignal: wifiSvc.wifiSignal
    readonly property var wifiList: wifiSvc.wifiList
    readonly property var wifiProfiles: wifiSvc.wifiProfiles
    readonly property string wifiConnecting: wifiSvc.wifiConnecting
    readonly property string wifiError: wifiSvc.wifiError
    readonly property string wifiGlyph: !wifiOn ? "wifi-off"
        : wifiName === "" ? "wifi-none"
        : wifiSignal >= 67 ? "wifi" : wifiSignal >= 34 ? "wifi-2" : "wifi-1"
    function toggleWifi() { wifiSvc.toggleWifi(); }
    function scanWifi() { wifiSvc.scanWifi(); }
    function wifiProfile(ssid) { return wifiSvc.wifiProfile(ssid); }
    function wifiKnown(ssid) { return wifiSvc.wifiKnown(ssid); }
    function connectWifi(ssid, password) { wifiSvc.connectWifi(ssid, password); }
    function disconnectWifi() { wifiSvc.disconnectWifi(); }
    function openWifiSettings() {
        closeCCQuiet();
        spawn(["sh", "-c",
            "kcmshell6 kcm_networkmanagement 2>/dev/null || nm-connection-editor 2>/dev/null || " +
            "(command -v kitty >/dev/null && kitty -e nmtui-connect) || " +
            "(command -v alacritty >/dev/null && alacritty -e nmtui-connect) || true"]);
    }

    BluetoothService { id: btSvc; pairTimeoutSec: Settings.btPairTimeoutSec }
    readonly property bool btAvailable: btSvc.btAvailable
    readonly property bool btOn: btSvc.btOn
    readonly property var btDevices: btSvc.btDevices
    readonly property var btNew: btSvc.btNew
    readonly property var btConnected: btSvc.btConnected
    readonly property bool btScanning: btSvc.btScanning
    readonly property var btPairing: btSvc.pairing
    function toggleBt() { btSvc.toggle(); }
    function setBtScan(on) { btSvc.setScan(on); }
    function pairBt(d) { btSvc.pair(d); }
    function openBtSettings() {
        closeCCQuiet();
        spawn(["sh", "-c", termScript +
            "kcmshell6 kcm_bluetooth 2>/dev/null || blueman-manager 2>/dev/null || term_run bluetoothctl"]);
    }

    property bool locked: false
    signal lockRefocus()
    function lock() {
        if (locked) return;
        closeCCQuiet();
        launcherOpen = false;
        clipboardOpen = false;
        wallpaperOpen = false;
        trayMenuOpen = false;
        refresh();
        locked = true;
    }

    CaptureService {
        id: captureSvc
        runtimeDir: root.runtimeDir
        panelCloseDelayMs: Settings.panelCloseDelayMs
    }
    property alias capturing: captureSvc.capturing
    property alias capturePending: captureSvc.capturePending
    property alias captureScreen: captureSvc.captureScreen
    property alias captureMode: captureSvc.captureMode
    property alias captureFile: captureSvc.captureFile
    property alias captureTargets: captureSvc.captureTargets

    function screenshot(mode, closeFirst) {
        if (captureSvc.capturing || captureSvc.capturePending) return;
        captureSvc.captureMode = mode || "copy";
        if (closeFirst) {
            closeCCQuiet();
            captureSvc.scheduleStart();
        } else {
            startCapture();
        }
    }
    function startCapture() { captureSvc.startCapture(focusedScreenName()); }
    function cancelCapture() { captureSvc.cancelCapture(); }
    function finishCapture(x, y, w, h) { captureSvc.finishCapture(x, y, w, h); }
    Connections {
        target: captureSvc
        function onStartRequested() { root.startCapture(); }
    }

    function closeCCQuiet() { ccOpen = false; launcherOpen = false; commandPaletteOpen = false; wallpaperOpen = false; clipboardOpen = false; emojiOpen = false; powerOpen = false; trayMenuOpen = false; calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    onClipboardOpenChanged: if (clipboardOpen) { calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    onWallpaperOpenChanged: if (wallpaperOpen) { calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    function togglePower() {
        if (powerOpen) { powerOpen = false; return; }
        closeCCQuiet();
        powerScreen = focusedScreenName();
        powerOpen = true;
    }

    function power(act) {
        closeCCQuiet();
        switch (act) {
        case "logout":   Quickshell.execDetached(["sh", Quickshell.shellDir + "/scripts/session/session.sh"]); break;
        case "sleep":    Quickshell.execDetached(["sh", "-c", "systemctl suspend"]); break;
        case "restart":  Quickshell.execDetached(["sh", "-c", "systemctl reboot"]); break;
        case "shutdown": Quickshell.execDetached(["sh", "-c", "systemctl poweroff"]); break;
        case "lock":     lock(); break;
        }
    }

    property string wallpaper: wallpaperSvc.wallpaper
    property bool wallpaperMono: wallpaperSvc.wallpaperMono
    readonly property var wallpapers: wallpaperSvc.wallpapers
    readonly property bool wallpaperReady: wallpaperSvc.wallpaperReady
    readonly property var wallpaperReadyScreens: wallpaperSvc.wallpaperReadyScreens
    readonly property string wallpaperLoadError: wallpaperSvc.wallpaperLoadError
    readonly property string thumbDir: wallpaperSvc.thumbDir
    readonly property int thumbsVersion: wallpaperSvc.thumbsVersion
    onWallpaperChanged: {
        if (wallpaper !== wallpaperSvc.wallpaper)
            wallpaperSvc.setWallpaper(wallpaper);
    }
    onWallpaperMonoChanged: {
        if (wallpaperMono !== wallpaperSvc.wallpaperMono)
            wallpaperSvc.setWallpaperMono(wallpaperMono);
    }
    Connections {
        target: wallpaperSvc
        function onWallpaperChanged() {
            if (root.wallpaper !== wallpaperSvc.wallpaper)
                root.wallpaper = wallpaperSvc.wallpaper;
        }
        function onWallpaperMonoChanged() {
            if (root.wallpaperMono !== wallpaperSvc.wallpaperMono)
                root.wallpaperMono = wallpaperSvc.wallpaperMono;
        }
    }
    function markWallpaperReady(path, screenName) { wallpaperSvc.markWallpaperReady(path, screenName); }
    function markWallpaperLoadError(path) { wallpaperSvc.markWallpaperLoadError(path); }
    function setWallpaper(path) { wallpaperSvc.setWallpaper(path); }
    function setWallpaperMono(v) { wallpaperSvc.setWallpaperMono(v); }
    function loadWallpapers() { wallpaperSvc.loadWallpapers(); }
    function randomWallpaper() { wallpaperSvc.randomWallpaper(); }
    function thumbFor(path) { return wallpaperSvc.thumbFor(path); }
    function saveState(name, value) { stateStore.save(name, value); }

    function refresh() {
        brightnessSvc.refresh();
        wifiSvc.refresh();
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/macmono"]);
        togglesRead.running = true;
        refresh();
        recStatusGeneration = recordingGeneration;
        recStatus.running = true;
    }
}
