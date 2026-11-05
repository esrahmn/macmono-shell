import QtQuick
import QtQuick.Layouts
import "../core"
import "../components"

RowLayout {
    id: batteryRow
    Layout.fillWidth: true
    visible: Sys.batAvailable
    Layout.leftMargin: Theme.space6
    Layout.rightMargin: Theme.space2
    spacing: Theme.space10

    BatteryIcon {}
    // "87% · 2h 10m left": bagian depan putih, bagian setelah " · " redup (Theme.dim)
    Text {
        id: batteryMain
        readonly property string full: Sys.batText()
        readonly property int split: full.indexOf(" · ")
        Layout.fillWidth: split < 0
        elide: Text.ElideRight
        text: split < 0 ? full : full.slice(0, split)
        color: Theme.text
        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
    }
    Text {
        Layout.fillWidth: true
        visible: batteryMain.split >= 0
        elide: Text.ElideRight
        text: batteryMain.split >= 0 ? batteryMain.full.slice(batteryMain.split) : ""
        color: Theme.dim
        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
    }
}
