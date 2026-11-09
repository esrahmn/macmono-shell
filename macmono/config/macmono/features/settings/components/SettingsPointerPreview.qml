import QtQuick
import QtQuick.Shapes
import "../../../core"

Rectangle {
    id: root
    property real sens: 0

    readonly property bool running: visible && Sys.settingsOpen
    property real t: 0
    readonly property real mult: Math.pow(3, sens)

    height: Theme.settingsDemoHeight + Theme.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    SequentialAnimation on t {
        running: root.running
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: Theme.settingsDemoMs; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: Theme.settingsDemoPauseMs }
    }

    Row {
        x: Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space22

        Rectangle {
            id: pad
            width: Theme.settingsDemoPadW
            height: Theme.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tileFaint
            border.width: Theme.borderThin
            border.color: Theme.line
            Rectangle {
                width: Theme.space22
                height: width
                radius: width / 2
                color: Theme.text
                opacity: Theme.opacityDim
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.space16 + (pad.width - width - Theme.space16 * 2) * root.t
            }
        }

        Rectangle {
            id: scr
            width: Theme.settingsDemoPageW
            height: Theme.settingsDemoHeight
            radius: Theme.radiusCard
            color: Theme.tileFaint
            border.width: Theme.borderThin
            border.color: Theme.line
            clip: true

            Shape {
                id: cursor
                readonly property real startX: Theme.space16
                readonly property real maxX: scr.width - Theme.space22
                x: startX + Math.min(maxX - startX, (scr.width * 0.3) * root.mult * root.t)
                y: (scr.height - height) / 2
                width: Theme.space12
                height: Theme.space16
                ShapePath {
                    fillColor: Theme.text
                    strokeColor: Theme.panel
                    strokeWidth: Theme.borderThin
                    PathPolyline { path: [Qt.point(0, 0), Qt.point(0, 15), Qt.point(4, 11), Qt.point(8, 18), Qt.point(11, 16), Qt.point(7, 10), Qt.point(12, 10), Qt.point(0, 0)] }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space4
            SettingsText { text: root.sens === 0 ? "Normal speed" : (root.sens > 0 ? "Faster pointer" : "Slower pointer"); font.weight: Font.DemiBold; font.pixelSize: Theme.fontBody }
            SettingsText { text: "Same hand movement, different distance"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
        }
    }
}
