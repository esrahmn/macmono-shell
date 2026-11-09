import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: root

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    function isEffectsNode(n) { return String(n?.name ?? "").indexOf("easyeffects_") === 0; }
    readonly property var outputDevices: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio
        && (!isEffectsNode(n) || n === sink))
    readonly property var inputDevices: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio
        && (!isEffectsNode(n) || n === source))

    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio
        && mediaClass(n).indexOf("Stream/Output") === 0)

    function mediaClass(n) {
        const p = n?.properties;
        return p ? String(p["media.class"] ?? "") : "";
    }

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function setMuted(m) {
        if (sink?.audio) sink.audio.muted = m;
    }

    function setSourceVolume(v) {
        if (!source?.audio) return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function setSourceMuted(m) {
        if (source?.audio) source.audio.muted = m;
    }

    function toggleMic() {
        if (source?.audio) source.audio.muted = !source.audio.muted;
    }

    function nodeLabel(n) {
        return n.nickname || n.description || n.name || "Unknown";
    }

    function streamName(n) {
        const p = n?.properties ?? ({});
        return p["application.name"] || p["media.name"] || n?.description || n?.name || "Application";
    }

    function setOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    function setStreamVolume(n, v) {
        if (!n?.audio) return;
        n.audio.muted = false;
        n.audio.volume = Math.max(0, Math.min(1, v));
    }

    function setStreamMuted(n, m) {
        if (n?.audio) n.audio.muted = m;
    }

    property string testStatus: ""
    property bool testRunning: false
    property bool testStopping: false

    readonly property string testScript:
        "tone() { d=${XDG_RUNTIME_DIR:-/tmp}/macmono-test-tone.wav; " +
        "LC_ALL=C awk 'BEGIN{rate=8000; n=rate*3/10; data=n*2; " +
        "printf \"RIFF\"; printf \"%c%c%c%c\", (36+data)%256, int((36+data)/256)%256, 0, 0; " +
        "printf \"WAVEfmt \"; printf \"%c%c%c%c\", 16, 0, 0, 0; printf \"%c%c\", 1, 0; printf \"%c%c\", 1, 0; " +
        "printf \"%c%c%c%c\", rate%256, int(rate/256)%256, 0, 0; " +
        "printf \"%c%c%c%c\", (rate*2)%256, int(rate*2/256)%256, 0, 0; " +
        "printf \"%c%c\", 2, 0; printf \"%c%c\", 16, 0; " +
        "printf \"data\"; printf \"%c%c%c%c\", data%256, int(data/256)%256, 0, 0; " +
        "for(i=0;i<n;i++){v=int(12000*sin(2*3.14159265358979*880*i/rate)); if(v<0)v+=65536; " +
        "printf \"%c%c\", v%256, int(v/256)%256}}' > $d && echo $d; }; " +
        "for f in /usr/share/sounds/freedesktop/stereo/bell.oga /usr/share/sounds/freedesktop/stereo/complete.oga /usr/share/sounds/alsa/Front_Center.wav; do " +
        "if [ -f $f ]; then " +
        "if command -v pw-play >/dev/null 2>&1; then exec pw-play $f; fi; " +
        "if command -v paplay >/dev/null 2>&1; then exec paplay $f; fi; " +
        "fi; done; " +
        "if command -v canberra-gtk-play >/dev/null 2>&1; then exec canberra-gtk-play -i bell; fi; " +
        "t=$(tone) || exit 1; " +
        "if command -v pw-play >/dev/null 2>&1; then exec pw-play $t; fi; " +
        "if command -v paplay >/dev/null 2>&1; then exec paplay $t; fi; " +
        "exit 1"

    function toggleTestSound() {
        if (testProc.running) {
            testStopping = true;
            testProc.running = false;
            return;
        }
        testStatus = "";
        testProc.running = true;
    }

    Process {
        id: testProc
        command: ["sh", "-c", root.testScript]
        onRunningChanged: root.testRunning = running
        onExited: (code) => {
            if (root.testStopping) {
                root.testStopping = false;
                root.testStatus = "";
                return;
            }
            root.testStatus = code === 0 ? "" : "failed";
        }
    }

    Timer {
        interval: 8000
        running: testProc.running
        onTriggered: if (testProc.running) root.toggleTestSound()
    }

    property bool meterWanted: false
    property bool meterAvailable: true
    property real inputLevel: 0

    readonly property string meterScript:
        "if command -v pw-record >/dev/null 2>&1; then rec='pw-record --raw --rate 8000 --channels 1 --format s16 -'; " +
        "elif command -v parec >/dev/null 2>&1; then rec='parec --raw --format=s16le --rate=8000 --channels=1'; " +
        "else exit 127; fi; " +
        "$rec 2>/dev/null | od -An -v -t d2 -w2 | " +
        "awk -v n=200 '{v=$1+0; if(v<0)v=-v; if(v>m)m=v; c++; if(c>=n){print int(m*100/32768); fflush(); m=0; c=0}}'"

    Process {
        id: meter
        running: root.meterWanted && root.meterAvailable
        command: ["sh", "-c", root.meterScript]
        stdout: SplitParser {
            onRead: line => {
                const v = Number(line);
                if (Number.isFinite(v)) root.inputLevel = Math.max(0, Math.min(1, v / 100));
            }
        }
        onExited: (code) => {
            root.inputLevel = 0;
            if (code === 127) root.meterAvailable = false;
        }
    }
}
