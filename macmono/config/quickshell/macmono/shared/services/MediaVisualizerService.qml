import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying) ?? null
    readonly property bool active: activePlayer !== null
    property var levels: Array(32).fill(0)

    function updateLevels(frame) {
        const values = frame.trim().split(";").filter(value => value.length > 0).map(Number);
        if (values.length !== levels.length || values.some(value => !Number.isFinite(value)))
            return;
        levels = values.map(value => Math.max(0, Math.min(1000, value)));
    }

    Process {
        id: cava
        running: root.active
        command: ["cava", "-p", Quickshell.shellDir + "/features/media/config/cava-mini.conf"]
        stdout: SplitParser {
            onRead: line => root.updateLevels(line)
        }
        onRunningChanged: if (!running) root.levels = Array(32).fill(0)
    }
}
