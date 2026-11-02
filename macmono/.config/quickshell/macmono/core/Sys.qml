pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../services"

Singleton {
    id: root

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
    // ---------------- indikator privasi ----------------
    // mic dipakai = ada stream capture audio dari app (selain peak-meter / efek audio)
    readonly property bool micInUse: Pipewire.nodes.values.some(n => {
        if (!n.isStream || n.isSink || !n.audio) return false;
        const app = String(n.properties?.["application.name"] ?? n.properties?.["node.name"] ?? n.name ?? "").toLowerCase();
        return !/easyeffects|pavucontrol|cava|quickshell|pipewire|wireplumber/.test(app);
    })
    property bool camInUse: false
    property bool recordingProc: false     // wf-recorder / gpu-screen-recorder / wl-screenrec jalan
    property int recordingGeneration: 0
    property int privCheckGeneration: 0
    // layar sedang di-capture lewat portal (OBS, share layar Discord/Meet, dll.) -> ada node video dari xdg-desktop-portal
    readonly property bool screencast: Pipewire.nodes.values.some(n => {
        const p = n.properties ?? {};
        const mc = String(p["media.class"] ?? "");
        const who = (String(n.name ?? "") + " " + String(p["application.name"] ?? "") + " " + String(p["node.name"] ?? "")).toLowerCase();
        return mc === "Video/Source" && /xdp|portal|screencast/.test(who);
    })
    readonly property bool recording: (recordingProc && !recActive) || screencast
    Process {
        id: privProc
        command: ["sh", "-c",
            "c=0; for d in /dev/video*; do [ -e \"$d\" ] || continue; fuser -s \"$d\" 2>/dev/null && { c=1; break; }; done; " +
            "r=0; pidof wf-recorder gpu-screen-recorder wl-screenrec >/dev/null 2>&1 && r=1; echo \"$c $r\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                root.camInUse = f[0] === "1";
                root.recordingProc = f[1] === "1";
                const stable = root.privCheckGeneration === root.recordingGeneration;
                if (root.recActive && !root.recordingProc && stable)
                    root.recActive = false;
                // perekam masih hidup padahal UI mengira berhenti (stop gagal / state telat) -> sinkron ke record.sh
                else if (!root.recActive && root.recordingProc && stable && !root.recStartPending && !root.recStopping) {
                    root.recStatusGeneration = root.recordingGeneration;
                    recStatus.running = true;
                }
                if (!root.recordingProc) root.recStopping = false;
            }
        }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!privProc.running) {
                root.privCheckGeneration = root.recordingGeneration;
                privProc.running = true;
            }
        }
    }

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
    property bool mediaOpen: false
    property string mediaScreen: ""
    function toggleMedia() {
        if (mediaOpen) { mediaOpen = false; return; }
        closeCCQuiet();
        mediaScreen = focusedScreenName();
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

    // Tutup semua panel dulu, baru kirim dispatch ke Hyprland. Begitu launcher melepas
    // keyboard, Hyprland balikin fokus ke window terakhir; dispatch yang dikirim sebelum itu
    // bakal ketimpa (workspace "balik lagi"). Jadi dispatch-nya ditunda sebentar.
    property string pendingDispatch: ""
    function closeAndDispatch(cmd) {
        pendingDispatch = cmd;
        closeCCQuiet();
        dispatchDelay.restart();
    }
    Timer {
        id: dispatchDelay
        interval: 90
        onTriggered: { if (root.pendingDispatch) Hyprland.dispatch(root.pendingDispatch); root.pendingDispatch = ""; }
    }

    function toggleClipboard() {
        if (clipboardOpen) { clipboardOpen = false; return; }
        closeCCQuiet();
        clipboardScreen = focusedScreenName();
        clipboardOpen = true;
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
    //  Brightness
    // =====================================================================
    // backlight laptop lewat brightnessctl; monitor eksternal (DDC/CI) lewat ddcutil kalau ada
    property real brightness: 0.5
    property bool brightnessOk: false
    property string brightnessBackend: ""   // "backlight" | "ddc"
    property int ddcMax: 100
    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v));
        if (brightnessBackend === "ddc") ddcSetDebounce.restart();   // ddcutil lambat (~0.5 dtk/panggilan)
        else brightSet.exec(["brightnessctl", "--class", "backlight", "set", Math.round(brightness * 100) + "%", "-q"]);
    }
    Timer {
        id: ddcSetDebounce
        interval: 250
        onTriggered: {
            if (brightSet.running) { restart(); return; }
            brightSet.exec(["ddcutil", "--noverify", "setvcp", "10", String(Math.round(root.brightness * root.ddcMax))]);
        }
    }
    Process {
        id: brightGet
        command: ["sh", "-c",
            "brightnessctl -m -c backlight 2>/dev/null | grep -q . && exec brightnessctl -m -c backlight; " +
            "command -v ddcutil >/dev/null && ddcutil getvcp 10 --brief 2>/dev/null | awk '$1 == \"VCP\" { print \"ddc,\" $4 \",\" $5 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f[0] === "ddc" && f.length >= 3) {
                    // format: ddc,current,max
                    root.ddcMax = parseInt(f[2]) || 100;
                    root.brightness = (parseInt(f[1]) || 0) / root.ddcMax;
                    root.brightnessBackend = "ddc";
                    root.brightnessOk = true;
                } else if (f.length >= 4) {
                    // format brightnessctl: device,class,current,percent%,max
                    root.brightness = parseInt(f[3]) / 100;
                    root.brightnessBackend = "backlight";
                    root.brightnessOk = true;
                }
            }
        }
    }
    Process { id: brightSet }

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
    //  Wi-Fi
    // =====================================================================
    property bool wifiOn: false
    property string wifiName: ""
    property string wifiActiveUuid: ""
    property var wifiList: []
    function toggleWifi() {
        wifiOn = !wifiOn;
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "on" : "off"]);
        recheck.restart();
    }
    function scanWifi() {
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        wifiListGet.running = true;
        recheck.restart();      // hasil rescan baru ada beberapa detik kemudian
    }
    // connect: jaringan tersimpan -> "connection up"; jaringan baru -> "device wifi connect" (+ password kalau ada)
    property string wifiConnecting: ""      // SSID yang lagi disambungkan
    property string wifiError: ""           // SSID yang gagal (password salah, dll.)
    property string wifiConnectRequestSsid: ""
    property bool wifiConnectMayCreate: false   // perintah `device wifi connect` bisa bikin profil baru
    property var wifiConnectKnownUuids: []      // profil yang sudah ada sebelum mencoba konek
    property var wifiProfiles: []
    function wifiProfile(ssid) {
        const matching = wifiProfiles.filter(profile => profile.ssid === ssid);
        return matching.find(profile => profile.uuid === wifiActiveUuid) ?? matching[0] ?? null;
    }
    function connectWifi(ssid, password) {
        if (!ssid || wifiConnectProc.running || wifiConnecting !== "") return;
        wifiError = "";
        wifiConnecting = ssid;
        wifiConnectRequestSsid = ssid;
        const profile = wifiProfile(ssid);
        wifiConnectMayCreate = false;
        if (profile && !password) {
            wifiConnectProc.command = ["nmcli", "connection", "up", "uuid", profile.uuid];
        } else {
            wifiConnectMayCreate = true;
            wifiConnectKnownUuids = wifiProfiles.map(p => p.uuid);
            // Password dikirim lewat stdin (--ask), bukan argumen: argv kebaca semua user lewat `ps`.
            wifiPendingPassword = password || "";
            wifiConnectProc.command = password
                ? ["nmcli", "--ask", "device", "wifi", "connect", ssid]
                : ["nmcli", "device", "wifi", "connect", ssid];
        }
        wifiConnectProc.running = true;
        wifiConnectTimeout.restart();
    }
    property string wifiPendingPassword: ""
    // nmcli bisa nunggu input selamanya kalau password ditolak di tengah jalan
    Timer { id: wifiConnectTimeout; interval: 45000; onTriggered: if (wifiConnectProc.running) wifiConnectProc.running = false }
    function disconnectWifi() {
        if (!wifiActiveUuid) {
            recheck.restart();
            return;
        }
        Quickshell.execDetached(["nmcli", "connection", "down", "uuid", wifiActiveUuid]);
        recheck.restart();
    }
    function openWifiSettings() {
        closeCCQuiet();
        Quickshell.execDetached(["sh", "-c", termScript +
            "kcmshell6 kcm_networkmanagement 2>/dev/null || nm-connection-editor 2>/dev/null || term_run nmtui-connect"]);
    }
    Process {
        id: wifiConnectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdinEnabled: true
        onStarted: {
            if (root.wifiPendingPassword) wifiConnectProc.write(root.wifiPendingPassword + "\n");
            root.wifiPendingPassword = "";
        }
        onExited: (code) => {
            wifiConnectTimeout.stop();
            root.wifiPendingPassword = "";
            if (code !== 0) {
                root.wifiError = root.wifiConnectRequestSsid;
                // koneksi baru yang gagal (password salah, dll.) jangan ditinggal tersimpan
                if (root.wifiConnectMayCreate) root.cleanupFailedWifi(root.wifiConnectRequestSsid, root.wifiConnectKnownUuids);
            }
            root.wifiConnectMayCreate = false;
            root.wifiConnecting = "";
            root.wifiConnectRequestSsid = "";
            recheck.restart();
        }
    }
    // Hapus HANYA profil wifi ber-SSID ini yang belum ada sebelum percobaan konek (jadi profil lama aman).
    function cleanupFailedWifi(ssid, knownUuids) {
        if (!ssid || wifiCleanupProc.running) return;
        wifiCleanupProc.command = ["sh", "-c",
            "ssid=$(printf %s \"$1\" | tr -d '\\134'); shift; known=\" $* \"; " +
            "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r u t; do " +
            "[ \"$t\" = 802-11-wireless ] || continue; " +
            "case \"$known\" in *\" $u \"*) continue;; esac; " +
            "s=$(nmcli -g 802-11-wireless.ssid connection show uuid \"$u\" 2>/dev/null | tr -d '\\134'); " +
            "[ \"$s\" = \"$ssid\" ] && nmcli connection delete uuid \"$u\" >/dev/null 2>&1; " +
            "done; true", "sh", ssid].concat(knownUuids);
        wifiCleanupProc.running = true;
    }
    Process {
        id: wifiCleanupProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        onExited: recheck.restart()
    }
    function wifiKnown(ssid) { return wifiProfile(ssid) !== null; }
    Process {
        id: wifiGet
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: wifiListGet
        // Mode list `connection show` nggak menerima field 802-11-wireless.ssid, jadi SSID tiap profil
        // diambil per UUID. Profil yang SSID-nya sudah di-cache (UUID dikirim sebagai argumen) dilewati,
        // jadi cuma profil baru yang memanggil nmcli lagi. Output: "C<TAB>uuid" (cache) / "N<TAB>uuid<TAB>ssid".
        command: ["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list; " +
            "echo '@@profiles'; known=\" $* \"; " +
            "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r u t; do " +
            "[ \"$t\" = 802-11-wireless ] || continue; " +
            "case \"$known\" in *\" $u \"*) printf 'C\\t%s\\n' \"$u\"; continue;; esac; " +
            "printf 'N\\t%s\\t%s\\n' \"$u\" \"$(nmcli -g 802-11-wireless.ssid connection show uuid \"$u\" 2>/dev/null)\"; " +
            "done; " +
            "echo '@@active'; nmcli -t -f UUID,TYPE connection show --active", "sh"].concat(root.wifiProfiles.map(p => p.uuid))
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const best = ({});
                let active = "";
                let activeSignal = 0;
                const sections = text.split("@@profiles");
                const profileSections = (sections[1] || "").split("@@active");
                const unescapeFields = line => line.replace(/\\:/g, "\u0001").split(":")
                    .map(field => field.replace(/\u0001/g, ":"));
                const cached = ({});
                for (const p of root.wifiProfiles) cached[p.uuid] = p.ssid;
                root.wifiProfiles = (profileSections[0] || "").split("\n")
                    .map(line => line.split("\t"))
                    .map(f => {
                        if (f[0] === "C" && f.length >= 2) return { uuid: f[1].trim(), ssid: cached[f[1].trim()] ?? "" };
                        // nmcli -g meng-escape ":" dan "\" di dalam nilai
                        if (f[0] === "N" && f.length >= 3) return { uuid: f[1].trim(), ssid: f.slice(2).join("\t").replace(/\\(.)/g, "$1") };
                        return null;
                    })
                    .filter(profile => profile && profile.uuid && profile.ssid);
                const activeUuids = (profileSections[1] || "").split("\n")
                    .filter(line => line.trim())
                    .map(unescapeFields)
                    .filter(fields => fields.length >= 2 && /wireless/.test(fields[1]))
                    .map(fields => fields[0]);
                root.wifiActiveUuid = activeUuids.find(uuid => root.wifiProfiles.some(profile => profile.uuid === uuid)) ?? "";
                for (const line of sections[0].split("\n")) {
                    if (!line.trim()) continue;
                    const f = unescapeFields(line);
                    if (f.length < 4 || !f[1]) continue;
                    const e = { ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--", active: f[0] === "*", known: root.wifiKnown(f[1]) };
                    if (e.active) { active = e.ssid; activeSignal = e.signal; }
                    if (!best[e.ssid] || best[e.ssid].signal < e.signal || e.active) best[e.ssid] = e;
                }
                root.wifiName = active;
                root.wifiSignal = activeSignal;
                root.wifiList = Object.values(best).sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal)).slice(0, 8);
            }
        }
    }

    // Status ringan buat ikon di menubar: radio + SSID + sinyal, tanpa rescan.
    // Dipicu event `nmcli monitor` (debounce), plus polling 30 detik buat update kekuatan sinyal.
    property int wifiSignal: 0
    readonly property string wifiGlyph: !wifiOn ? "wifi-off"
        : wifiName === "" ? "wifi-none"
        : wifiSignal >= 67 ? "wifi" : wifiSignal >= 34 ? "wifi-2" : "wifi-1"
    Process {
        id: wifiStatusGet
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no | grep '^\\*:' | head -n1"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.wifiOn = (lines[0] || "").trim() === "enabled";
                const line = lines[1] || "";
                if (!line.startsWith("*:")) { root.wifiName = ""; root.wifiSignal = 0; return; }
                const rest = line.slice(2);
                const i = rest.indexOf(":");
                root.wifiSignal = parseInt(rest.slice(0, i)) || 0;
                root.wifiName = rest.slice(i + 1).replace(/\\(.)/g, "$1");
            }
        }
    }
    Timer { id: wifiStatusDebounce; interval: 700; onTriggered: if (!wifiStatusGet.running) wifiStatusGet.running = true }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: wifiStatusDebounce.restart() }
    Process {
        id: nmMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: wifiStatusDebounce.restart() }
        onExited: nmMonitorRestart.restart()
    }
    Timer { id: nmMonitorRestart; interval: 5000; onTriggered: nmMonitor.running = true }

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
        captureScreen = focusedScreenName();
        captureFile = runtimeDir + "/shot-" + captureScreen + ".png";
        capturePending = true;
        targetsGet.running = true;
        // umask 077 -> folder 0700 dan file 0600
        grimProc.exec(["sh", "-c", "umask 077; mkdir -p \"$1\" && exec grim -o \"$2\" \"$3\"", "sh", runtimeDir, captureScreen, captureFile]);
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

    function closeCCQuiet() { ccOpen = false; launcherOpen = false; wallpaperOpen = false; clipboardOpen = false; powerOpen = false; trayMenuOpen = false; calendarOpen = false; mediaOpen = false; cheatOpen = false; }
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
    //  Wallpaper
    // =====================================================================
    property string wallpaper: ""
    property bool wallpaperMono: true
    property var wallpapers: []
    property bool pendingRandom: false
    property var wallpaperReadyScreens: []
    property string wallpaperLoadError: ""
    readonly property bool wallpaperReady: wallpaper !== "" && Quickshell.screens.length > 0
        && Quickshell.screens.every(screen => wallpaperReadyScreens.includes(screen.name))
    function markWallpaperReady(path, screenName) {
        if (path !== wallpaper || !screenName || wallpaperReadyScreens.includes(screenName)) return;
        wallpaperReadyScreens = wallpaperReadyScreens.concat([screenName]);
    }
    function markWallpaperLoadError(path) {
        if (path === wallpaper) wallpaperLoadError = path;
    }
    onWallpaperChanged: {
        wallpaperReadyScreens = [];
        wallpaperLoadError = "";
    }

    function saveState(name, value) {
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.local/state/macmono\" && printf '%s' \"$2\" > \"$HOME/.local/state/macmono/$1\"", "sh", name, String(value)]);
    }
    function setWallpaper(path) { wallpaper = path; saveState("wallpaper", path); }
    function setWallpaperMono(v) { wallpaperMono = v; saveState("wallpaper_mono", v ? "1" : "0"); }
    function loadWallpapers() { wallpaperFind.running = true; }
    // thumbnail kecil di ~/.cache/macmono/thumbs (dibuat sekali di background), dipakai picker
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/macmono/thumbs/"
    function thumbFor(path) { return thumbDir + Qt.md5(path) + ".jpg"; }
    property int thumbsVersion: 0
    Process { id: thumbProc; onExited: root.thumbsVersion++ }
    function randomWallpaper() {
        if (wallpapers.length === 0) { pendingRandom = true; loadWallpapers(); return; }
        setWallpaper(wallpapers[Math.floor(Math.random() * wallpapers.length)]);
    }

    Process {
        id: wallpaperRead
        command: ["sh", "-c", "cat \"$HOME/.local/state/macmono/wallpaper\" 2>/dev/null; echo; cat \"$HOME/.local/state/macmono/wallpaper_mono\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                if (lines[0] && lines[0].trim()) root.wallpaper = lines[0].trim();
                if (lines[1] && lines[1].trim() === "0") root.wallpaperMono = false;
            }
        }
    }
    Process {
        id: wallpaperFind
        command: ["sh", "-c",
            "find \"$HOME/Pictures/Wallpapers\" \"$HOME/Pictures\" \"$HOME/Wallpapers\" \"$HOME/.local/share/backgrounds\" /usr/share/backgrounds /usr/share/wallpapers " +
            "-maxdepth 2 -type f -not -path '*/Screenshots/*' \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | awk '!seen[$0]++' | head -120"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n").filter(l => l.trim() !== "");
                if (root.pendingRandom) { root.pendingRandom = false; root.randomWallpaper(); }
                thumbProc.command = ["sh", Quickshell.shellDir + "/core/thumbs.sh"].concat(root.wallpapers);
                thumbProc.running = true;
            }
        }
    }

    // =====================================================================
    function refresh() {
        if (!brightGet.running) brightGet.running = true;
        if (!wifiGet.running) wifiGet.running = true;
        if (!wifiListGet.running) wifiListGet.running = true;
    }
    Timer { id: recheck; interval: 1200; onTriggered: root.refresh() }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/macmono"]);
        togglesRead.running = true;
        refresh();
        recStatusGeneration = recordingGeneration;
        recStatus.running = true;
        wallpaperRead.running = true;
    }
}
