import QtQuick
import "../../../core"

Rectangle {
    id: root

    readonly property int settingsDemoTravel: 40
    property bool natural: true
    property real factor: 1

    readonly property bool running: visible && Sys.settingsOpen
    property real t: 0

    height: SettingsMetrics.settingsDemoHeight + SettingsMetrics.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    SequentialAnimation on t {
        running: root.running
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: Math.round(SettingsMetrics.settingsDemoMs / Math.max(0.2, root.factor)); easing.type: Easing.InOutQuad }
        PauseAnimation { duration: SettingsMetrics.settingsDemoPauseMs }
    }

    Row {
        x: SettingsMetrics.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space24

        Rectangle {
            id: pad
            width: SettingsMetrics.settingsDemoPadW
            height: SettingsMetrics.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.line
            Rectangle {
                readonly property real travel: pad.height - height - Theme.space16
                width: Theme.space24
                height: width
                radius: width / 2
                color: Theme.text
                opacity: Theme.opacityDim
                x: (pad.width - width) / 2
                y: Theme.space8 + travel * (1 - root.t)
            }
        }

        Rectangle {
            id: page
            width: SettingsMetrics.settingsDemoPageW
            height: SettingsMetrics.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.line
            clip: true

            Column {
                x: Theme.space12
                width: parent.width - Theme.space12 * 2
                spacing: Theme.space12
                y: -root.settingsDemoTravel + (root.natural ? -1 : 1) * (root.t - 0.5) * root.settingsDemoTravel
                Repeater {
                    model: 12
                    delegate: Rectangle {
                        required property int index
                        width: parent.width * (index % 3 === 0 ? 0.9 : (index % 3 === 1 ? 0.65 : 0.8))
                        height: Theme.space8
                        radius: height / 2
                        color: index % 4 === 0 ? Theme.tilePress : Theme.tileHover
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space4
            SettingsText { text: root.natural ? "Page follows your fingers" : "Page moves the opposite way"; font.weight: Theme.weightSemibold; font.pixelSize: Theme.fontSm }
            SettingsText { text: "Swipe up on the touchpad"; color: SettingsMetrics.settingsDescText; font.pixelSize: Theme.fontSm }
            SettingsText { text: "Speed " + Number(root.factor).toFixed(2) + "×"; color: Theme.dim; font.pixelSize: Theme.fontXs }
        }
    }
}
