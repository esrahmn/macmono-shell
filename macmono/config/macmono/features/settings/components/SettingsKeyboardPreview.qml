import QtQuick
import "../../../core"

Rectangle {
    id: root

    readonly property int settingsKeycap: 40
    property int rate: 25
    property int delayMs: 600

    readonly property bool running: visible && Sys.settingsOpen
    readonly property int maxChars: 28
    readonly property real holdMs: delayMs + (maxChars - 1) / Math.max(1, rate) * 1000
    readonly property real totalMs: holdMs + SettingsMetrics.settingsDemoPauseMs * 2
    property real elapsed: 0
    readonly property bool held: elapsed < holdMs
    readonly property int chars: elapsed < delayMs ? 1 : Math.min(maxChars, 1 + Math.floor((elapsed - delayMs) / 1000 * Math.max(1, rate)))

    height: SettingsMetrics.settingsRowPadY * 2 + body.height
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    NumberAnimation on elapsed {
        running: root.running
        loops: Animation.Infinite
        from: 0
        to: root.totalMs
        duration: Math.max(1, root.totalMs)
        easing.type: Easing.Linear
    }

    Column {
        id: body
        x: SettingsMetrics.settingsRowPadX
        y: SettingsMetrics.settingsRowPadY
        width: parent.width - SettingsMetrics.settingsRowPadX * 2
        spacing: Theme.space12

        Row {
            width: parent.width
            spacing: Theme.space12

            Rectangle {
                width: root.settingsKeycap
                height: width
                radius: Theme.radiusControl * 2
                color: root.held ? Theme.tilePress : Theme.tile
                border.width: Theme.borderThin
                border.color: Theme.line
                scale: root.held ? 0.94 : 1
                SettingsText { anchors.centerIn: parent; text: "A"; font.weight: Theme.weightSemibold }
            }

            Rectangle {
                width: parent.width - root.settingsKeycap - Theme.space12
                height: root.settingsKeycap
                radius: Theme.radiusCard
                color: Theme.tile
                border.width: Theme.borderThin
                border.color: Theme.line
                clip: true
                SettingsText {
                    anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    text: "a".repeat(root.chars)
                    font.letterSpacing: Theme.space2
                }
            }
        }

        SettingsText {
            width: parent.width
            text: "Hold a key: the first letter appears, then after " + root.delayMs + " ms it repeats " + root.rate + " times per second."
            color: SettingsMetrics.settingsDescText
            font.pixelSize: Theme.fontSm
            wrapMode: Text.Wrap
        }
    }
}
