import QtQuick
import "../../../core"

Column {
    id: root
    property int lockMin: 5
    property int offMin: 10
    property int suspendMin: 15
    property var warnLevels: [5, 10, 20]
    property int criticalLevel: 10

    spacing: Theme.settingsGroupSpacing

    component Caption: SettingsText {
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }

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

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: "SLEEP TIMELINE" }

        Rectangle {
            width: parent.width
            height: tlBody.height + Theme.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.cardStroke

            Item {
                id: tlBody
                x: Theme.settingsRowPadX
                y: Theme.settingsRowPadY
                width: parent.width - Theme.settingsRowPadX * 2
                height: root.events.length === 0 ? emptyText.height
                        : Theme.settingsMarkSize + Theme.space4 + (root.events.length > 1 ? Theme.fontBody * 2 + Theme.space6 : Theme.fontBody) + Theme.space4

                SettingsText {
                    id: emptyText
                    visible: root.events.length === 0
                    width: parent.width
                    text: "Nothing happens automatically. The screen stays on and the computer never sleeps."
                    color: Theme.settingsDescText
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.Wrap
                }

                Item {
                    visible: root.events.length > 0
                    anchors.fill: parent
                    readonly property real trackW: width - Theme.settingsMarkSize

                    Rectangle {
                        x: Theme.settingsMarkSize / 2
                        y: Theme.settingsMarkSize / 2 - height / 2
                        width: parent.trackW
                        height: Theme.settingsSliderTrack
                        radius: height / 2
                        color: Theme.tileHover
                    }
                    Rectangle { x: 0; y: 0; width: Theme.settingsMarkSize; height: width; radius: width / 2; color: Theme.dim }
                    SettingsText { x: 0; y: Theme.settingsMarkSize + Theme.space4; text: "Idle"; color: Theme.dim; font.pixelSize: Theme.fontCaption }

                    Repeater {
                        model: root.events
                        delegate: Item {
                            id: ev
                            required property var modelData
                            required property int index
                            readonly property real cx: Theme.settingsMarkSize / 2 + parent.trackW * (modelData.m / root.axisMax)
                            Rectangle {
                                x: ev.cx - width / 2
                                y: 0
                                width: Theme.settingsMarkSize
                                height: width
                                radius: width / 2
                                color: Theme.text
                            }
                            SettingsText {
                                x: Math.max(0, Math.min(ev.parent.width - width, ev.cx - width / 2))
                                y: Theme.settingsMarkSize + Theme.space4 + (ev.index % 2) * (Theme.fontBody + Theme.space6)
                                text: ev.modelData.label + " · " + ev.modelData.m + " min"
                                font.pixelSize: Theme.fontBody
                            }
                        }
                    }
                }
            }
        }
    }

    readonly property var levels: {
        const seen = {};
        const out = [];
        for (const v of (warnLevels || [])) {
            const n = Math.round(Number(v));
            if (n > 0 && n <= 100 && !seen[n]) { seen[n] = true; out.push(n); }
        }
        out.sort((a, b) => a - b);
        return out;
    }

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: "BATTERY ALERT LEVELS" }

        Rectangle {
            width: parent.width
            height: alBody.height + Theme.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.cardStroke

            Item {
                id: alBody
                x: Theme.settingsRowPadX
                y: Theme.settingsRowPadY
                width: parent.width - Theme.settingsRowPadX * 2
                height: Theme.settingsBatBar + Theme.space8 + Theme.fontBody + Theme.space8 + Theme.fontCaption

                Rectangle {
                    id: bar
                    width: parent.width
                    height: Theme.settingsBatBar
                    radius: height / 2
                    color: Theme.tileHover
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, root.criticalLevel)) / 100
                        height: parent.height
                        radius: height / 2
                        color: Theme.text
                    }
                }
                Repeater {
                    model: root.levels
                    delegate: Item {
                        id: tick
                        required property int modelData
                        readonly property real cx: bar.width * modelData / 100
                        Rectangle { x: tick.cx - width / 2; y: -Theme.space3; width: Theme.borderStrong; height: bar.height + Theme.space3 * 2; color: Theme.dim }
                        SettingsText {
                            x: Math.max(0, Math.min(alBody.width - width, tick.cx - width / 2))
                            y: bar.height + Theme.space8
                            text: tick.modelData + "%"
                            font.pixelSize: Theme.fontBody
                        }
                    }
                }
                SettingsText {
                    y: bar.height + Theme.space8 + Theme.fontBody + Theme.space8
                    text: "Solid area = urgent warnings (" + root.criticalLevel + "% and below). Lines = alert levels."
                    color: Theme.settingsDescText
                    font.pixelSize: Theme.fontCaption
                }
            }
        }
    }
}
