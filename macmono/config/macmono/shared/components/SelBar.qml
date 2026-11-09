import QtQuick
import "../../core"

Rectangle {
    property bool active: false
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    width: 2
    radius: 0
    color: Theme.text
    opacity: active ? 1 : 0
}
