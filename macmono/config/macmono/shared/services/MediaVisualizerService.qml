import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying) ?? null
    readonly property bool active: activePlayer !== null
    property bool enabled: true
    property bool wanted: true
    property bool forceRun: false
    // Set while a fullscreen window covers the bar: no point drawing a wave nobody can see.
    property bool paused: false
    property real gain: 1.0
    // Must match `bars` in features/media/config/cava-mini.conf.
    readonly property int bars: 24
    property var levels: Array(bars).fill(0)

    function updateLevels(frame) {
        const values = frame.trim().split(";").filter(value => value.length > 0).map(Number);
        if (values.length !== levels.length || values.some(value => !Number.isFinite(value)))
            return;
        levels = values.map(value => Math.max(0, Math.min(1000, value * gain)));
    }

    Process {
        id: cava
        running: root.enabled && ((root.active && root.wanted && !root.paused) || root.forceRun)
        command: ["cava", "-p", Quickshell.shellDir + "/features/media/config/cava-mini.conf"]
        stdout: SplitParser {
            onRead: line => root.updateLevels(line)
        }
        onRunningChanged: if (!running) root.levels = Array(root.bars).fill(0)
    }
}
