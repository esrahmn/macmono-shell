import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../core"

// Isi kartu media (cover, judul, progress, tombol kontrol), dipakai bersama oleh
// kartu di Control Center (modules/MediaCard) dan popup Super+M (modules/MediaPopup).
// Bungkus (latar, padding, animasi buka) tetap tanggung jawab pemakainya.
// `roomy` = tampilan lega untuk popup yang berdiri sendiri.
ColumnLayout {
    id: root

    property var player: null
    property var players: []
    property bool panelShown: false
    property bool roomy: false
    signal playerChangeRequested(int index)

    // semua beda ukuran antara dua tampilan ada di sini
    readonly property int artRadius: roomy ? Theme.radiusCard : Theme.radiusMedium
    readonly property int artGlyph: roomy ? 24 : 22
    readonly property int switchSize: roomy ? 28 : 26
    readonly property int bigButton: roomy ? 48 : 44
    readonly property int smallButton: roomy ? 40 : 38
    readonly property int bigGlyph: roomy ? 19 : 18
    readonly property int buttonGap: roomy ? 8 : 6

    readonly property real len: player?.length ?? 0
    property real pos: 0

    spacing: roomy ? Theme.space12 : Theme.space10

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

    // Timer di atas berhenti saat pause, jadi posisi disegarkan sekali tiap panel dibuka.
    onPanelShownChanged: {
        if (panelShown && player)
            pos = clock.sample();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: root.roomy ? Theme.space14 : Theme.space12

        Rectangle {
            Layout.preferredWidth: Theme.mediaArtSize
            Layout.preferredHeight: Theme.mediaArtSize
            radius: root.artRadius
            color: Theme.tile
            clip: true
            Glyph {
                visible: art.status !== Image.Ready
                anchors.centerIn: parent
                width: root.artGlyph; height: root.artGlyph
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
            Rectangle { id: artMask; anchors.fill: parent; radius: root.artRadius; visible: false; layer.enabled: true }
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackTitle || "Unknown title"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                visible: text !== ""
                text: root.player?.trackArtist || ""
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontBody
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: (root.player?.identity || "Media") + (root.players.length > 1 ? "  ·  " + (root.players.indexOf(root.player) + 1) + "/" + root.players.length : "")
                color: Theme.faint
                font.family: Theme.font; font.pixelSize: root.roomy ? Theme.fontSmall : Theme.fontCaption
            }
        }

        MouseArea {
            id: switchArea
            visible: root.players.length > 1
            Layout.preferredWidth: root.switchSize
            Layout.preferredHeight: root.switchSize
            Layout.alignment: Qt.AlignTop
            hoverEnabled: true
            onClicked: root.playerChangeRequested((root.players.indexOf(root.player) + 1) % root.players.length)
            Rectangle { anchors.fill: parent; radius: Theme.radiusXs; color: switchArea.containsMouse ? Theme.tileHover : Theme.transparent }
            Glyph { anchors.centerIn: parent; width: Theme.icon13; height: Theme.icon13; name: "chevron"; rotation: -90; color: Theme.dim }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.len > 0
        spacing: Theme.space4
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.mediaProgressRow
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: Theme.mediaProgressHeight; radius: Math.min(width, height) / 2
                color: Theme.tileHover
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.pos / Math.max(1, root.len)))
                    height: parent.height; radius: Math.min(width, height) / 2
                    color: Theme.text
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
        RowLayout {
            Layout.fillWidth: true
            // Durasi = informasi, bukan hiasan: pakai dim, bukan faint (faint terlalu redup di atas panel).
            Text { text: Sys.formatMediaTime(root.pos); color: Theme.dim; font.family: Theme.font; font.pixelSize: Theme.fontCaption }
            Item { Layout.fillWidth: true }
            Text { text: "-" + Sys.formatMediaTime(root.len - root.pos); color: Theme.dim; font.family: Theme.font; font.pixelSize: Theme.fontCaption }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space0
        Item { Layout.fillWidth: true }
        Repeater {
            model: ["prev", "toggle", "next"]
            delegate: MouseArea {
                id: control
                required property string modelData
                readonly property bool big: modelData === "toggle"
                Layout.preferredWidth: big ? root.bigButton : root.smallButton
                Layout.preferredHeight: big ? root.bigButton : root.smallButton
                Layout.leftMargin: root.buttonGap; Layout.rightMargin: root.buttonGap
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
                    radius: Math.min(width, height) / 2
                    color: control.big ? Theme.inverse : (control.containsMouse ? Theme.tileHover : Theme.transparent)
                }
                Glyph {
                    anchors.centerIn: parent
                    width: control.big ? root.bigGlyph : 17; height: width
                    name: control.modelData === "toggle" ? (root.player?.isPlaying ? "pause" : "play") : control.modelData
                    color: control.big ? Theme.inverseText : Theme.text
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
