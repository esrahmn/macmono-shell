import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: chip
    property string label
    property bool on: false
    signal picked()
    implicitWidth: chipText.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
    height: SettingsMetrics.settingsChipHeight
    radius: Theme.radiusCard
    color: on ? Theme.tileHover : (chipArea.containsMouse ? Theme.tile : Theme.tile)
    border.width: Theme.borderThin
    border.color: on ? Theme.line : Theme.line
    Behavior on color { TweenColor { duration: Theme.durFast } }
    SettingsText {
        id: chipText
        anchors.centerIn: parent
        text: chip.label
        color: chip.on ? Theme.text : Theme.text
        font.pixelSize: Theme.fontSm
        font.weight: chip.on ? Theme.weightSemibold : Theme.weightRegular
    }
    MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.picked() }
}
