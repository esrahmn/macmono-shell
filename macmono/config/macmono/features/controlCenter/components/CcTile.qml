import QtQuick
import "../../../core"
import "../../../shared/components"

// Control Center tile: neutral glass, active = dark gray fill (no bright accent).
Rectangle {
    id: root

    property bool active: false
    readonly property bool pressed: area.pressed
    readonly property bool hovered: hover.hovered
    signal clicked()

    radius: Theme.radiusCard
    scale: area.pressed ? Theme.pressScale : 1
    color: active || area.pressed ? Theme.tilePress : hover.hovered ? Theme.tileHover : Theme.tile
    Behavior on color { TweenColor { duration: Theme.durFast } }
    Behavior on scale { Tween { duration: Theme.durFast } }

    // HoverHandler is passive, so the hover state survives child mouse areas (e.g. the Wi-Fi icon button).
    HoverHandler { id: hover }

    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
