import QtQuick
import "../../core"

// One motion formula for wallpaper changes (used by WallLayer and the picker preview).
// t: linear 0..1 progress of the change. The incoming layer uses in*, the outgoing layer uses out*.
QtObject {
    property real t: 0
    property int dir: 1        // +1 = forward (enters from the right), -1 = backward
    property real span: 1920   // surface width, used for the slide distance

    readonly property real e: 1 - Math.pow(1 - t, 3)

    readonly property real inOpacity: Math.min(1, t * 1.8)
    readonly property real inScale: 1 + (1 - e) * Theme.wallZoomIn
    readonly property real inX: dir * (1 - e) * span * Theme.wallSlide

    readonly property real outScale: 1 + e * Theme.wallZoomOut
    readonly property real outX: -dir * e * span * Theme.wallSlide * 0.3

    // dim in the middle of the change (0 at start and end)
    readonly property real dip: Theme.wallDip * Math.sin(Math.PI * t)
}
