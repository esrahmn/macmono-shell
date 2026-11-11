import QtQuick
import "../../core"

// Class B (micro): the only NumberAnimation for hover, press, small fades, moves.
// Usage: Behavior on opacity { Tween {} }  |  Behavior on scale { Tween { duration: Theme.durFast } }
NumberAnimation {
    duration: Theme.durBase
    easing.type: Theme.easeOut
}
