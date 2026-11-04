import QtQuick
import Quickshell
import Quickshell.Io

// Wi‑Fi subsystem (NetworkManager via nmcli).
// - Status menubar: ringan, event-driven lewat nmcli monitor
// - Scan/list: on-demand
// - Connect: password lewat stdin (bukan argv)
Scope {
    id: root

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

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]);
        statusDebounce.restart();
    }

    function scanWifi() {
        if (!wifiListGet.running)
            wifiListGet.running = true;
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
        if (!wifiActiveUuid) {
            statusDebounce.restart();
            return;
        }
        Quickshell.execDetached(["nmcli", "connection", "down", "uuid", wifiActiveUuid]);
        statusDebounce.restart();
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

    // ---- status ringan (ikon menubar) ----
    Process {
        id: wifiStatusGet
        command: ["sh", "-c",
            "nmcli radio wifi; nmcli -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no 2>/dev/null | grep '^\\*:' | head -n1; " +
            "nmcli -t -f UUID,TYPE connection show --active 2>/dev/null | awk -F: '$2 ~ /wireless|wifi/ { print $1; exit }'"
        ]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.wifiOn = (lines[0] || "").trim() === "enabled";
                root.wifiActiveUuid = (lines[2] || "").trim();
                const line = lines[1] || "";
                if (!line.startsWith("*:")) {
                    root.wifiName = "";
                    root.wifiSignal = 0;
                    return;
                }
                const rest = line.slice(2);
                const i = rest.indexOf(":");
                root.wifiSignal = parseInt(rest.slice(0, i)) || 0;
                root.wifiName = rest.slice(i + 1).replace(/\\(.)/g, "$1");
                if (root.wifiError !== "" && root.wifiError === root.wifiName)
                    root.wifiError = "";
            }
        }
    }

    Timer {
        id: statusDebounce
        interval: 700
        onTriggered: if (!wifiStatusGet.running) wifiStatusGet.running = true
    }

    // Fallback pelan + update kekuatan sinyal
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: statusDebounce.restart()
    }

    Process {
        id: nmMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: statusDebounce.restart() }
        onExited: nmMonitorRestart.restart()
    }

    Timer {
        id: nmMonitorRestart
        interval: 5000
        onTriggered: nmMonitor.running = true
    }

    // ---- list / scan ----
    Process {
        id: wifiListGet
        command: ["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null; echo '---'; " +
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
                    const active = inUse === "*";
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
                root.wifiList = list.slice(0, 16);
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
            if (!wifiListGet.running)
                wifiListGet.running = true;
        }
    }

    Timer {
        id: wifiConnectTimeout
        interval: 45000
        onTriggered: if (wifiConnectProc.running) wifiConnectProc.running = false
    }

    Component.onCompleted: {
        statusDebounce.restart();
        scanWifi();
    }
}
