import QtQuick
import "../../../core"

// Chip pilihan (satu dari beberapa) untuk bagian Pengaturan buatan sendiri (Display, Weather).
Rectangle {
    id: chip
    property string label
    property bool on: false
    signal picked()
    implicitWidth: chipText.implicitWidth + Theme.settingsButtonPadX * 2
    height: Theme.settingsChipHeight
    radius: Theme.radiusCard
    color: on ? Theme.tileHover : (chipArea.containsMouse ? Theme.tileMid : Theme.tile)
    border.width: Theme.borderThin
    border.color: on ? Theme.lineStrong : Theme.cardStroke
    Behavior on color { ColorAnimation { duration: Theme.animHover } }
    SettingsText {
        id: chipText
        anchors.centerIn: parent
        text: chip.label
        color: chip.on ? Theme.text : Theme.textSoft
        font.pixelSize: Theme.fontBody
        font.weight: chip.on ? Font.DemiBold : Font.Normal
    }
    MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.picked() }
}
