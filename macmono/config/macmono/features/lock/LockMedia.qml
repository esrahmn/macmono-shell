pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../core"
import "../../shared/components"

Rectangle {
    id: root

    property var player: null
    property real pos: 0
    readonly property real len: player?.length ?? 0

    implicitHeight: row.implicitHeight + Theme.space16 * 2
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.line

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
        running: root.visible && root.player !== null && root.player.isPlaying && Sys.locked
        onTriggered: {
            root.pos = clock.sample();
        }
    }

    onVisibleChanged: {
        if (visible && player && Sys.locked)
            pos = clock.sample();
    }

    component CtlButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool primary: false
        signal clicked()
        readonly property int sizeNormal: 32
        readonly property int sizePrimary: 40
        implicitWidth: primary ? sizePrimary : sizeNormal
        implicitHeight: implicitWidth
        radius: width / 2
        color: primary ? Theme.inverse : (hover.hovered ? Theme.tileHover : Theme.transparent)
        scale: tap.pressed ? Theme.pressScale : 1
        Behavior on color { TweenColor { duration: Theme.durFast } }
        Glyph {
            anchors.centerIn: parent
            width: btn.primary ? Theme.iconMd : Theme.iconMd
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
        spacing: Theme.space16

        Item {
            Layout.preferredWidth: Settings.lockMediaCoverSize
            Layout.preferredHeight: Settings.lockMediaCoverSize

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusCard
                color: Theme.tile
                visible: art.status !== Image.Ready
                Glyph { anchors.centerIn: parent; width: Theme.iconXl; height: Theme.iconXl; name: "play"; color: Theme.dim }
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: Settings.lockMediaCoverSize * 2
                sourceSize.height: Settings.lockMediaCoverSize * 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: artMask; anchors.fill: parent; radius: Theme.radiusCard; visible: false; layer.enabled: true }
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
                font.pixelSize: Theme.fontLg
                font.weight: Theme.weightSemibold
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackArtist || "Unknown artist"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSm
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space4
                Layout.preferredHeight: Settings.lockMediaProgressHeight
                radius: height / 2
                color: Theme.tile
                visible: root.len > 0
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.min(1, root.pos / Math.max(1, root.len))
                    color: Theme.accent
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space4

                Text {
                    visible: root.len > 0
                    text: root.fmt(root.pos) + " / " + root.fmt(root.len)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontXs
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
