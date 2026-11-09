import QtQuick
import "../../../core"

// Label grup KAPITAL renggang (token labelCaps*). Satu komponen untuk halaman Settings buatan sendiri,
// supaya tidak ada salinan baru di tiap file.
// Jarak atas = settingsGroupSpacing (kecuali `first`), jarak ke baris di bawahnya = space8.
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
