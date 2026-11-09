import QtQuick
import "../../../core"

Rectangle {
    id: root
    property int startMin: 1320
    property int endMin: 420
    property bool scheduled: false

    readonly property int dayMin: 1440
    readonly property int nowMin: Sys.now.getHours() * 60 + Sys.now.getMinutes()
    readonly property bool hasWindow: startMin !== endMin
    readonly property int lengthMin: hasWindow ? (endMin - startMin + dayMin) % dayMin : 0
    readonly property bool insideNow: hasWindow && (startMin < endMin ? (nowMin >= startMin && nowMin < endMin)
                                                                      : (nowMin >= startMin || nowMin < endMin))
    readonly property var segments: !hasWindow ? [] : (startMin < endMin ? [[startMin, endMin]] : [[startMin, dayMin], [0, endMin]])

    function hhmm(m) { return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0"); }

    height: body.height + Theme.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    Column {
        id: body
        x: Theme.settingsRowPadX
        y: Theme.settingsRowPadY
        width: parent.width - Theme.settingsRowPadX * 2
        spacing: Theme.space8

        SettingsText {
            width: parent.width
            text: !root.scheduled ? "Schedule is off. This is how it would look."
                : !root.hasWindow ? "Start and end are the same, so nothing is silenced."
                : "Quiet from " + root.hhmm(root.startMin) + " to " + root.hhmm(root.endMin)
                  + " (" + Math.floor(root.lengthMin / 60) + " h" + (root.lengthMin % 60 ? " " + root.lengthMin % 60 + " min" : "") + ")"
                  + (root.insideNow ? ", quiet now" : "")
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fontBody
        }

        Item {
            id: bar
            width: parent.width
            height: Theme.settingsBatBar + Theme.space8

            Rectangle {
                y: Theme.space4
                width: parent.width
                height: Theme.settingsBatBar
                radius: height / 2
                color: Theme.tileHover
            }
            Repeater {
                model: root.segments
                delegate: Rectangle {
                    required property var modelData
                    x: bar.width * modelData[0] / root.dayMin
                    y: Theme.space4
                    width: Math.max(Theme.settingsBatBar, bar.width * (modelData[1] - modelData[0]) / root.dayMin)
                    height: Theme.settingsBatBar
                    radius: height / 2
                    color: Theme.text
                    opacity: root.scheduled ? 1 : 0.3
                }
            }
            Rectangle {
                x: Math.max(0, Math.min(bar.width - width, bar.width * root.nowMin / root.dayMin - width / 2))
                width: Theme.borderStrong
                height: bar.height
                radius: width / 2
                color: Theme.textSoft
            }
        }

        Item {
            width: parent.width
            height: Theme.fontCaption + Theme.space4
            Repeater {
                model: [0, 6, 12, 18, 24]
                delegate: SettingsText {
                    required property int modelData
                    text: modelData
                    color: Theme.dim
                    font.pixelSize: Theme.fontCaption
                    x: Math.max(0, Math.min(parent.width - width, parent.width * modelData / 24 - width / 2))
                }
            }
        }
    }
}
