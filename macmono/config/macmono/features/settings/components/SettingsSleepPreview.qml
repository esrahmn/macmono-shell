import QtQuick
import "../../../core"

Rectangle {
    id: root
    property int lockMin: 5
    property int offMin: 10
    property int suspendMin: 15

    readonly property var events: {
        const all = [
            { label: "Lock", m: lockMin },
            { label: "Screen off", m: offMin },
            { label: "Sleep", m: suspendMin }
        ].filter(e => e.m > 0);
        all.sort((a, b) => a.m - b.m);
        return all;
    }
    readonly property real axisMax: Math.max(15, events.length ? events[events.length - 1].m : 0)

    height: tlBody.height + SettingsMetrics.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    Item {
        id: tlBody
        x: SettingsMetrics.settingsRowPadX
        y: SettingsMetrics.settingsRowPadY
        width: root.width - SettingsMetrics.settingsRowPadX * 2
        height: root.events.length === 0 ? emptyText.height
                : SettingsMetrics.settingsMarkSize + Theme.space4 + (root.events.length > 1 ? Theme.fontSm * 2 + Theme.space8 : Theme.fontSm) + Theme.space4

        SettingsText {
            id: emptyText
            visible: root.events.length === 0
            width: parent.width
            text: "Nothing happens automatically. The screen stays on and the computer never sleeps."
            color: SettingsMetrics.settingsDescText
            font.pixelSize: Theme.fontSm
            wrapMode: Text.Wrap
        }

        Item {
            visible: root.events.length > 0
            anchors.fill: parent
            readonly property real trackW: width - SettingsMetrics.settingsMarkSize

            Rectangle {
                x: SettingsMetrics.settingsMarkSize / 2
                y: SettingsMetrics.settingsMarkSize / 2 - height / 2
                width: parent.trackW
                height: SettingsMetrics.settingsSliderTrack
                radius: height / 2
                color: Theme.tileHover
            }
            Rectangle { x: 0; y: 0; width: SettingsMetrics.settingsMarkSize; height: width; radius: width / 2; color: Theme.dim }
            SettingsText { x: 0; y: SettingsMetrics.settingsMarkSize + Theme.space4; text: "Idle"; color: Theme.dim; font.pixelSize: Theme.fontXs }

            Repeater {
                model: root.events
                delegate: Item {
                    id: ev
                    required property var modelData
                    required property int index
                    readonly property real cx: SettingsMetrics.settingsMarkSize / 2 + parent.trackW * (modelData.m / root.axisMax)
                    Rectangle {
                        x: ev.cx - width / 2
                        y: 0
                        width: SettingsMetrics.settingsMarkSize
                        height: width
                        radius: width / 2
                        color: Theme.text
                    }
                    SettingsText {
                        x: Math.max(0, Math.min(ev.parent.width - width, ev.cx - width / 2))
                        y: SettingsMetrics.settingsMarkSize + Theme.space4 + (ev.index % 2) * (Theme.fontSm + Theme.space8)
                        text: ev.modelData.label + " · " + ev.modelData.m + " min"
                        font.pixelSize: Theme.fontSm
                    }
                }
            }
        }
    }
}
