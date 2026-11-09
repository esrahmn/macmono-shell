import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"

Rectangle {
    id: ov

    required property var screenInfo
    property bool live: false
    signal activated(string cmd)

    readonly property HyprlandMonitor hmon: Hyprland.monitorFor(screenInfo)
    readonly property var mon: Sys.hyprMonitors.find(m => m.name === screenInfo.name) ?? null

    readonly property int rows: Settings.overviewRows
    readonly property int cols: Settings.overviewColumns
    readonly property int perGroup: rows * cols
    readonly property real s: Settings.overviewScale
    readonly property int gap: 8

    readonly property var res: mon?.reserved ?? [0, 0, 0, 0]
    readonly property real monW: mon ? ((mon.transform % 2 === 1) ? mon.height : mon.width) / mon.scale : screenInfo.width
    readonly property real monH: mon ? ((mon.transform % 2 === 1) ? mon.width : mon.height) / mon.scale : screenInfo.height
    readonly property real wsW: Math.round((monW - res[0] - res[2]) * s)
    readonly property real wsH: Math.round((monH - res[1] - res[3]) * s)

    readonly property int activeWs: Math.max(1, hmon?.activeWorkspace?.id ?? 1)
    readonly property int group: Math.floor((activeWs - 1) / perGroup)
    readonly property int firstWs: group * perGroup + 1

    property bool dragging: false
    property int dragTarget: -1

    readonly property var clients: Sys.hyprClients.filter(c =>
        c.mapped && c.workspace && c.workspace.id >= firstWs && c.workspace.id < firstWs + perGroup)
    readonly property var byAddr: {
        const m = ({});
        for (const c of clients) m[c.address] = c;
        return m;
    }

    function cellPos(ws) {
        const i = ws - firstWs;
        return { x: (i % cols) * (wsW + gap), y: Math.floor(i / cols) * (wsH + gap) };
    }
    function wsAt(px, py) {
        const c = Math.floor(px / (wsW + gap)), r = Math.floor(py / (wsH + gap));
        if (c < 0 || c >= cols || r < 0 || r >= rows) return -1;
        if (px - c * (wsW + gap) > wsW || py - r * (wsH + gap) > wsH) return -1;
        return firstWs + r * cols + c;
    }
    function dispatch(cmd) { Hyprland.dispatch(cmd); }

    implicitWidth: grid.width + 24
    implicitHeight: grid.height + 24
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: Theme.borderThin
    border.color: Theme.line

    MouseArea { anchors.fill: parent }

    Item {
        id: grid
        anchors.centerIn: parent
        width: ov.cols * ov.wsW + (ov.cols - 1) * ov.gap
        height: ov.rows * ov.wsH + (ov.rows - 1) * ov.gap

        Repeater {
            model: ov.perGroup
            delegate: Rectangle {
                id: cell
                required property int index
                readonly property int ws: ov.firstWs + index
                readonly property bool isTarget: ov.dragging && ov.dragTarget === ws
                x: (index % ov.cols) * (ov.wsW + ov.gap)
                y: Math.floor(index / ov.cols) * (ov.wsH + ov.gap)
                width: ov.wsW
                height: ov.wsH
                radius: Theme.radiusCard
                color: isTarget ? Theme.tileHover : (cellArea.containsMouse && !ov.dragging ? Theme.tile : Theme.tileFaint)
                border.width: isTarget ? 2 : 1
                border.color: isTarget ? Theme.text : Theme.line
                Behavior on color { ColorAnimation { duration: Theme.animHover } }

                Text {
                    anchors.centerIn: parent
                    text: cell.ws
                    color: Theme.ghost
                    font.family: Theme.font
                    font.pixelSize: Math.round(ov.wsH * 0.42)
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        ov.activated("hl.dsp.focus({ workspace = " + cell.ws + " })");
                    }
                }
            }
        }

        Repeater {
            model: ScriptModel { values: ov.clients.map(c => c.address) }

            delegate: Item {
                id: w
                required property string modelData
                readonly property var c: ov.byAddr[modelData] ?? null
                readonly property var cmon: Sys.hyprMonitors.find(m => m.id === c?.monitor) ?? ov.mon
                readonly property var cres: cmon?.reserved ?? [0, 0, 0, 0]
                readonly property var cell: ov.cellPos(c?.workspace?.id ?? ov.firstWs)
                readonly property real baseX: cell.x + Math.max(0, ((c?.at[0] ?? 0) - (cmon?.x ?? 0) - cres[0]) * ov.s)
                readonly property real baseY: cell.y + Math.max(0, ((c?.at[1] ?? 0) - (cmon?.y ?? 0) - cres[1]) * ov.s)
                readonly property var toplevel: Hyprland.toplevels.values.find(t => "0x" + t.address === modelData)?.wayland ?? null

                property real dx: 0
                property real dy: 0
                property bool held: false
                property bool moved: false

                readonly property bool wantsPreview: ov.live && Settings.overviewLivePreview && toplevel !== null
                property bool capReset: false
                property int retries: 0
                function restartCapture() {
                    if (capReset) return;
                    capReset = true;
                    Qt.callLater(() => w.capReset = false);
                }
                onWantsPreviewChanged: retries = 0
                Timer {
                    interval: Settings.overviewPreviewRetryMs
                    repeat: true
                    running: w.wantsPreview && !preview.hasContent && w.retries < 6
                    onTriggered: { w.retries++; w.restartCapture(); }
                }

                visible: c !== null && c.workspace.id > 0
                x: baseX + dx
                y: baseY + dy
                width: Math.max(10, Math.min((c?.size[0] ?? 0) * ov.s, ov.wsW))
                height: Math.max(10, Math.min((c?.size[1] ?? 0) * ov.s, ov.wsH))
                z: held ? 100 : ((c?.floating ? 3 : 2) + (c?.fullscreen ? 2 : 0))
                scale: held && moved ? 1.04 : 1
                Behavior on x { enabled: !w.held; NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                Behavior on y { enabled: !w.held; NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                Behavior on scale { NumberAnimation { duration: Theme.animHover } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusXs
                    color: Theme.raised
                }

                ScreencopyView {
                    id: preview
                    anchors.fill: parent
                    captureSource: (ov.live && Settings.overviewLivePreview && !w.capReset) ? w.toplevel : null
                    live: true
                    onHasContentChanged: if (!hasContent && w.wantsPreview) w.restartCapture()
                }

                Text {
                    visible: !preview.hasContent
                    anchors { fill: parent; margins: Theme.space8 }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: w.c?.title || w.c?.class || ""
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusXs
                    color: area.containsMouse ? Theme.tileMid : Theme.transparent
                    border.width: area.containsMouse || w.held ? 2 : 1
                    border.color: area.containsMouse || w.held ? Theme.text : Theme.lineStrong
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: w.held && w.moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    property point start

                    onPressed: (m) => {
                        if (m.button !== Qt.LeftButton) return;
                        start = mapToItem(grid, m.x, m.y);
                        w.held = true;
                        w.moved = false;
                    }
                    onPositionChanged: (m) => {
                        if (!w.held) return;
                        const p = mapToItem(grid, m.x, m.y);
                        w.dx = p.x - start.x;
                        w.dy = p.y - start.y;
                        if (!w.moved && Math.hypot(w.dx, w.dy) > 6) { w.moved = true; ov.dragging = true; }
                        if (w.moved) ov.dragTarget = ov.wsAt(p.x, p.y);
                    }
                    onReleased: (m) => {
                        if (m.button === Qt.MiddleButton) {
                            ov.dispatch("hl.dsp.window.close({ window = \"address:" + w.modelData + "\" })");
                            return;
                        }
                        if (!w.held) return;
                        const target = ov.dragTarget;
                        const wasMoved = w.moved;
                        w.held = false;
                        w.moved = false;
                        ov.dragging = false;
                        ov.dragTarget = -1;
                        w.dx = 0;
                        w.dy = 0;
                        if (wasMoved) {
                            if (target > 0 && target !== w.c.workspace.id)
                                ov.dispatch("hl.dsp.window.move({ workspace = " + target + ", follow = false, window = \"address:" + w.modelData + "\" })");
                        } else {
                            ov.activated("hl.dsp.focus({ window = \"address:" + w.modelData + "\" })");
                        }
                    }
                }
            }
        }

        Rectangle {
            readonly property var p: ov.cellPos(ov.activeWs)
            visible: ov.activeWs >= ov.firstWs && ov.activeWs < ov.firstWs + ov.perGroup
            x: p.x - 1; y: p.y - 1
            width: ov.wsW + 2; height: ov.wsH + 2
            z: 50
            radius: Theme.radiusCard
            color: Theme.transparent
            border.width: Theme.borderStrong
            border.color: Theme.text
            Behavior on x { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
            Behavior on y { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
        }
    }
}
