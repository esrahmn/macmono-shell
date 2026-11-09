import QtQuick
import Quickshell.Io
import "../../core"
import "../../shared/components"

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
    property string requestStage: ""
    property bool retryAvailable: false
    property int retryCount: 0
    readonly property int maxRetries: 3

    MediaClock { id: clock; player: root.player; active: root.active }

    readonly property string trackKey: player
        ? [player.trackTitle || "", player.trackArtist || "", player.trackAlbum || "", player.length || 0].join("\u001f")
        : ""

    function loadLyrics() {
        if (!active || !player || !player.trackTitle || !player.trackArtist) {
            lines = [];
            loading = false;
            retryAvailable = false;
            requestedTrack = "";
            status = "Hell nah cuh";
            return;
        }
        if (requestedTrack === trackKey)
            return;

        requestedTrack = trackKey;
        requestGeneration++;
        lines = [];
        activeLine = -1;
        loading = true;
        retryAvailable = false;
        status = retryCount > 0 ? "Retrying (" + retryCount + "/" + maxRetries + ")…" : "Wait";
        requestExactMatch();
    }

    function requestExactMatch() {
        requestStage = "exact";
        const args = [
            "curl", "--silent", "--show-error", "--get",
            "--connect-timeout", "4", "--max-time", "10",
            "--user-agent", "macmono-shell/1.0 (Quickshell lyrics widget)",
            "--write-out", "\n__MACMONO_REQUEST__" + requestGeneration + ":%{http_code}",
            "--data-urlencode", "artist_name=" + player.trackArtist,
            "--data-urlencode", "track_name=" + player.trackTitle,
            "--data-urlencode", "album_name=" + (player.trackAlbum || ""),
        ];
        if (player.length > 0)
            args.push("--data-urlencode", "duration=" + Math.round(player.length));
        args.push("https://lrclib.net/api/get");

        startRequest(args);
    }

    function requestSearch() {
        requestStage = "search";
        const args = [
            "curl", "--silent", "--show-error", "--get",
            "--connect-timeout", "4", "--max-time", "10",
            "--user-agent", "macmono-shell/1.0 (Quickshell lyrics widget)",
            "--write-out", "\n__MACMONO_REQUEST__" + requestGeneration + ":%{http_code}",
            "--data-urlencode", "artist_name=" + player.trackArtist,
            "--data-urlencode", "track_name=" + player.trackTitle,
        ];
        args.push("https://lrclib.net/api/search");
        startRequest(args);
    }

    function startRequest(args) {
        requestTimeout.restart();
        lyricsProcess.running = false;
        lyricsProcess.command = args;
        lyricsProcess.running = true;
    }

    function handleNetworkFailure() {
        requestTimeout.stop();
        if (retryCount < maxRetries) {
            retryCount++;
            status = "Connection failed. Retrying in 3s (" + retryCount + "/" + maxRetries + ")…";
            autoRetryTimer.start();
        } else {
            finishLookupError();;
        }
    }

    function parseLyrics(response) {
        const marker = "\n__MACMONO_REQUEST__";
        const markerIndex = response.lastIndexOf(marker);
        if (markerIndex < 0)
            return;
        const requestInfo = response.slice(markerIndex + marker.length).trim().split(":");
        const responseGeneration = Number(requestInfo[0]);
        const httpStatus = requestInfo[1] || "000";
        if (responseGeneration !== requestGeneration || requestedTrack !== trackKey)
            return;

        requestTimeout.stop();
        response = response.slice(0, markerIndex);

        let result;
        if (httpStatus === "404" && requestStage === "exact") {
            requestSearch();
            return;
        }
        if (httpStatus !== "200") {
            if (httpStatus === "404" && requestStage === "search") {
                loading = false;
                retryAvailable = true;
                status = "Lyrics not found · Tap to retry";
                return;
            }
            handleNetworkFailure();
            return;
        }
        try { result = JSON.parse(response); }
        catch (error) {
            handleNetworkFailure();
            return;
        }

        if (requestStage === "exact") {
            if (!result || typeof result !== "object" || Array.isArray(result)) {
                handleNetworkFailure();
                return;
            }
            if (applyLyrics(result))
                return;
            requestSearch();
            return;
        }

        if (!Array.isArray(result)) {
            handleNetworkFailure();
            return;
        }
        const expectedTitle = normalizeTitle(player.trackTitle);
        const expectedArtist = normalizeText(player.trackArtist);
        const match = result.find(candidate => {
            const titleMatches = normalizeTitle(candidate.trackName || "") === expectedTitle;
            const candidateArtist = normalizeText(candidate.artistName || "");
            const artistMatches = candidateArtist === expectedArtist
                || candidateArtist.startsWith(expectedArtist + " ")
                || candidateArtist.endsWith(" " + expectedArtist)
                || candidateArtist.includes(" " + expectedArtist + " ");
            return titleMatches && artistMatches && (candidate.syncedLyrics || candidate.plainLyrics);
        });
        if (!match) {
            loading = false;
            retryAvailable = true;
            status = "Retry";
            return;
        }
        applyLyrics(match);
    }

    function normalizeText(value) {
        return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();
    }

    function normalizeTitle(value) {
        return normalizeText(String(value || "").replace(/\s*[\[(](?:feat|ft)\.?.*?[\])]/ig, ""));
    }

    function applyLyrics(result) {
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
            return false;
        }
        loading = false;
        retryAvailable = false;
        retryCount = 0;
        updateActiveLine();
        return true;
    }

    function finishLookupError() {
        lines = [];
        loading = false;
        retryAvailable = true;
        status = "Retry";
    }

    function retryLookup() {
        if (!retryAvailable || loading)
            return;
        requestedTrack = "";
        retryAvailable = false;
        loadLyrics();
    }

    function updateActiveLine() {
        if (!player || lines.length === 0 || lines[0].time < 0) {
            activeLine = -1;
            return;
        }
        const position = clock.sample() + Settings.lyricsLeadSeconds;
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

    function scrollToActive(animate) {
        if (lines.length === 0)
            return;
        lyricList.forceLayout();
        const minY = lyricList.originY;
        let target = minY;
        if (activeLine >= 0) {
            const item = lyricList.itemAtIndex(activeLine);
            if (!item) {
                lyricList.positionViewAtIndex(activeLine, ListView.Center);
                return;
            }
            target = item.y + item.height / 2 - lyricList.height / 2;
        }
        const maxY = Math.max(minY, minY + lyricList.contentHeight - lyricList.height);
        target = Math.max(minY, Math.min(maxY, target));
        scrollAnim.stop();
        if (animate) {
            scrollAnim.to = target;
            scrollAnim.start();
        } else {
            lyricList.contentY = target;
        }
    }
    onActiveLineChanged: scrollToActive(true)
    onLinesChanged: Qt.callLater(() => scrollToActive(false))

    onTrackKeyChanged: {
        if (active) {
            requestedTrack = "";
            loadLyrics();
        }
    }
    onActiveChanged: {
        if (!active)
            return;
        if (retryAvailable) {
            requestedTrack = "";
            retryAvailable = false;
        }
        loadLyrics();
        Qt.callLater(() => scrollToActive(false));
    }
    Process {
        id: lyricsProcess
        stdout: StdioCollector {
            onStreamFinished: root.parseLyrics(text)
        }
    }

    Timer {
        id: requestTimeout
        interval: Settings.lyricsRequestTimeoutMs
        onTriggered: {
            if (root.loading) {
                root.loading = false;
                root.requestedTrack = "";
                root.retryAvailable = true;
                root.status = "Lookup timed out · Tap to retry";
            }
        }
    }

    Timer {
        id: autoRetryTimer
        interval: Settings.lyricsRetryDelayMs
        repeat: false
        onTriggered: {
            root.requestedTrack = "";
            root.loadLyrics();
        }
    }

    Timer {
        interval: Settings.lyricsSyncIntervalMs
        repeat: true
        running: root.active && root.player !== null && root.player.isPlaying && root.lines.length > 0 && root.lines[0].time >= 0
        onTriggered: {
            root.updateActiveLine();
        }
    }

    Connections {
        target: clock
        function onPolled() { root.updateActiveLine(); }
    }

    Component.onCompleted: loadLyrics()

    ListView {
        id: lyricList
        anchors.fill: parent
        clip: true
        topMargin: Theme.space4
        bottomMargin: Theme.space16
        spacing: Theme.space12
        model: root.lines
        boundsBehavior: Flickable.StopAtBounds
        visible: root.lines.length > 0
        highlightRangeMode: ListView.NoHighlightRange
        NumberAnimation { id: scrollAnim; target: lyricList; property: "contentY"; duration: Theme.animScroll; easing.type: Theme.easeOut }
        delegate: Text {
            required property var modelData
            required property int index
            width: lyricList.width - Theme.space8
            text: modelData.text
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: index === root.activeLine ? Theme.text : Theme.dim
            opacity: root.activeLine < 0 || index === root.activeLine ? 1 : Theme.opacityDim
            Behavior on color { ColorAnimation { duration: Theme.animBase } }
            Behavior on opacity { NumberAnimation { duration: Theme.animBase } }
            font.family: Theme.font
            font.pixelSize: index === root.activeLine ? Theme.fontDisplayMd : Theme.fontHeading
            font.weight: index === root.activeLine ? Font.DemiBold : Font.Normal
        }
    }

    Text {
        anchors.fill: parent
        visible: root.lines.length === 0
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.loading ? "Looking for lyrics…" : root.status
        color: Theme.faint
        font.family: Theme.font; font.pixelSize: Theme.fontBody
        font.underline: root.retryAvailable
        MouseArea {
            anchors.fill: parent
            enabled: root.retryAvailable
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.retryLookup()
        }
    }
}
