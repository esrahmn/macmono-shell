import QtQuick
import Quickshell
import Quickshell.Io

// Wi‑Fi subsystem (NetworkManager via nmcli).
// - Status menubar: ringan, event-driven lewat nmcli monitor
// - Scan/list: on-demand + ikut refresh setelah status berubah
// - Connect: password lewat stdin (bukan argv)
Scope {
    id: root

    // Diisi Sys dari Settings.wifi*
    property int statusPollMs: 30000       // cek ulang status & sinyal (cadangan, nmcli monitor sudah event-driven)
    property int connectTimeoutMs: 45000   // batas waktu menyambung
    property int maxNetworks: 16           // maks. jaringan di daftar
    // Internal (nggak perlu diubah): jeda gabung event beruntun & jeda restart nmcli monitor
    readonly property int statusDebounceMs: 400
    readonly property int listDebounceMs: 600
    readonly property int monitorRestartMs: 5000

    property bool wifiOn: false
    property string wifiName: ""
    property string wifiActiveUuid: ""
    property int wifiSignal: 0
    property var wifiList: []
    property var wifiProfiles: []
    property string wifiConnecting: ""
    property string wifiError: ""
    property string wifiConnectRequestSsid: ""
    property bool wifiConnectMayCreate: false
    property var wifiConnectKnownUuids: []
    property string wifiPendingPassword: ""

    function wifiProfile(ssid) {
        return wifiProfiles.find(p => p.name === ssid || p.ssid === ssid) || null;
    }

    function wifiKnown(ssid) {
        return wifiProfile(ssid) !== null;
    }

    // Samakan flag active di cache list dengan SSID yang lagi aktif (tanpa nunggu rescan).
    function syncListActive() {
        if (!wifiList || wifiList.length === 0)
            return;
        const name = wifiName;
        let changed = false;
        const next = wifiList.map(e => {
            const active = name !== "" && e.ssid === name;
            if (e.active !== active)
                changed = true;
            return active === e.active ? e : {
                ssid: e.ssid,
                signal: e.signal,
                security: e.security,
                secure: e.secure,
                known: e.known,
                active: active
            };
        });
        if (changed)
            wifiList = next;
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]);
        // Optimistic: radio off → anggap putus
        if (wifiOn) {
            wifiOn = false;
            wifiName = "";
            wifiSignal = 0;
            wifiActiveUuid = "";
            syncListActive();
        }
        statusDebounce.restart();
        listDebounce.restart();
    }

    function scanWifi() {
        // tampilin cache dulu biar UI nggak kosong
        if (!wifiListGet.running)
            wifiListGet.running = true;
        // minta scan baru (error "too soon" aman diabaikan)
        if (wifiOn && !wifiRescanProc.running)
            wifiRescanProc.running = true;
    }

    function connectWifi(ssid, password) {
        if (!ssid || wifiConnectProc.running || wifiConnecting !== "")
            return;
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
            wifiPendingPassword = password || "";
            wifiConnectProc.command = password
            ? ["nmcli", "--ask", "device", "wifi", "connect", ssid]
            : ["nmcli", "device", "wifi", "connect", ssid];
        }
        wifiConnectProc.running = true;
        wifiConnectTimeout.restart();
    }

    function disconnectWifi() {
        const uuid = wifiActiveUuid;
        // Optimistic UI: jangan nunggu nmcli selesai
        wifiName = "";
        wifiSignal = 0;
        wifiActiveUuid = "";
        syncListActive();
        if (uuid)
            Quickshell.execDetached(["nmcli", "connection", "down", "uuid", uuid]);
        statusDebounce.restart();
        listDebounce.restart();
    }

    function cleanupFailedWifi(ssid, knownUuids) {
        const known = (knownUuids || []).join(" ");
        const safeSsid = String(ssid || "").replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c",
                                "known='" + known + "'; ssid='" + safeSsid + "'; " +
                                "nmcli -t -f UUID,NAME connection show 2>/dev/null | while IFS=: read -r uuid name; do " +
                                "  case \" $known \" in *\" $uuid \"*) continue ;; esac; " +
                                "  [ \"$name\" = \"$ssid\" ] && nmcli connection delete uuid \"$uuid\" >/dev/null 2>&1; " +
                                "done"
        ]);
    }

    function refresh() {
        if (!wifiStatusGet.running)
            wifiStatusGet.running = true;
        if (!wifiListGet.running)
            wifiListGet.running = true;
    }

    // ---- status ringan (sumber kebenaran = koneksi aktif, bukan IN-USE stale) ----
    // Format stdout:
    //   line0: enabled|disabled
    //   line1: NAME\tUUID   (kosong kalau nggak nyambung)
    //   line2: SIGNAL       (opsional, dari AP bertanda *)
    Process {
        id: wifiStatusGet
        command: ["sh", "-c",
        "nmcli radio wifi; " +
        "nmcli -t -f NAME,UUID,TYPE connection show --active 2>/dev/null | " +
        "awk -F: '$3 ~ /wireless|802-11-wireless|wifi/ { print $1 \"\\t\" $2; exit }'; " +
        "nmcli -t -f IN-USE,SIGNAL device wifi list --rescan no 2>/dev/null | " +
        "awk -F: '$1 == \"*\" { print $2; exit }'"
        ]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const prevName = root.wifiName;
                root.wifiOn = (lines[0] || "").trim() === "enabled";

                const active = (lines[1] || "").trim();
                if (!active) {
                    root.wifiName = "";
                    root.wifiActiveUuid = "";
                    root.wifiSignal = 0;
                } else {
                    const tab = active.indexOf("\t");
                    if (tab >= 0) {
                        root.wifiName = active.slice(0, tab).replace(/\\:/g, ":");
                        root.wifiActiveUuid = active.slice(tab + 1);
                    } else {
                        root.wifiName = active.replace(/\\:/g, ":");
                        root.wifiActiveUuid = "";
                    }
                    const sig = parseInt((lines[2] || "").trim());
                    root.wifiSignal = isNaN(sig) ? root.wifiSignal : sig;
                }

                if (root.wifiError !== "" && root.wifiError === root.wifiName)
                    root.wifiError = "";

                root.syncListActive();
                // Kalau SSID berubah (connect/disconnect), refresh list biar section Connected ikut
                if (root.wifiName !== prevName)
                    listDebounce.restart();
            }
        }
    }

    Timer {
        id: statusDebounce
        interval: root.statusDebounceMs
        onTriggered: if (!wifiStatusGet.running) wifiStatusGet.running = true
    }

    Timer {
        id: listDebounce
        interval: root.listDebounceMs
        onTriggered: if (!wifiListGet.running) wifiListGet.running = true
    }

    // Fallback pelan + update kekuatan sinyal
    Timer {
        interval: root.statusPollMs
        running: true
        repeat: true
        onTriggered: statusDebounce.restart()
    }

    Process {
        id: nmMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: {
                statusDebounce.restart();
                listDebounce.restart();
            }
        }
        onExited: nmMonitorRestart.restart()
    }

    Timer {
        id: nmMonitorRestart
        interval: root.monitorRestartMs
        onTriggered: nmMonitor.running = true
    }

    // ---- rescan (minta scan baru, lalu baca ulang list) ----
    Process {
        id: wifiRescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: rescanListDelay.restart()
    }

    Timer {
        id: rescanListDelay
        interval: 2500   // kasih waktu scan selesai
        onTriggered: if (!wifiListGet.running) wifiListGet.running = true
    }

    // ---- list / scan ----
    Process {
        id: wifiListGet
        command: ["sh", "-c",
        "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null; echo '---'; " +
        "nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null | awk -F: '$3 ~ /wireless|802-11-wireless|wifi/ {print $1\"\\t\"$2}'"
        ]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const chunks = text.split("---");

                const profiles = [];
                const profileNames = ({});
                const plines = (chunks[1] || "").split("\n");
                for (let i = 0; i < plines.length; i++) {
                    const line = plines[i].trim();
                    if (!line)
                        continue;
                    const f = line.split("\t");
                    if (f.length >= 2) {
                        const name = f[0].replace(/\\:/g, ":");
                        profiles.push({ name: name, ssid: name, uuid: f[1] });
                        profileNames[name] = true;
                    }
                }
                root.wifiProfiles = profiles;

                const list = [];
                const seen = ({});
                const lines = (chunks[0] || "").split("\n");
                const activeName = root.wifiName;
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line)
                        continue;
                    // IN-USE:SSID:SIGNAL:SECURITY  (*:MyNet:80:WPA2)
                    const raw = line.replace(/\\:/g, "\u0001").split(":");
                    if (raw.length < 4)
                        continue;
                    const inUse = raw[0];
                    const security = raw[raw.length - 1].replace(/\u0001/g, ":");
                    const signal = parseInt(raw[raw.length - 2]) || 0;
                    const ssid = raw.slice(1, raw.length - 2).join(":").replace(/\u0001/g, ":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    const sec = String(security || "").toLowerCase();
                    const secure = !(sec === "" || sec === "--" || sec === "none" || sec.indexOf("open") !== -1);
                    // Utamakan SSID aktif dari status; IN-USE cuma fallback
                    const active = activeName !== "" ? (ssid === activeName) : (inUse === "*");
                    list.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        secure: secure,
                        known: !!profileNames[ssid],
                        active: active
                    });
                }
                list.sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal) || a.ssid.localeCompare(b.ssid));
                root.wifiList = list.slice(0, root.maxNetworks);
            }
        }
    }

    // ---- connect ----
    Process {
        id: wifiConnectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdinEnabled: true
        onStarted: {
            if (root.wifiPendingPassword)
                wifiConnectProc.write(root.wifiPendingPassword + "\n");
            root.wifiPendingPassword = "";
        }
        onExited: (code) => {
            wifiConnectTimeout.stop();
            root.wifiPendingPassword = "";
            if (code !== 0 && root.wifiName !== root.wifiConnectRequestSsid) {
                root.wifiError = root.wifiConnectRequestSsid;
                if (root.wifiConnectMayCreate)
                    root.cleanupFailedWifi(root.wifiConnectRequestSsid, root.wifiConnectKnownUuids);
            } else {
                root.wifiError = "";
            }
            root.wifiConnectMayCreate = false;
            root.wifiConnecting = "";
            statusDebounce.restart();
            listDebounce.restart();
        }
    }

    Timer {
        id: wifiConnectTimeout
        interval: root.connectTimeoutMs
        onTriggered: if (wifiConnectProc.running) wifiConnectProc.running = false
    }

    Component.onCompleted: {
        statusDebounce.restart();
        scanWifi();
    }
}
