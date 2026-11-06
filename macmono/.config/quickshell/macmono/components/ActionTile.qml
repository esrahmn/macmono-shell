import QtQuick
import "../core"

// Tile kotak ikon-di-atas-label. Dipakai menu ⋯ (tools) dan menu power di Control Center,
// biar dua dropdown itu bentuknya sama persis.
Rectangle {
    id: root
    property string glyph: ""
    property string label: ""
    property bool hot: false          // putih (aktif / menunggu konfirmasi)
    signal clicked()

    implicitHeight: Theme.actionTileHeight
    radius: Theme.radius
    color: hot ? Theme.inverse : (area.containsMouse ? Theme.tileHover : Theme.tileFaint)
    Behavior on color { ColorAnimation { duration: Theme.animHover } }
    scale: area.pressed ? Theme.buttonPressedScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.animPress } }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: Theme.space7
        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.icon22; height: Theme.icon22
            name: root.glyph
            color: root.hot ? Theme.inverseText : Theme.text
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.label
            color: root.hot ? Theme.inverseText : Theme.textSoft
            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
            font.weight: root.hot ? Font.DemiBold : Font.Medium
            font.features: ({ "tnum": 1 })
        }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
