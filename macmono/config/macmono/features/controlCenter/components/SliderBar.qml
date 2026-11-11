import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int sliderHeight: 40
    readonly property real sliderWheelStep: 0.05
    readonly property real sliderFillAlpha: 0.32
    property real value: 0
    property string icon: ""
    signal moved(real v)

    implicitHeight: root.sliderHeight
    radius: height / 2
    color: Theme.tile
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
        radius: parent.radius
        color: Qt.alpha(Theme.text, root.sliderFillAlpha)
        Behavior on width { enabled: !area.pressed; Tween { duration: Theme.durFast } }
    }

    Glyph {
        anchors.verticalCenter: parent.verticalCenter
        x: (root.height - height) / 2
        width: Theme.iconMd; height: Theme.iconMd
        name: root.icon
        color: Theme.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        function setFrom(mx) { root.moved(Math.max(0, Math.min(1, mx / width))); }
        onPressed: (e) => setFrom(e.x)
        onPositionChanged: (e) => { if (pressed) setFrom(e.x); }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (e) => root.moved(Math.max(0, Math.min(1,
            root.value + e.angleDelta.y / 120 * root.sliderWheelStep)))
    }
}
