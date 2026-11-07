import QtQuick
import "../../../core"

// Teks dasar aplikasi Pengaturan: font + warna + ukuran standar macmono.
// PreferVerticalHinting: huruf tetap tajam di layar 1080p, tapi jarak horizontal tidak dibulatkan per
// piksel (hinting penuh bikin spasi antar huruf Inter loncat-loncat). Properti ini hanya berlaku
// bersama NativeRendering (Qt 6.12, Text.font.hintingPreference). Kalau mau coba tampilan lain,
// ganti renderType ke Text.QtRendering di SINI saja; semua teks Pengaturan ikut.
Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontBodyLg
    font.hintingPreference: Font.PreferVerticalHinting
    renderType: Text.NativeRendering
}
