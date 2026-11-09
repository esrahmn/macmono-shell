import QtQuick
import "../../../core"

Rectangle {
    id: box
    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    function clear() { input.text = ""; }
    function focusField() { input.forceActiveFocus(); }

    height: Theme.settingsSearchHeight
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: input.activeFocus ? Theme.lineStrong : Theme.cardStroke
    Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: Theme.settingsRowPadX; rightMargin: Theme.settingsRowPadX }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontBodyLg
        selectionColor: Theme.selection
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
            color: Theme.muted
        }
    }
}
