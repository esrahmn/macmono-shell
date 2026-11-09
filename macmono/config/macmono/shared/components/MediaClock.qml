import QtQuick
import Quickshell.Io
import "../../core"

Item {
    id: root
    visible: false

    property var player: null
    property bool active: true
    signal polled()

    property real polledPos: -1
    property real polledAt: 0
    property var pollTarget: null

    readonly property real jumpThreshold: 1.0
    readonly property real restartZone: 1.5
    readonly property int guardMs: 2500

    property int pollIntervalMs: Settings.mediaPollIntervalMs

    property real offset: 0
    property real lastRaw: -1
    property real lastAt: 0
    property bool prevPlaying: false
    property real guardUntil: 0
    property string lastTrack: ""

    onPlayerChanged: reset()

    function reset() {
        offset = 0;
        lastRaw = -1;
        guardUntil = 0;
        lastTrack = "";
        polledPos = -1;
        pollTarget = null;
        pollNow();
    }

    function pollNow() {
        const p = player;
        if (!p || !p.dbusName || poller.running)
            return;
        pollTarget = p;
        poller.command = ["busctl", "--user", "get-property", p.dbusName,
            "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Position"];
        poller.running = true;
    }

    function pollIfStale() {
        const p = player;
        if (!p || !p.dbusName || poller.running)
            return;
        if (polledPos >= 0 && Date.now() - polledAt < pollIntervalMs)
            return;
        pollNow();
    }

    function onPollResult(text) {
        const m = /x\s+(-?\d+)/.exec(text || "");
        if (!m || pollTarget !== player)
            return;
        polledPos = Number(m[1]) / 1000000;
        polledAt = Date.now();
        sample();
        polled();
    }

    function rawPosition(p, now) {
        if (polledPos >= 0)
            return polledPos + (p.isPlaying ? (now - polledAt) / 1000 : 0);
        return p.position || 0;
    }

    function sample() {
        const p = player;
        if (!p) {
            reset();
            return 0;
        }
        const now = Date.now();
        const raw = rawPosition(p, now);
        const playing = p.isPlaying;
        const track = (p.trackTitle || "") + "\u001f" + (p.trackArtist || "") + "\u001f" + (p.length || 0);

        if (track !== lastTrack) {
            lastTrack = track;
            offset = 0;
            lastRaw = -1;
            guardUntil = 0;
            polledPos = -1;
            pollNow();
        }
        if (playing !== prevPlaying)
            guardUntil = now + guardMs;

        if (lastRaw >= 0) {
            const expected = lastRaw + (prevPlaying ? (now - lastAt) / 1000 : 0);
            const jump = raw - expected;
            if (jump < -jumpThreshold && raw <= restartZone)
                offset = 0;
            if (now < guardUntil && Math.abs(jump) > jumpThreshold && raw > restartZone)
                offset -= jump;
        }
        lastRaw = raw;
        lastAt = now;
        prevPlaying = playing;
        return Math.max(0, raw + offset);
    }

    function seekTo(seconds) {
        if (!player)
            return;
        const raw = Math.max(0, seconds - offset);
        player.position = raw;
        lastRaw = raw;
        lastAt = Date.now();
        polledPos = raw;
        polledAt = Date.now();
    }

    Connections {
        target: root.player
        function onPositionChanged() { root.sample(); }
        function onPlaybackStateChanged() { root.sample(); root.pollNow(); }
        function onTrackChanged() { root.pollNow(); }
    }

    Process {
        id: poller
        stdout: StdioCollector { onStreamFinished: root.onPollResult(text) }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.active && root.player !== null
        onTriggered: {
            root.sample();
            root.pollIfStale();
        }
    }
}
