import QtQuick
import "../../../core"

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: Theme.settingsToggleWidth
    implicitHeight: Theme.settingsToggleHeight
    radius: height / 2
    color: checked ? Theme.inverse : Theme.tileHover
    Behavior on color { ColorAnimation { duration: Theme.animHover } }

    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    Keys.onSpacePressed: root.toggled(!root.checked)

    Rectangle {
        width: Theme.settingsToggleKnob
        height: Theme.settingsToggleKnob
        radius: height / 2
        y: (root.height - height) / 2
        x: root.checked ? root.width - width - Theme.settingsToggleInset : Theme.settingsToggleInset
        color: root.checked ? Theme.inverseText : Theme.text
        Behavior on x { NumberAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.space3
        radius: height / 2
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.lineFocus
        visible: root.activeFocus
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
