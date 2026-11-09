import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string osName: "Linux"
    property string kernelVersion: ""
    property string architecture: ""

    function uptimeSeconds() {
        return boot > 0 ? boot + Math.max(0, (Date.now() - bootStamp) / 1000) : 0;
    }

    property var details: ({})
    property bool detailsRequested: false
    function loadDetails() {
        if (detailsRequested) return;
        detailsRequested = true;
        detailsProc.running = true;
    }
    function parseDetails(text) {
        const out = ({});
        for (const line of String(text).split("\n")) {
            const i = line.indexOf("\t");
            if (i > 0) out[line.slice(0, i)] = line.slice(i + 1).trim();
        }
        return out;
    }
    Process {
        id: detailsProc
        command: ["bash", Quickshell.shellDir + "/scripts/session/system-info.sh"]
        stdout: StdioCollector { onStreamFinished: root.details = root.parseDetails(text) }
    }

    property real boot: 0
    property real bootStamp: 0

    function parseOsRelease(text) {
        let name = "";
        for (const line of String(text).split("\n")) {
            const m = line.match(/^(PRETTY_NAME|NAME)="?(.*?)"?\s*$/);
            if (!m) continue;
            if (m[1] === "PRETTY_NAME") return m[2].trim();
            if (name === "") name = m[2].trim();
        }
        return name !== "" ? name : "Linux";
    }

    Process {
        command: ["cat", "/etc/os-release"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.osName = root.parseOsRelease(text)
        }
    }

    Process {
        command: ["uname", "-r"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.kernelVersion = text.trim() }
    }

    Process {
        command: ["uname", "-m"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.architecture = text.trim() }
    }

    Process {
        command: ["cat", "/proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text);
                if (isFinite(v)) {
                    root.boot = v;
                    root.bootStamp = Date.now();
                }
            }
        }
    }
}
