import QtQuick
import "../../core"

// Standard frame for every floating panel (DESIGN.md 3.1, 5.2, 6.1): glass, hairline border, drawer motion.
// Usage: Panel { travel: win.travel; progress: win.anim; <content> }
// Children go into an inner area inset by `padding` and fade with `progress`.
Rectangle {
    id: root

    default property alias content: slot.data
    readonly property Item contentItem: slot

    property real padding: Theme.space16
    // From Reveal.travel (may exceed 1 while bouncing) and Reveal.progress (clamped 0..1).
    property real travel: 1
    property real progress: 1
    // Slide distance when closed. Default: drawer from the top edge. Override if the panel does not slide from its own top edge.
    property real slideDistance: root.height + Theme.drawerGap

    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: Theme.borderThin
    border.color: Theme.line
    transform: Translate { y: Theme.drawerOffset(root.slideDistance, root.travel) }

    // Click catcher: clicks inside the panel do not fall through to the dismiss layer behind it.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Item {
        id: slot
        anchors { fill: parent; margins: root.padding }
        opacity: root.progress
    }
}
