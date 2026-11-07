import QtQuick
import "../../../core"
import "../../../shared/components"

// Daftar nilai yang bisa ditambah/dihapus (pinned apps, folder wallpaper, level baterai).
Item {
    id: root
    property var model: []
    property bool mono: false
    property bool numeric: false
    signal edited(var list)

    implicitWidth: Theme.settingsChipsMinWidth
    implicitHeight: flow.implicitHeight

    function same(a, b) { return String(a) === String(b); }

    function commit(raw) {
        const t = raw.trim();
        if (t === "") return;
        let value = t;
        if (numeric) {
            value = Number(t);
            if (!isFinite(value) || value < 0) return;
        }
        for (const x of model) if (same(x, value)) return;
        const next = model.concat([value]);
        if (numeric) next.sort((a, b) => a - b);
        edited(next);
    }

    function removeAt(i) {
        const next = model.slice();
        next.splice(i, 1);
        edited(next);
    }

    Flow {
        id: flow
        width: root.width
        spacing: Theme.space6

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: chip
                required property var modelData
                required property int index

                height: Theme.settingsChipHeight
                width: chipLabel.implicitWidth + Theme.space10 + Theme.settingsChipRemove + Theme.space6
                radius: Theme.radiusXs
                color: Theme.tileMid

                SettingsText {
                    id: chipLabel
                    x: Theme.space10
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(chip.modelData)
                    font.family: root.mono ? Theme.fontMono : Theme.font
                    font.pixelSize: Theme.fontBodyLg
                }

                Rectangle {
                    width: Theme.settingsChipRemove
                    height: Theme.settingsChipRemove
                    radius: height / 2
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space4
                    anchors.verticalCenter: parent.verticalCenter
                    color: removeArea.containsMouse ? Theme.tileStrong : Theme.transparent

                    Glyph {
                        anchors.centerIn: parent
                        name: "close"
                        color: Theme.dim
                        width: Theme.icon11
                        height: Theme.icon11
                    }

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeAt(chip.index)
                    }
                }
            }
        }

        Rectangle {
            width: Theme.settingsChipInputWidth
            height: Theme.settingsChipHeight
            radius: Theme.radiusXs
            color: Theme.inset
            border.width: Theme.borderThin
            border.color: input.activeFocus ? Theme.lineFocus : Theme.line

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: Theme.space10
                anchors.rightMargin: Theme.space10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.selection
                font.family: root.mono ? Theme.fontMono : Theme.font
                font.pixelSize: Theme.fontBodyLg
                clip: true
                selectByMouse: true
                inputMethodHints: root.numeric ? Qt.ImhDigitsOnly : Qt.ImhNoPredictiveText
                onAccepted: { root.commit(text); text = ""; }
                Keys.onEscapePressed: event => {
                    if (text !== "") { text = ""; event.accepted = true; }
                    else { focus = false; }
                }
            }

            SettingsText {
                anchors.left: parent.left
                anchors.leftMargin: Theme.space10
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: "+ add"
                color: Theme.muted
                font.pixelSize: Theme.fontBodyLg
            }
        }
    }
}
