import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import "../../core"
import "../../shared/components"

Scope {
    id: root
    readonly property int recStopRadius: 2   // record dot becomes a small square on hover

    readonly property int menubarCellHeight: 16
    readonly property int menubarTrayItem: 23
    readonly property int menubarRecHeight: 22
    readonly property int menubarTitleMaxWidth: 300
    readonly property int wsDotWide: 20
    readonly property int wsDotNarrow: 7
    readonly property int wsDotCompact: 8
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            visible: Sys.barVisible
            anchors { top: true; left: true; right: true }
            margins { top: Theme.barMargin; left: Theme.barMargin; right: Theme.barMargin }
            implicitHeight: Theme.barHeight
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:menubar"

            IdleInhibitor { window: bar; enabled: Sys.keepAwake }

            readonly property var activeTop: ToplevelManager.activeToplevel
            readonly property string appName: {
                const id = activeTop?.appId ?? "";
                if (!id) return "Desktop";
                const parts = id.split(".");
                const n = parts[parts.length - 1];
                return n.charAt(0).toUpperCase() + n.slice(1);
            }

            readonly property string clockLabel: {
                const d = Sys.now;
                const pad = n => (n < 10 ? "0" : "") + n;
                let time;
                if (Settings.clock24h) {
                    time = pad(d.getHours()) + ":" + pad(d.getMinutes());
                    if (Settings.clockSeconds)
                        time += ":" + pad(d.getSeconds());
                } else {
                    let h = d.getHours() % 12;
                    if (h === 0)
                        h = 12;
                    time = h + ":" + pad(d.getMinutes());
                    if (Settings.clockSeconds)
                        time += ":" + pad(d.getSeconds());
                    time += d.getHours() < 12 ? " AM" : " PM";
                }
                return Settings.clockDate ? Qt.formatDateTime(d, "ddd d MMM") + "  " + time : time;
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.barHeight / 2
                color: Theme.panel

                Row {
                    anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space16

                    Item {
                        id: launcherButton
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.iconLg
                        height: Theme.iconLg

                        readonly property bool menuOpen: Sys.launcherMenuOpen && Sys.launcherMenuScreen === bar.screen.name

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -Theme.space8
                            radius: Theme.radiusControl
                            color: Theme.tile
                            visible: launcherButton.menuOpen
                        }

                        Glyph {
                            anchors.fill: parent
                            name: "enso"
                            color: Theme.text
                            opacity: launcherArea.containsMouse ? Theme.opacityHover : 1
                            Behavior on opacity { Tween { duration: Theme.durFast } }
                        }

                        MouseArea {
                            id: launcherArea
                            anchors.fill: parent
                            anchors.margins: -Theme.space8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Sys.toggleLauncherMenu(bar.screen.name)
                        }
                    }

                    Item {
                        id: ws
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.menubarCellHeight
                        width: wsRow.width
                        readonly property bool open: wsArea.containsMouse
                        readonly property int count: Math.min(Settings.menubarWorkspaceMax, Math.max(Settings.menubarWorkspaceMin, Hyprland.focusedWorkspace?.id ?? 0,
                                                                           ...Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0 && id <= Settings.menubarWorkspaceMax)))

                        MouseArea {
                            id: wsArea
                            anchors.fill: wsRow
                            anchors.margins: -Theme.space8
                            hoverEnabled: true
                            onWheel: (e) => {
                                Hyprland.dispatch("hl.dsp.focus({workspace = \"r" + (e.angleDelta.y > 0 ? "-1" : "+1") + "\"})");
                            }
                        }

                        Row {
                            id: wsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Repeater {
                                model: ws.count
                                delegate: Item {
                                    id: cell
                                    required property int index
                                    readonly property int num: index + 1
                                    readonly property bool active: Hyprland.focusedWorkspace?.id === num
                                    readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === num)
                                    readonly property real dotW: ws.open ? (active ? root.wsDotWide : root.wsDotNarrow) : (active ? root.wsDotCompact : 0)
                                    readonly property real gap: ws.open ? Theme.space8 : 0

                                    height: root.menubarCellHeight
                                    width: dotW + (index < ws.count - 1 ? gap : 0)
                                    clip: false
                                    Behavior on width { Tween {} }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: cell.dotW
                                        height: cell.dotW > 0 ? (cell.active && ws.open ? 7 : (cell.active ? 8 : 7)) : 0
                                        radius: height / 2
                                        color: cell.active ? Theme.accent : (cell.occupied ? Theme.dim : Theme.faint)
                                        opacity: cell.dotW > 1 ? 1 : 0
                                        Behavior on width { Tween {} }
                                        Behavior on color { TweenColor {} }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -Theme.space2
                                        enabled: ws.open
                                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + cell.num + "})")
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, root.menubarTitleMaxWidth)
                        elide: Text.ElideRight
                        text: bar.appName
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontMd
                        font.weight: Theme.weightSemibold
                    }
                }

                MouseArea {
                    id: clockArea
                    anchors.centerIn: parent
                    width: clockText.implicitWidth + 28
                    height: bar.height
                    onClicked: Sys.toggleCalendar(bar.screen.name)
                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        text: bar.clockLabel
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontLg
                        font.weight: Theme.weightSemibold
                    }
                    Rectangle {
                        visible: Sys.notifUnread > 0
                        anchors { left: clockText.right; leftMargin: Theme.space4; verticalCenter: clockText.verticalCenter }
                        width: Settings.menuBarUnreadDotSize; height: Settings.menuBarUnreadDotSize; radius: Math.min(width, height) / 2
                        color: Theme.text
                    }
                }

                Row {
                    id: rightContent
                    anchors { right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space16

                    MouseArea {
                        id: miniMediaArea
                        readonly property var player: Sys.mediaPlayer(Mpris.players.values, -1)
                        visible: player !== null
                        anchors.verticalCenter: parent.verticalCenter
                        width: Sys.mediaPopupWidth
                        height: bar.height - 4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Anchor comes from mediaBarRightMargin below, so this and Super+M land in the same spot.
                        onClicked: Sys.toggleMedia(bar.screen.name)

                        CavaWave {
                            id: miniMediaVisualizer
                            anchors.fill: parent
                            opacity: (miniMediaArea.player?.isPlaying && Settings.visualizerEnabled && Settings.visualizerInBar) ? 1 : 0
                            visible: opacity > 0
                            levels: Sys.mediaVisualizerLevels
                            fillOpacity: 0.10
                            // Flat strip: a pill radius (height / 2) clipped the wave's peaks at the ends.
                            cornerRadius: 0
                        }
                    }

                    // Publishes the popup anchor: the card is as wide as this strip, so its left edge lands on
                    // the visualizer's left edge. Shared with the Super+M shortcut through Sys.toggleMedia().
                    Binding {
                        target: Sys
                        property: "mediaBarRightMargin"
                        value: Theme.barMargin + Theme.space16 + rightContent.width - miniMediaArea.width
                    }

                    Row {
                        id: trayRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space12
                        layer.enabled: trayRow.width > 0
                        layer.effect: MultiEffect { saturation: -1.0 }
                        Repeater {
                            model: SystemTray.items
                            delegate: MouseArea {
                                id: trayItem
                                required property var modelData
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.menubarTrayItem; height: root.menubarTrayItem
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: (e) => {
                                    if (e.button === Qt.MiddleButton) { modelData.secondaryActivate(); return; }
                                    if (e.button === Qt.LeftButton && !modelData.onlyMenu) { modelData.activate(); return; }
                                    if (modelData.hasMenu) {
                                        const p = trayItem.mapToItem(null, 0, 0);
                                        Sys.openTrayMenu(modelData, bar.screen.name, p.x + Theme.barMargin + trayItem.width / 2);
                                    }
                                }
                                onWheel: (w) => modelData.scroll(w.angleDelta.y, false)
                                IconImage {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.verticalCenter: parent.verticalCenter
                        width: statusRow.implicitWidth
                        height: bar.height
                        onClicked: Sys.toggleCC(bar.screen.name)

                        Row {
                            id: statusRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space12

                            Rectangle {
                                visible: Sys.recActive
                                anchors.verticalCenter: parent.verticalCenter
                                width: recRow.implicitWidth + 18; height: root.menubarRecHeight; radius: Math.min(width, height) / 2
                                color: recArea.containsMouse ? Theme.accentHover : Theme.accent
                                Row {
                                    id: recRow
                                    anchors.centerIn: parent
                                    spacing: Theme.space8
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Settings.menuBarRecordDotSize; height: Settings.menuBarRecordDotSize; radius: recArea.containsMouse ? root.recStopRadius : Math.min(width, height) / 2
                                        color: Theme.textOnAccent
                                        SequentialAnimation on opacity {
                                            running: Sys.recActive && !recArea.containsMouse; loops: Animation.Infinite
                                            NumberAnimation { to: 0.3; duration: Theme.durPulse; easing.type: Theme.easeInOut }
                                            NumberAnimation { to: 1; duration: Theme.durPulse; easing.type: Theme.easeInOut }
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: recArea.containsMouse ? "Stop" : Sys.recLabel
                                        color: Theme.textOnAccent
                                        font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
                                        font.features: ({ "tnum": 1 })
                                    }
                                }
                                MouseArea {
                                    id: recArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Sys.recordStop()
                                }
                            }

                            Row {
                                visible: Sys.recording || Sys.micInUse || Sys.camInUse
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space8
                                Rectangle {
                                    visible: Sys.recording
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Settings.menuBarRecordingDotSize; height: Settings.menuBarRecordingDotSize; radius: Math.min(width, height) / 2
                                    color: Theme.text
                                    SequentialAnimation on opacity {
                                        running: Sys.recording; loops: Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: Theme.durPulse; easing.type: Theme.easeInOut }
                                        NumberAnimation { to: 1; duration: Theme.durPulse; easing.type: Theme.easeInOut }
                                    }
                                }
                                Row {
                                    visible: Sys.micInUse || Sys.camInUse
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space4
                                    Glyph { visible: Sys.camInUse; width: Theme.iconLg; height: Theme.iconLg; name: "camera"; color: Theme.text }
                                    Glyph { visible: Sys.micInUse; width: Theme.iconLg; height: Theme.iconLg; name: "mic-fill"; color: Theme.text }
                                }
                            }

                            Glyph {
                                visible: Sys.micMuted
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconLg; height: Theme.iconLg
                                name: "mic-off"
                                color: Theme.text
                            }
                            Glyph {
                                visible: Sys.dnd
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconLg; height: Theme.iconLg
                                name: "moon"
                                color: Theme.text
                            }
                            Glyph {
                                visible: Sys.keepAwake
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconLg; height: Theme.iconLg
                                name: "coffee"
                                color: Theme.text
                            }
                            Text {
                                visible: Sys.kbLayoutMulti
                                anchors.verticalCenter: parent.verticalCenter
                                text: Sys.kbLayout
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSm
                                font.weight: Theme.weightSemibold
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconLg; height: Theme.iconLg
                                name: Sys.wifiGlyph
                                color: Sys.wifiOn ? Theme.text : Theme.dim
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconLg; height: Theme.iconLg
                                name: Sys.muted ? "mute" : Sys.volume <= 0.005 ? "volume-zero" : Sys.volume < 0.5 ? "volume-low" : "volume"
                                color: Theme.text
                            }

                            Row {
                                visible: Sys.batAvailable
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(Sys.batPercent * 100) + "%"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontMd
                                }
                                BatteryIcon { anchors.verticalCenter: parent.verticalCenter }
                                Glyph {
                                    visible: Sys.batCharging
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.iconSm; height: Theme.iconSm
                                    name: "bolt"
                                    color: Theme.text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
