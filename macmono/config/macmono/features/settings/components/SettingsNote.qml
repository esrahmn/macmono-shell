import QtQuick
import "../../../core"

// Keterangan satu-dua baris di bawah label grup (akibat sebuah aksi, bukan petunjuk tombol).
// Pasang `width` di tempat pemakaian supaya teks bisa membungkus.
SettingsText {
    bottomPadding: Theme.space4
    leftPadding: Theme.settingsRowPadX
    rightPadding: Theme.settingsRowPadX
    wrapMode: Text.WordWrap
    color: Theme.dim
    font.pixelSize: Theme.fontBody
}
