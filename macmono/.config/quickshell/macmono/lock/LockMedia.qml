pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../core"
import "../ui"

// Kartu media di lock screen. Data langsung dari Mpris (D-Bus) yang sudah
// dipantau shell, jadi nggak ada playerctl/polling script sama sekali.
Rectangle {
    id: root

    property var player: null
    property real pos: 0
    readonly property real len: player?.length ?? 0

    implicitHeight: row.implicitHeight + Theme.space16 * 2
    radius: Theme.radiusXl
    color: Theme.panel
    border.width: 1
    border.color: Theme.lineStrong

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    MediaClock {
        id: clock
        player: root.player
        active: root.visible && Sys.locked
        onPolled: root.pos = clock.sample()
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.player !== null && Sys.locked
        onTriggered: {
            root.pos = clock.sample();
        }
    }

    component CtlButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool primary: false
        signal clicked()
        implicitWidth: primary ? 40 : 34
        implicitHeight: implicitWidth
        radius: width / 2
        color: primary ? Theme.inverse : (hover.hovered ? Theme.tileHover : Theme.transparent)
        scale: tap.pressed ? Theme.buttonPressedScale : 1
        Behavior on color { ColorAnimation { duration: Theme.animHover } }
        Glyph {
            anchors.centerIn: parent
            width: btn.primary ? 16 : 15
            height: width
            name: btn.glyph
            color: btn.primary ? Theme.inverseText : Theme.text
        }
        HoverHandler { id: hover }
        TapHandler { id: tap; onTapped: btn.clicked() }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Theme.space16
        spacing: Theme.space14

        Item {
            Layout.preferredWidth: 84
            Layout.preferredHeight: 84

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.tile
                visible: art.status !== Image.Ready
                Glyph { anchors.centerIn: parent; width: 22; height: 22; name: "play"; color: Theme.dim }
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: 168
                sourceSize.height: 168
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: artMask; anchors.fill: parent; radius: Theme.radius; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: parent
                visible: art.status === Image.Ready
                source: art
                saturation: -1.0
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space4

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackTitle || "Unknown title"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackArtist || "Unknown artist"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space4
                Layout.preferredHeight: 3
                radius: height / 2
                color: Theme.tileMid
                visible: root.len > 0
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.min(1, root.pos / Math.max(1, root.len))
                    color: Theme.text
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space4

                Text {
                    visible: root.len > 0
                    text: root.fmt(root.pos) + " / " + root.fmt(root.len)
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontCaption
                }
                Item { Layout.fillWidth: true }
                CtlButton {
                    glyph: "prev"
                    opacity: root.player?.canGoPrevious ? 1 : Theme.opacityDisabled
                    onClicked: if (root.player?.canGoPrevious) root.player.previous()
                }
                CtlButton {
                    primary: true
                    glyph: root.player?.isPlaying ? "pause" : "play"
                    onClicked: if (root.player?.canTogglePlaying) root.player.togglePlaying()
                }
                CtlButton {
                    glyph: "next"
                    opacity: root.player?.canGoNext ? 1 : Theme.opacityDisabled
                    onClicked: if (root.player?.canGoNext) root.player.next()
                }
            }
        }
    }
}
