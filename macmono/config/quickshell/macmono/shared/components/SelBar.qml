import QtQuick
import "../../core"

// Penanda baris terpilih gaya editorial: bilah putih 2 px di tepi kiri.
// Dipakai bersama sorotan `Theme.tileMid` (sama seperti baris Settings). Pasang sebagai anak baris.
Rectangle {
    property bool active: false
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    width: 2
    radius: 0
    color: Theme.text
    opacity: active ? 1 : 0
}
