import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: box
    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    function clear() { input.text = ""; }
    function focusField() { input.forceActiveFocus(); }

    height: SettingsMetrics.settingsSearchHeight
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: input.activeFocus ? Theme.line : Theme.line
    Behavior on border.color { TweenColor { duration: Theme.durFast } }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: SettingsMetrics.settingsRowPadX; rightMargin: SettingsMetrics.settingsRowPadX }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
        selectionColor: Theme.tileHover
        selectedTextColor: Theme.text
        clip: true
        onAccepted: box.accepted()
        Keys.onEscapePressed: (event) => {
            if (text !== "") { text = ""; event.accepted = true; }
            else event.accepted = false;
        }

        SettingsText {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: !input.text
            text: box.placeholder
            color: Theme.faint
        }
    }
}
