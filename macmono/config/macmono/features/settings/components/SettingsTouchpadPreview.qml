import QtQuick
import "../../../core"

// Pratinjau Touchpad: jari bergeser ke atas di touchpad mini, halaman mini mengikuti (natural) atau
// berlawanan arah (tradisional). Kecepatan animasi ikut "Scroll speed". Hanya jalan saat Settings terbuka.
Rectangle {
    id: root
    property bool natural: true
    property real factor: 1

    readonly property bool running: visible && Sys.settingsOpen
    property real t: 0

    height: Theme.settingsDemoHeight + Theme.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    SequentialAnimation on t {
        running: root.running
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: Math.round(Theme.settingsDemoMs / Math.max(0.2, root.factor)); easing.type: Easing.InOutQuad }
        PauseAnimation { duration: Theme.settingsDemoPauseMs }
    }

    Row {
        x: Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space22

        // touchpad + jari
        Rectangle {
            id: pad
            width: Theme.settingsDemoPadW
            height: Theme.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tileFaint
            border.width: Theme.borderThin
            border.color: Theme.line
            Rectangle {
                readonly property real travel: pad.height - height - Theme.space16
                width: Theme.space22
                height: width
                radius: width / 2
                color: Theme.text
                opacity: Theme.opacityDim
                x: (pad.width - width) / 2
                y: Theme.space8 + travel * (1 - root.t)
            }
        }

        // halaman mini
        Rectangle {
            id: page
            width: Theme.settingsDemoPageW
            height: Theme.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tileFaint
            border.width: Theme.borderThin
            border.color: Theme.line
            clip: true

            Column {
                x: Theme.space12
                width: parent.width - Theme.space12 * 2
                spacing: Theme.space10
                // natural: halaman naik bersama jari. Tradisional: halaman turun.
                y: -Theme.settingsDemoTravel + (root.natural ? -1 : 1) * (root.t - 0.5) * Theme.settingsDemoTravel
                Repeater {
                    model: 12
                    delegate: Rectangle {
                        required property int index
                        width: parent.width * (index % 3 === 0 ? 0.9 : (index % 3 === 1 ? 0.65 : 0.8))
                        height: Theme.space8
                        radius: height / 2
                        color: index % 4 === 0 ? Theme.tileStrong : Theme.tileHover
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space4
            SettingsText { text: root.natural ? "Page follows your fingers" : "Page moves the opposite way"; font.weight: Font.DemiBold; font.pixelSize: Theme.fontBody }
            SettingsText { text: "Swipe up on the touchpad"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
            SettingsText { text: "Speed " + Number(root.factor).toFixed(2) + "×"; color: Theme.dim; font.pixelSize: Theme.fontCaption }
        }
    }
}
