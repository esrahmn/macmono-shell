pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "../services"

Singleton {
    id: root

    // Subsystem services (hidup di dalam Sys supaya property binding tetap sederhana)
    PrivacyService { id: privacy }
    BrightnessService { id: brightnessSvc }
    WifiService { id: wifiSvc }
    WallpaperService { id: wallpaperSvc }
    MediaVisualizerService { id: mediaVisualizer }

    // Folder pribadi (mode 0700) untuk file sementara: screenshot beku, gambar clipboard hasil decode.
    // Jangan pakai /tmp: isinya bisa password atau data sensitif, dan /tmp bisa dibaca user lain.
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("HOME") + "/.cache")) + "/macmono"

    // =====================================================================
    //  State UI (panel yang lagi kebuka)
    // =====================================================================
    property bool barVisible: true
    property bool ccOpen: false
    property string ccScreen: ""
    property real ccClosedAt: 0
    property bool launcherOpen: false
    property string launcherScreen: ""
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
        if (Date.now() - trayClosedAt < 200) return;
        closeCCQuiet();
        trayMenuItem = item; trayMenuScreen = screenName; trayMenuX = x; trayMenuOpen = true;
    }
    property real trayClosedAt: 0
    onTrayMenuOpenChanged: if (!trayMenuOpen) trayClosedAt = Date.now()
    // foto profil: ~/.face (file ATAU folder berisi gambar), ~/.face.icon, AccountsService
    property string avatar: ""
    Process {
        running: true
        command: ["sh", "-c", "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do " +
            "if [ -d \"$f\" ]; then i=$(find \"$f\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort | head -n1); " +
            "[ -n \"$i\" ] && { echo \"$i\"; exit; }; elif [ -s \"$f\" ]; then echo \"$f\"; exit; fi; done"]
        stdout: StdioCollector { onStreamFinished: root.avatar = text.trim() }
    }
    // ---------------- indikator privasi (delegasi ke PrivacyService) ----------------
    // mic & screencast = reactive Pipewire; camera/recorder = poll hemat di PrivacyService
    readonly property bool micInUse: privacy.micInUse
    readonly property bool camInUse: privacy.camInUse
    readonly property bool recordingProc: privacy.recordingProc
    readonly property bool screencast: privacy.screencast
    // recording = ada external recorder ATAU portal screencast (internal recActive di-handle terpisah)
    readonly property bool recording: (privacy.recordingProc && !recActive) || privacy.screencast

    // Generation counter untuk sinkronisasi state rekaman internal vs external process
    property int recordingGeneration: 0

    // ---------------- rekam layar (core/record.sh, wf-recorder) ----------------
    property bool recActive: false
    property bool recStartPending: false
    property bool recStopping: false         // lagi menunggu wf-recorder berhenti (jangan dikira masih rekam)
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
        // jaga-jaga record.sh gagal ngabarin lewat IPC: jangan biarkan tombol Record macet selamanya
        recStartTimeout.interval = recStartMode === "area" ? 120000 : 15000;
        recStartTimeout.restart();
    }
    function recordStop() {
        recordingGeneration++;
        recActive = false;
        recStopping = true;
        recStopGrace.restart();
        Quickshell.execDetached(["bash", Quickshell.shellDir + "/core/record.sh", "stop"]);
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
    // Timeout: IPC dari record.sh nggak datang. Cek status asli, siapa tahu perekam sebenarnya sudah jalan.
    Timer {
        id: recStartTimeout
        onTriggered: {
            if (!root.recStartPending) return;
            root.recStartPending = false;
            root.recStatusGeneration = root.recordingGeneration;
            recStatus.running = true;
        }
    }
    Timer { id: recStopGrace; interval: 8000; onTriggered: root.recStopping = false }
    Timer {
        id: recordStartDelay
        interval: 260
        onTriggered: {
            Quickshell.execDetached(["bash", Quickshell.shellDir + "/core/record.sh", "start", root.recStartMode, root.recStartAudio]);
        }
    }
    Process {
        id: recStatus
        command: ["bash", Quickshell.shellDir + "/core/record.sh", "status"]
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
    // ---------------- peringatan baterai ----------------
    property int batWarned: 100            // level terakhir yang sudah diperingatkan (reset saat dicas)
    function batNotify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency,
            "-h", "string:x-canonical-private-synchronous:macmono-battery", title, body]);
    }
    function checkBattery() {
        if (!batAvailable) return;
        const pct = Math.round(batPercent * 100);
        if (batCharging) { batWarned = 100; return; }
        for (const lvl of [5, 10, 20]) {
            if (pct <= lvl && batWarned > lvl) {
                batWarned = lvl;
                batNotify(lvl <= 10 ? "critical" : "normal",
                          lvl <= 10 ? "Battery critically low" : "Battery low",
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
    Timer { interval: 4000; running: true; onTriggered: { root.batChargingKnown = true; root.checkBattery(); } }

    // ---------------- kalender + pusat notifikasi (klik jam) ----------------
    property bool calendarOpen: false
    property string calendarScreen: ""
    property real calendarClosedAt: 0
    onCalendarOpenChanged: if (!calendarOpen) calendarClosedAt = Date.now(); else notifUnread = 0
    function toggleCalendar(screenName) {
        if (Date.now() - calendarClosedAt < 300) return;   // klik jam saat terbuka: focus grab sudah nutup duluan
        if (calendarOpen) { calendarOpen = false; return; }
        closeCCQuiet();
        calendarScreen = screenName || focusedScreenName();
        calendarOpen = true;
    }

    // ---------------- popup media (Super+M) & cheatsheet (Super+/) ----------------
    readonly property int mediaPopupWidth: 420
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
    property bool cheatOpen: false
    property string cheatScreen: ""
    function toggleCheat() {
        if (cheatOpen) { cheatOpen = false; return; }
        closeCCQuiet();
        cheatScreen = focusedScreenName();
        cheatOpen = true;
    }

    // ---------------- riwayat notifikasi ----------------
    property var notifHistory: []          // [{ id, app, summary, body, time }], terbaru di depan
    property int notifUnread: 0
    property int notifSeq: 0
    function pushNotif(n) {
        const item = { id: ++notifSeq, app: n.appName || "", summary: n.summary || "", body: n.body || "", time: Date.now() };
        notifHistory = [item].concat(notifHistory).slice(0, 50);
        if (!calendarOpen) notifUnread++;
    }
    function removeNotif(id) { notifHistory = notifHistory.filter(x => x.id !== id); }
    function clearNotifs() { notifHistory = []; notifUnread = 0; }
    // riwayat disimpan ke ~/.local/state/macmono/notifications.json (ditulis lewat FileView, bukan argv)
    property bool notifLoaded: false
    onNotifHistoryChanged: if (notifLoaded) notifSave.restart()
    Timer { id: notifSave; interval: 1000; onTriggered: notifFile.setText(JSON.stringify(root.notifHistory)) }
    FileView {
        id: notifFile
        path: Quickshell.env("HOME") + "/.local/state/macmono/notifications.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const list = JSON.parse(text());
                if (Array.isArray(list)) {
                    root.notifHistory = list.slice(0, 50);
                    root.notifSeq = list.reduce((m, x) => Math.max(m, x.id || 0), 0);
                }
            } catch (e) {}
            root.notifLoaded = true;
        }
        onLoadFailed: root.notifLoaded = true
    }

    property bool powerOpen: false
    property string powerScreen: ""
    signal clipboardUpdated()   // dipanggil watcher cliphist (execs.lua) tiap ada salinan baru
    property string clipboardScreen: ""

    function focusedScreenName() {
        return Hyprland.focusedMonitor?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
    }

    function toggleCC(screenName) {
        // Klik tombol saat panel kebuka: focus grab nutup duluan, jangan dibuka lagi
        if (Date.now() - ccClosedAt < 300) return;
        if (ccOpen && ccScreen === screenName) { ccOpen = false; return; }
        closeCCQuiet();
        ccScreen = screenName || focusedScreenName();
        ccOpen = true;
    }
    function closeCC() { ccOpen = false; ccClosedAt = Date.now(); }
    onCcOpenChanged: if (ccOpen) { refresh(); calendarOpen = false; mediaOpen = false; cheatOpen = false; }

    function toggleLauncher() {
        if (launcherOpen) { launcherOpen = false; return; }
        closeCCQuiet();
        launcherScreen = focusedScreenName();
        launcherOpen = true;
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

    // Tutup semua panel dulu, baru kirim dispatch ke Hyprland.
    // Race: begitu launcher melepas keyboard focus, Hyprland mengembalikan fokus ke window
    // terakhir dan bisa menimpa dispatch workspace/window. Solusi: tutup panel dulu,
    // baru dispatch setelah fokus sempat settle (docs Hyprland + pengalaman end-4/ii).
    property string pendingDispatch: ""
    function closeAndDispatch(cmd) {
        if (!cmd) return;
        pendingDispatch = cmd;
        closeCCQuiet();
        // Pastikan launcher benar-benar tertutup sebelum timer jalan
        launcherOpen = false;
        dispatchDelay.restart();
    }
    Timer {
        id: dispatchDelay
        interval: 120
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

    // =====================================================================
    //  Data Hyprland buat overview (hyprctl -j clients & monitors).
    //  Di-refresh pas launcher dibuka, dan tiap ada event window/workspace selama kebuka.
    // =====================================================================
    // Implementasi ada di HyprlandOverviewService; UI tetap pakai Sys.hyprClients / Sys.hyprMonitors.
    HyprlandOverviewService { id: hyprOverview; active: root.launcherOpen }
    readonly property var hyprClients: hyprOverview.clients
    readonly property var hyprMonitors: hyprOverview.monitors
    function refreshHypr() { hyprOverview.refresh(); }
    onLauncherOpenChanged: if (launcherOpen) { refreshHypr(); calendarOpen = false; mediaOpen = false; cheatOpen = false; }

    // =====================================================================
    //  Jam
    // =====================================================================
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var now: clock.date

    // =====================================================================
    //  Audio
    // =====================================================================
    // Implementasi ada di AudioService; UI tetap pakai Sys.volume, Sys.setVolume(), dst.
    AudioService { id: audioService }
    readonly property var sink: audioService.sink
    readonly property real volume: audioService.volume
    readonly property bool muted: audioService.muted
    readonly property bool micMuted: audioService.micMuted
    readonly property var outputDevices: audioService.outputDevices
    function setVolume(v) { audioService.setVolume(v); }
    function toggleMic() { audioService.toggleMic(); }
    function nodeLabel(n) { return audioService.nodeLabel(n); }
    function setOutput(node) { audioService.setOutput(node); }
    readonly property var mediaVisualizerLevels: mediaVisualizer.levels

    // Helper media (MPRIS), dipakai MediaCard / MediaPopup.
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

    // =====================================================================
    //  Baterai & power profile
    // =====================================================================
    readonly property bool batAvailable: UPower.displayDevice.isLaptopBattery
    readonly property real batPercent: UPower.displayDevice.percentage ?? 1   // 0..1
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

    // =====================================================================
    //  Brightness (delegasi ke BrightnessService)
    // =====================================================================
    readonly property real brightness: brightnessSvc.brightness
    readonly property bool brightnessOk: brightnessSvc.brightnessOk
    readonly property string brightnessBackend: brightnessSvc.brightnessBackend
    function setBrightness(v) { brightnessSvc.setBrightness(v); }

    // =====================================================================
    //  Toggle: Focus (DND), Keep Awake, Night Light
    // =====================================================================
    property bool dnd: false
    property bool keepAwake: false
    property bool nightLight: false
    function toggleNightLight() {
        nightLight = !nightLight;
        applyNightLight();
    }
    function applyNightLight() {
        Quickshell.execDetached(["bash", "-c",
            "pidof hyprsunset >/dev/null || (hyprsunset >/dev/null 2>&1 &) ; sleep 0.4; hyprctl hyprsunset temperature " + (nightLight ? 4200 : 6500)]);
    }
    // toggle disimpan di ~/.local/state/macmono, dipulihkan saat shell start
    property bool togglesLoaded: false
    onDndChanged: if (togglesLoaded) saveState("dnd", dnd ? "1" : "0")
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

    // =====================================================================
    //  Terminal: $TERMINAL -> xdg-terminal-exec -> kitty/foot/alacritty/wezterm/konsole
    // =====================================================================
    readonly property string termScript:
        "term_run() { for t in \"${TERMINAL:-}\" xdg-terminal-exec kitty foot alacritty wezterm konsole; do " +
        "[ -n \"$t\" ] && command -v \"$t\" >/dev/null 2>&1 || continue; " +
        "case \"$t\" in xdg-terminal-exec) exec \"$t\" \"$@\";; wezterm) exec wezterm start -- \"$@\";; *) exec \"$t\" -e \"$@\";; esac; done; " +
        "notify-send -a macmono -u critical 'No terminal found' 'Set $TERMINAL or install kitty, foot or alacritty'; }; "
    function runInTerminal(args, hold) {
        const cmd = hold
            ? ["bash", "-c", "\"$@\"; echo; read -r -p 'Press Enter to close…' _", "bash"].concat(args)
            : args;
        Quickshell.execDetached(["sh", "-c", termScript + "term_run \"$@\"", "sh"].concat(cmd));
    }

    // =====================================================================
    //  Wifi (delegasi ke WifiService)
    // =====================================================================
    readonly property bool wifiOn: wifiSvc.wifiOn
    readonly property string wifiName: wifiSvc.wifiName
    readonly property string wifiActiveUuid: wifiSvc.wifiActiveUuid
    readonly property int wifiSignal: wifiSvc.wifiSignal
    readonly property var wifiList: wifiSvc.wifiList
    readonly property var wifiProfiles: wifiSvc.wifiProfiles
    readonly property string wifiConnecting: wifiSvc.wifiConnecting
    readonly property string wifiError: wifiSvc.wifiError
    // Icon menubar: wifi-off / wifi-1 / wifi-2 / wifi
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
        Quickshell.execDetached(["sh", "-c",
            "kcmshell6 kcm_networkmanagement 2>/dev/null || nm-connection-editor 2>/dev/null || " +
            "(command -v kitty >/dev/null && kitty -e nmtui-connect) || " +
            "(command -v alacritty >/dev/null && alacritty -e nmtui-connect) || true"]);
    }

    // =====================================================================
    //  Bluetooth
    // =====================================================================
    readonly property bool btAvailable: Bluetooth.adapters.values.length > 0
    readonly property bool btOn: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property var btDevices: (Bluetooth.defaultAdapter?.devices.values ?? [])
        .filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // perangkat baru yang ketemu saat scan (punya nama, belum di-pair)
    readonly property var btNew: (Bluetooth.defaultAdapter?.devices.values ?? [])
        .filter(d => !d.paired && !d.connected && d.deviceName !== "" && d.name !== d.address.replace(/:/g, "-"))
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var btConnected: btDevices.find(d => d.connected) ?? null
    readonly property bool btScanning: Bluetooth.defaultAdapter?.discovering ?? false
    function toggleBt() { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; }
    function setBtScan(on) { if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) Bluetooth.defaultAdapter.discovering = on; }
    // pair perangkat baru -> setelah ter-pair: trust + connect otomatis
    property var btPairing: null
    property int btPairTicks: 0
    function pairBt(d) {
        btPairing = d; btPairTicks = 0;
        d.trusted = true;
        d.pair();
    }
    Timer {
        interval: 1000; repeat: true
        running: root.btPairing !== null
        onTriggered: {
            const d = root.btPairing;
            if (!d) return;
            if (d.paired) { d.trusted = true; d.connect(); root.btPairing = null; return; }
            if (++root.btPairTicks > 30) { d.cancelPair(); root.btPairing = null; }
        }
    }
    function openBtSettings() {
        closeCCQuiet();
        Quickshell.execDetached(["sh", "-c", termScript +
            "kcmshell6 kcm_bluetooth 2>/dev/null || blueman-manager 2>/dev/null || term_run bluetoothctl"]);
    }

    // =====================================================================
    //  Lock screen (hyprlock dengan tema macmono)
    // =====================================================================
    // Lock native QML (lock/LockScreen.qml). lock/lock.sh (hyprlock) cuma cadangan
    // dari hypridle kalau qs lagi mati.
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

    // closeFirst = true kalau dipanggil dari tombol di launcher/CC (panelnya ditutup dulu)
    function screenshot(mode, closeFirst) {
        if (capturing || capturePending) return;
        captureMode = mode || "copy";
        if (closeFirst) {
            closeCCQuiet();
            captureDelay.restart();   // tunggu panel benar-benar hilang dari layar
        } else {
            startCapture();
        }
    }
    function startCapture() {
        if (capturing || capturePending) return;
        const screen = focusedScreenName();
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
    Timer { id: captureDelay; interval: 260; onTriggered: root.startCapture() }
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

    function closeCCQuiet() { ccOpen = false; launcherOpen = false; wallpaperOpen = false; clipboardOpen = false; emojiOpen = false; powerOpen = false; trayMenuOpen = false; calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    // panel lain dibuka -> panel "kecil" (kalender, media, cheatsheet) ditutup
    onClipboardOpenChanged: if (clipboardOpen) { calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    onWallpaperOpenChanged: if (wallpaperOpen) { calendarOpen = false; mediaOpen = false; cheatOpen = false; }
    function togglePower() {
        if (powerOpen) { powerOpen = false; return; }
        closeCCQuiet();
        powerScreen = focusedScreenName();
        powerOpen = true;
    }

    // power: dipakai Control Center, launcher, dll.
    function power(act) {
        closeCCQuiet();
        switch (act) {
        case "logout":   Quickshell.execDetached(["sh", Quickshell.shellDir + "/core/session.sh"]); break;
        case "sleep":    Quickshell.execDetached(["sh", "-c", "systemctl suspend"]); break;
        case "restart":  Quickshell.execDetached(["sh", "-c", "systemctl reboot"]); break;
        case "shutdown": Quickshell.execDetached(["sh", "-c", "systemctl poweroff"]); break;
        case "lock":     lock(); break;
        }
    }

    // =====================================================================
    //  Wallpaper (delegasi ke WallpaperService)
    //  Wallpaper.qml menulis Sys.wallpaper langsung, jadi property harus writable
    //  dan disinkronkan dua arah dengan service.
    // =====================================================================
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
    // service -> Sys (saat load dari disk / random)
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
    // saveState masih dipakai toggle DND/night light di Sys
    function saveState(name, value) {
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.local/state/macmono\" && printf '%s' \"$2\" > \"$HOME/.local/state/macmono/$1\"",
            "sh", name, String(value)]);
    }

    // =====================================================================
    function refresh() {
        brightnessSvc.refresh();
        wifiSvc.refresh();
    }
    Timer { id: recheck; interval: 1200; onTriggered: root.refresh() }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/macmono"]);
        togglesRead.running = true;
        refresh();
        recStatusGeneration = recordingGeneration;
        recStatus.running = true;
    }
}
