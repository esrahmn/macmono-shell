import QtQuick
import Quickshell.Io

// Jam posisi lagu yang dijaga. Spotify (lewat MPRIS) kadang melaporkan Position yang loncat
// beberapa detik tepat setelah pause/play, sehingga progress bar dan lirik ikut loncat.
// Lompatan mendadak sesaat setelah pause/play dianggap salah baca: selisihnya dicatat sebagai
// `offset` lalu dikurangkan, jadi jam tetap lanjut dari posisi sebenarnya.
// Lompatan lain tetap diikuti: seek, ganti lagu, dan "previous" yang balik ke awal lagu.
// Dipakai bersama oleh MediaPlayerView (progress bar) dan LyricsView.
Item {
    id: root
    visible: false

    property var player: null
    // true = baca posisi asli dari player tiap 1 detik (set false kalau panel lagi ketutup)
    property bool active: true
    signal polled()

    // Posisi asli hasil baca langsung ke player lewat DBus. Quickshell cuma NEBAK posisi
    // (hitung maju dari posisi terakhir), dan Spotify nggak ngabarin kalau lagu di-restart
    // lewat "previous". Makanya posisi dibaca ulang sendiri di sini.
    property real polledPos: -1
    property real polledAt: 0
    property var pollTarget: null

    // lompatan > jumpThreshold detik dalam guardMs setelah pause/play = salah baca,
    // kecuali mendarat di dekat awal lagu (restartZone) karena itu "previous" yang sah.
    readonly property real jumpThreshold: 1.0
    readonly property real restartZone: 1.5
    readonly property int guardMs: 2500

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

    // Baca posisi (detik) yang sudah dikoreksi, sekaligus memperbarui state jam.
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
            // lagu di-restart (previous): ikut, dan buang koreksi lama
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

    // Seek ke `seconds` (posisi yang tampil), lalu rebase jam supaya seek ini nggak dianggap salah baca.
    function seekTo(seconds) {
        if (!player)
            return;
        const raw = Math.max(0, seconds - offset);
        player.position = raw;
        lastRaw = raw;
        lastAt = Date.now();
    }

    // Tangkap lompatan yang terjadi di antara polling (mis. saat popup tertutup).
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
        onTriggered: root.pollNow()
    }
}
