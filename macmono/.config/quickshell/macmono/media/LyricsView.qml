import QtQuick
import Quickshell.Io
import "../core"

Item {
    id: root

    property var player: null
    property bool active: false
    property var lines: []
    property bool loading: false
    property string status: "Lyrics will appear here"
    property int activeLine: -1
    property string requestedTrack: ""
    property int requestGeneration: 0

    readonly property string trackKey: player
        ? [player.trackTitle || "", player.trackArtist || "", player.trackAlbum || "", player.length || 0].join("\u001f")
        : ""

    function loadLyrics() {
        if (!active || !player || !player.trackTitle || !player.trackArtist) {
            lines = [];
            loading = false;
            status = "Lyrics unavailable";
            return;
        }
        if (requestedTrack === trackKey)
            return;

        requestedTrack = trackKey;
        requestGeneration++;
        lines = [];
        activeLine = -1;
        loading = true;
        status = "Searching LRCLIB…";
        requestTimeout.restart();

        const args = [
            "curl", "--fail", "--silent", "--show-error", "--get",
            "--connect-timeout", "4", "--max-time", "10",
            "--user-agent", "macmono-shell/1.0 (Quickshell lyrics widget)",
            "--write-out", "\n__MACMONO_REQUEST__" + requestGeneration,
            "--data-urlencode", "artist_name=" + player.trackArtist,
            "--data-urlencode", "track_name=" + player.trackTitle,
            "--data-urlencode", "album_name=" + (player.trackAlbum || ""),
        ];
        if (player.length > 0)
            args.push("--data-urlencode", "duration=" + Math.round(player.length));
        args.push("https://lrclib.net/api/get");

        lyricsProcess.running = false;
        lyricsProcess.command = args;
        lyricsProcess.running = true;
    }

    function parseLyrics(response) {
        const marker = "\n__MACMONO_REQUEST__";
        const markerIndex = response.lastIndexOf(marker);
        const responseGeneration = Number(response.slice(markerIndex + marker.length).trim());
        if (markerIndex < 0 || responseGeneration !== requestGeneration || requestedTrack !== trackKey)
            return;
        requestTimeout.stop();
        response = response.slice(0, markerIndex);

        let result;
        try {
            result = JSON.parse(response);
        } catch (error) {
            lines = [];
            loading = false;
            status = "Lyrics not found";
            return;
        }

        const parsed = [];
        const synced = result.syncedLyrics || "";
        for (const line of synced.split("\n")) {
            const matches = [];
            const timestampPattern = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            let match;
            while ((match = timestampPattern.exec(line)) !== null)
                matches.push(match);
            const text = line.replace(/\[(\d+):(\d+(?:\.\d+)?)\]/g, "").trim();
            if (!text)
                continue;
            for (const match of matches)
                parsed.push({ time: Number(match[1]) * 60 + Number(match[2]), text: text });
        }
        parsed.sort((a, b) => a.time - b.time);

        if (parsed.length > 0) {
            lines = parsed;
            status = "Synced lyrics";
        } else if (result.plainLyrics) {
            lines = result.plainLyrics.split("\n").map(text => ({ time: -1, text: text }));
            status = "Lyrics";
        } else {
            lines = [];
            status = "Lyrics not found";
        }
        loading = false;
        updateActiveLine();
    }

    function updateActiveLine() {
        if (!player || lines.length === 0 || lines[0].time < 0) {
            activeLine = -1;
            return;
        }
        const position = player.position || 0;
        let low = 0;
        let high = lines.length - 1;
        let match = -1;
        while (low <= high) {
            const middle = Math.floor((low + high) / 2);
            if (lines[middle].time <= position) {
                match = middle;
                low = middle + 1;
            } else {
                high = middle - 1;
            }
        }
        activeLine = match;
    }

    onTrackKeyChanged: {
        if (active) {
            requestedTrack = "";
            loadLyrics();
        }
    }
    onActiveChanged: if (active) loadLyrics()
    Process {
        id: lyricsProcess
        stdout: StdioCollector {
            onStreamFinished: root.parseLyrics(text)
        }
    }

    Timer {
        id: requestTimeout
        interval: 11000
        onTriggered: {
            if (root.loading) {
                root.loading = false;
                root.requestedTrack = "";
                root.status = "Lyrics unavailable";
            }
        }
    }

    Timer {
        interval: 80
        repeat: true
        running: root.active && root.player !== null && root.lines.length > 0 && root.lines[0].time >= 0
        onTriggered: {
            if (!root.player)
                return;
            root.player.positionChanged();
            root.updateActiveLine();
        }
    }

    Component.onCompleted: loadLyrics()

    Column {
        anchors.fill: parent
        spacing: Theme.space8

        Item {
            width: parent.width
            height: 20
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Lyrics"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
            }
            Text {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: root.status
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontCaption
            }
        }

        ListView {
            id: lyricList
            width: parent.width
            height: parent.height - 28
            clip: true
            spacing: Theme.space8
            model: root.lines
            boundsBehavior: Flickable.StopAtBounds
            visible: root.lines.length > 0
            currentIndex: root.activeLine
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 360
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: height / 2
            preferredHighlightEnd: height / 2
            highlight: Item {}
            delegate: Text {
                required property var modelData
                required property int index
                width: lyricList.width - Theme.space8
                text: modelData.text
                wrapMode: Text.Wrap
                color: index === root.activeLine ? Theme.text : Theme.dim
                opacity: root.activeLine < 0 || index === root.activeLine ? 1 : Theme.opacityDim
                Behavior on color { ColorAnimation { duration: Theme.animBase } }
                Behavior on opacity { NumberAnimation { duration: Theme.animBase } }
                font.family: Theme.font
                font.pixelSize: index === root.activeLine ? Theme.fontSubtitle : Theme.fontBodyLg
                font.weight: index === root.activeLine ? Font.DemiBold : Font.Normal
            }
        }

        Text {
            width: parent.width
            height: parent.height - 28
            visible: root.lines.length === 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.loading ? "Looking for lyrics…" : root.status
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
        }
    }
}
