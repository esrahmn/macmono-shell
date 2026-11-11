import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: root

    readonly property int settingsChipRemove: 18
    readonly property int settingsChipInputWidth: 150
    readonly property int settingsChipsMinWidth: 320
    property var model: []
    property bool mono: false
    property bool numeric: false
    signal edited(var list)

    implicitWidth: root.settingsChipsMinWidth
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
        spacing: Theme.space8

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: chip
                required property var modelData
                required property int index

                height: SettingsMetrics.settingsChipHeight
                width: chipLabel.implicitWidth + Theme.space12 + root.settingsChipRemove + Theme.space8
                radius: Theme.radiusControl
                color: Theme.tile

                SettingsText {
                    id: chipLabel
                    x: Theme.space12
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(chip.modelData)
                    font.family: root.mono ? Theme.fontMono : Theme.font
                    font.pixelSize: Theme.fontMd
                }

                Rectangle {
                    width: root.settingsChipRemove
                    height: root.settingsChipRemove
                    radius: height / 2
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space4
                    anchors.verticalCenter: parent.verticalCenter
                    color: removeArea.containsMouse ? Theme.tilePress : Theme.transparent

                    Glyph {
                        anchors.centerIn: parent
                        name: "close"
                        color: Theme.dim
                        width: Theme.iconSm
                        height: Theme.iconSm
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
            width: root.settingsChipInputWidth
            height: SettingsMetrics.settingsChipHeight
            radius: Theme.radiusControl
            color: Theme.scrim
            border.width: Theme.borderThin
            border.color: input.activeFocus ? Theme.lineFocus : Theme.line

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: Theme.space12
                anchors.rightMargin: Theme.space12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.tileHover
                font.family: root.mono ? Theme.fontMono : Theme.font
                font.pixelSize: Theme.fontMd
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
                anchors.leftMargin: Theme.space12
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: "+ add"
                color: Theme.faint
                font.pixelSize: Theme.fontMd
            }
        }
    }
}
