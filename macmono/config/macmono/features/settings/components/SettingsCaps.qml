import QtQuick
import "../../../core"

SettingsText {
    property bool first: false
    topPadding: first ? 0 : SettingsMetrics.settingsGroupSpacing
    bottomPadding: Theme.space8
    leftPadding: SettingsMetrics.settingsRowPadX
    color: Theme.dim
    font.pixelSize: Theme.fontXs
    font.weight: Theme.weightSemibold
    font.letterSpacing: Theme.trackCaps
}
