import QtQuick
import "../../../core"

Rectangle {
    id: btn
    property string label
    property bool primary: false
    signal clicked()
    implicitWidth: btnText.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
    height: SettingsMetrics.settingsButtonHeight
    radius: Theme.radiusCard
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.text : (btnArea.containsMouse ? Theme.tileHover : Theme.tile)
    SettingsText {
        id: btnText
        anchors.centerIn: parent
        text: btn.label
        color: btn.primary ? Theme.panel : Theme.text
        font.pixelSize: Theme.fontSm
        font.weight: Theme.weightSemibold
    }
    MouseArea { id: btnArea; anchors.fill: parent; enabled: btn.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
