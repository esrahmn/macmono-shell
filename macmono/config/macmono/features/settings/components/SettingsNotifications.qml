import QtQuick
import "../../../core"

Column {
    id: root
    spacing: 0

    function hhmm(minutes) {
        const m = Math.max(0, Math.min(24 * 60 - 1, Math.round(Number(minutes) || 0)));
        return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
    }
    function setStart(v) { SettingsStore.apply({ dndStartMin: v }, []); }
    function setEnd(v) { SettingsStore.apply({ dndEndMin: v }, []); }

    readonly property var recentApps: {
        const seen = {};
        const out = [];
        for (const n of Sys.notifHistory) {
            const name = String(n.app ?? "").trim();
            const key = name.toLowerCase();
            if (name === "" || seen[key] || Sys.notifIsMuted(name)) continue;
            seen[key] = true;
            out.push(name);
            if (out.length >= 6) break;
        }
        return out;
    }
    function mute(name) { SettingsStore.apply({ notifMutedApps: (Settings.notifMutedApps ?? []).concat([name]) }, []); }

    // Fixed presets, so the choice stays predictable instead of a free-form number.
    readonly property var notifDurations: [
        { ms: 2000, label: "2s" },
        { ms: 3000, label: "3s" },
        { ms: 5000, label: "5s" },
        { ms: 10000, label: "10s" }
    ]

    component SectionLabel: SettingsText {
        property bool first: false
        topPadding: first ? 0 : SettingsMetrics.settingsGroupSpacing
        bottomPadding: Theme.space8
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
        leftPadding: SettingsMetrics.settingsRowPadX
    }


    SettingsNotifPreview {
        width: root.width
        dnd: Sys.dnd
    }

    SectionLabel { first: false; text: "NOTIFICATION CARDS" }

    SettingsRow {
        width: root.width
        title: "Hide after"
        Row {
            spacing: Theme.space8
            Repeater {
                model: root.notifDurations
                delegate: SettingsChoice {
                    required property var modelData
                    label: modelData.label
                    on: Settings.notifDefaultTimeoutMs === modelData.ms
                    onPicked: SettingsStore.apply({ notifDefaultTimeoutMs: modelData.ms }, [])
                }
            }
        }
    }

    SectionLabel { first: false; text: "DO NOT DISTURB" }

    SettingsRow {
        width: root.width
        title: "Do Not Disturb"
        valueText: Sys.dnd ? "On" : ""
        SettingsToggle {
            checked: Sys.dnd
            onToggled: (v) => { Sys.dnd = v; }
        }
    }


    SettingsRow {
        width: root.width
        separator: true
        title: "Schedule"
        valueText: Settings.dndScheduleEnabled
            ? root.hhmm(Settings.dndStartMin) + " – " + root.hhmm(Settings.dndEndMin)
            : ""
        SettingsToggle {
            checked: Settings.dndScheduleEnabled
            onToggled: (v) => SettingsStore.apply({ dndScheduleEnabled: v }, [])
        }
    }

    Item {
        width: root.width
        height: dndTimeline.height + Theme.space12 * 2
        SettingsDndTimeline {
            id: dndTimeline
            y: Theme.space12
            width: parent.width
            startMin: Settings.dndStartMin
            endMin: Settings.dndEndMin
            scheduled: Settings.dndScheduleEnabled
        }
    }

    SettingsRow {
        visible: Settings.dndScheduleEnabled
        width: root.width
        separator: true
        title: "Turn on at"
        Row {
            spacing: Theme.space8
            SettingsStepper {
                value: Math.floor(Settings.dndStartMin / 60)
                minValue: 0; maxValue: 23; step: 1; pad: 2
                onMoved: (v) => root.setStart(v * 60 + (Settings.dndStartMin % 60))
            }
            SettingsText {
                height: SettingsMetrics.settingsStepperHeight
                verticalAlignment: Text.AlignVCenter
                text: ":"
                color: Theme.text
            }
            SettingsStepper {
                value: Settings.dndStartMin % 60
                minValue: 0; maxValue: 55; step: 5; pad: 2
                onMoved: (v) => root.setStart(Math.floor(Settings.dndStartMin / 60) * 60 + v)
            }
        }
    }

    SettingsRow {
        visible: Settings.dndScheduleEnabled
        width: root.width
        separator: true
        title: "Turn off at"
        Row {
            spacing: Theme.space8
            SettingsStepper {
                value: Math.floor(Settings.dndEndMin / 60)
                minValue: 0; maxValue: 23; step: 1; pad: 2
                onMoved: (v) => root.setEnd(v * 60 + (Settings.dndEndMin % 60))
            }
            SettingsText {
                height: SettingsMetrics.settingsStepperHeight
                verticalAlignment: Text.AlignVCenter
                text: ":"
                color: Theme.text
            }
            SettingsStepper {
                value: Settings.dndEndMin % 60
                minValue: 0; maxValue: 55; step: 5; pad: 2
                onMoved: (v) => root.setEnd(Math.floor(Settings.dndEndMin / 60) * 60 + v)
            }
        }
    }

    Item { width: 1; height: SettingsMetrics.settingsGroupSpacing }

    SettingsRow {
        width: root.width
        stacked: true
        title: "Muted applications"
        SettingsChips {
            width: parent.width
            model: Settings.notifMutedApps
            onEdited: (list) => SettingsStore.apply({ notifMutedApps: list }, [])
        }
    }

    Column {
        visible: root.recentApps.length > 0
        x: SettingsMetrics.settingsRowPadX
        width: root.width - SettingsMetrics.settingsRowPadX * 2
        spacing: Theme.space8
        topPadding: Theme.space4
        SettingsText { text: "Recently notified. Tap to mute."; color: Theme.dim; font.pixelSize: Theme.fontXs }
        Flow {
            width: parent.width
            spacing: Theme.space8
            Repeater {
                model: root.recentApps
                delegate: SettingsChoice {
                    required property string modelData
                    label: "+ " + modelData
                    on: false
                    onPicked: root.mute(modelData)
                }
            }
        }
    }

    SettingsText {
        width: root.width
        topPadding: Theme.space8
        leftPadding: SettingsMetrics.settingsRowPadX
        rightPadding: SettingsMetrics.settingsRowPadX
        wrapMode: Text.WordWrap
        text: "Type an app name exactly as it appears on its notifications. Notifications from muted apps are dismissed right away."
        color: Theme.dim
        font.pixelSize: Theme.fontSm
    }
}
