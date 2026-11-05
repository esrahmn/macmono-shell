import QtQuick
import "../core"

// Slider ala macOS: batang tebal, isian putih, ikon di kiri
Rectangle {
    id: root
    property real value: 0          // 0..1
    property string icon: ""
    signal moved(real v)

    implicitHeight: 38
    radius: height / 2
    color: Theme.tile
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
        radius: parent.radius
        color: Theme.inverse
        Behavior on width { enabled: !area.pressed; NumberAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
    }

    Glyph {
        anchors.verticalCenter: parent.verticalCenter
        x: 9
        width: 16; height: 16
        name: root.icon
        color: Theme.inverseText
    }

    MouseArea {
        id: area
        anchors.fill: parent
        function setFrom(mx) { root.moved(Math.max(0, Math.min(1, mx / width))); }
        onPressed: (e) => setFrom(e.x)
        onPositionChanged: (e) => { if (pressed) setFrom(e.x); }
    }
}
