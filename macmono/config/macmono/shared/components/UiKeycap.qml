import QtQuick
import "../../core"

// Shared keycap (Cheatsheet, Settings > Shortcuts). Sized by the `cheatsheetKeycap*` tokens in Theme.
Rectangle {
    id: root

    property string label: ""
    property int fontSize: Theme.fontXs

    implicitWidth: Math.max(Theme.cheatsheetKeycapMinWidth, cap.implicitWidth + Theme.cheatsheetKeycapPadding)
    implicitHeight: Theme.cheatsheetKeycapHeight
    radius: Theme.radiusControl
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    Text {
        id: cap
        anchors.centerIn: parent
        text: root.label
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: root.fontSize
        font.weight: Theme.weightMedium
    }
}
