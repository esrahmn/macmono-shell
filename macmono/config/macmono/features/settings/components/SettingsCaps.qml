import QtQuick
import "../../../core"

SettingsText {
    property bool first: false
    topPadding: first ? 0 : Theme.settingsGroupSpacing
    bottomPadding: Theme.space8
    leftPadding: Theme.settingsRowPadX
    color: Theme.labelCapsText
    font.pixelSize: Theme.labelCapsSize
    font.weight: Font.DemiBold
    font.letterSpacing: Theme.labelCapsTracking
}
