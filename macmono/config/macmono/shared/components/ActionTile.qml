import QtQuick
import "../../core"
import "."

Rectangle {
    id: root

    readonly property int actionTileHeight: 78
    property string glyph: ""
    property string label: ""
    property bool hot: false
    signal clicked()

    implicitHeight: root.actionTileHeight
    radius: Theme.radiusCard
    color: hot ? Theme.accent : (area.pressed ? Theme.tilePress : area.containsMouse ? Theme.tileHover : Theme.tile)
    Behavior on color { TweenColor { duration: Theme.durFast } }
    scale: area.pressed ? Theme.pressScale : 1
    Behavior on scale { Tween { duration: Theme.durFast } }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: Theme.space8
        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.iconXl; height: Theme.iconXl
            name: root.glyph
            color: root.hot ? Theme.textOnAccent : Theme.text
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.label
            color: root.hot ? Theme.textOnAccent : Theme.text
            font.family: Theme.font; font.pixelSize: Theme.fontMd
            font.weight: root.hot ? Theme.weightSemibold : Theme.weightMedium
            font.features: ({ "tnum": 1 })
        }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
