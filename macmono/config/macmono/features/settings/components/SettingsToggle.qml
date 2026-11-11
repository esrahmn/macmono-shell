import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int settingsToggleWidth: 40
    readonly property int settingsToggleHeight: 24
    readonly property int settingsToggleKnob: 18
    readonly property int settingsToggleInset: 3
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: root.settingsToggleWidth
    implicitHeight: root.settingsToggleHeight
    radius: height / 2
    color: checked ? Theme.accent : Theme.tileHover
    Behavior on color { TweenColor { duration: Theme.durFast } }

    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    Keys.onSpacePressed: root.toggled(!root.checked)

    Rectangle {
        width: root.settingsToggleKnob
        height: root.settingsToggleKnob
        radius: height / 2
        y: (root.height - height) / 2
        x: root.checked ? root.width - width - root.settingsToggleInset : root.settingsToggleInset
        color: root.checked ? Theme.textOnAccent : Theme.text
        Behavior on x { Tween { duration: Theme.durFast } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.space2
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
