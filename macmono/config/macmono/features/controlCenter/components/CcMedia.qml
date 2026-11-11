import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int ccMediaArtSize: 56
    readonly property int ccMediaBigButton: 40
    readonly property int ccMediaSmallButton: 28
    readonly property int ccMediaGlyph: 18
    readonly property int ccMediaBarHeight: 4
    readonly property int ccMediaSeekHit: 14

    property var player: null
    property var players: []
    property bool panelShown: false
    signal playerChangeRequested(int index)

    readonly property real len: player?.length ?? 0
    property real pos: 0

    visible: player !== null
    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 2 * Theme.space12
    radius: Theme.radiusCard
    color: Theme.tile

    MediaClock {
        id: clock
        player: root.player
        active: root.panelShown
        onPolled: root.pos = clock.sample()
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.panelShown && root.player !== null && root.player.isPlaying
        onTriggered: {
            root.player.positionChanged();
            root.pos = clock.sample();
        }
    }

    onPanelShownChanged: {
        if (panelShown && player)
            pos = clock.sample();
    }

    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space12

            // Tap the cover to switch player (only when more than one is running).
            MouseArea {
                id: artArea
                Layout.preferredWidth: root.ccMediaArtSize
                Layout.preferredHeight: root.ccMediaArtSize
                Layout.alignment: Qt.AlignVCenter
                enabled: root.players.length > 1
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.playerChangeRequested((root.players.indexOf(root.player) + 1) % root.players.length)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusCard
                    color: Theme.tile
                    clip: true
                    Glyph {
                        visible: art.status !== Image.Ready
                        anchors.centerIn: parent
                        width: Theme.iconXl; height: Theme.iconXl
                        name: "play"
                        color: Theme.dim
                    }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 144
                        sourceSize.height: 144
                        visible: false
                    }
                    Rectangle { id: artMask; anchors.fill: parent; radius: Theme.radiusCard; visible: false; layer.enabled: true }
                    MultiEffect {
                        visible: art.status === Image.Ready
                        anchors.fill: parent
                        source: art
                        saturation: -1.0
                        maskEnabled: true
                        maskSource: artMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.space2
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || "Unknown title"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                    font.letterSpacing: Theme.trackSnug
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: (root.player?.trackArtist || root.player?.identity || "").toUpperCase()
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                    font.letterSpacing: Theme.trackCaps
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                Repeater {
                    model: ["prev", "toggle", "next"]
                    delegate: MouseArea {
                        id: control
                        required property string modelData
                        readonly property bool big: modelData === "toggle"
                        readonly property int buttonSize: big ? root.ccMediaBigButton : root.ccMediaSmallButton
                        // RowLayout centers each control, so prev/next sit on the play/pause circle's axis instead of
                        // hugging the top of the row (a plain Row aligns children to the top when heights differ).
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: control.buttonSize
                        Layout.preferredHeight: control.buttonSize
                        hoverEnabled: true
                        enabled: modelData === "prev" ? (root.player?.canGoPrevious ?? false)
                               : modelData === "next" ? (root.player?.canGoNext ?? false)
                               : (root.player?.canTogglePlaying ?? false)
                        opacity: enabled ? 1 : Theme.opacityDisabled
                        onClicked: {
                            if (modelData === "prev") root.player.previous();
                            else if (modelData === "next") root.player.next();
                            else root.player.togglePlaying();
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: control.containsMouse ? Theme.tileHover : (control.big ? Theme.tile : Theme.transparent)
                            Behavior on color { TweenColor { duration: Theme.durFast } }
                        }
                        Glyph {
                            anchors.centerIn: parent
                            width: root.ccMediaGlyph; height: root.ccMediaGlyph
                            name: control.modelData === "toggle" ? (root.player?.isPlaying ? "pause" : "play") : control.modelData
                            color: Theme.text
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.ccMediaSeekHit
            visible: root.len > 0
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: root.ccMediaBarHeight; radius: height / 2
                color: Theme.tile
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.pos / Math.max(1, root.len)))
                    height: parent.height; radius: height / 2
                    color: Qt.alpha(Theme.text, Theme.opacityDim)
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: (mouse) => {
                    const target = root.len * Math.max(0, Math.min(1, mouse.x / width));
                    clock.seekTo(target);
                    root.pos = target;
                }
            }
        }
    }
}
