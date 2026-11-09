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

    property bool confirmClear: false
    Timer { id: confirmTimer; interval: Theme.settingsConfirmMs; onTriggered: root.confirmClear = false }

    component SectionLabel: SettingsText {
        property bool first: false
        topPadding: first ? 0 : Theme.settingsGroupSpacing
        bottomPadding: Theme.space8
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }


    SettingsNotifPreview {
        width: root.width
        dnd: Sys.dnd
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
            spacing: Theme.space6
            SettingsStepper {
                value: Math.floor(Settings.dndStartMin / 60)
                minValue: 0; maxValue: 23; step: 1; pad: 2
                onMoved: (v) => root.setStart(v * 60 + (Settings.dndStartMin % 60))
            }
            SettingsText {
                height: Theme.settingsStepperHeight
                verticalAlignment: Text.AlignVCenter
                text: ":"
                color: Theme.textSoft
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
            spacing: Theme.space6
            SettingsStepper {
                value: Math.floor(Settings.dndEndMin / 60)
                minValue: 0; maxValue: 23; step: 1; pad: 2
                onMoved: (v) => root.setEnd(v * 60 + (Settings.dndEndMin % 60))
            }
            SettingsText {
                height: Theme.settingsStepperHeight
                verticalAlignment: Text.AlignVCenter
                text: ":"
                color: Theme.textSoft
            }
            SettingsStepper {
                value: Settings.dndEndMin % 60
                minValue: 0; maxValue: 55; step: 5; pad: 2
                onMoved: (v) => root.setEnd(Math.floor(Settings.dndEndMin / 60) * 60 + v)
            }
        }
    }

    Item { width: 1; height: Theme.settingsGroupSpacing }

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
        x: Theme.settingsRowPadX
        width: root.width - Theme.settingsRowPadX * 2
        spacing: Theme.space6
        topPadding: Theme.space4
        SettingsText { text: "Recently notified. Tap to mute."; color: Theme.dim; font.pixelSize: Theme.fontCaption }
        Flow {
            width: parent.width
            spacing: Theme.space6
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
        leftPadding: Theme.settingsRowPadX
        rightPadding: Theme.settingsRowPadX
        wrapMode: Text.WordWrap
        text: "Type an app name exactly as it appears on its notifications. Notifications from muted apps are dismissed right away."
        color: Theme.dim
        font.pixelSize: Theme.fontBody
    }


    SectionLabel { text: "HISTORY" }

    SettingsRow {
        width: root.width
        title: "Notification history"
        valueText: Sys.notifHistory.length === 0 ? "Empty" : Sys.notifHistory.length + " stored"
        SettingsButton {
            label: root.confirmClear ? "Tap again to clear" : "Clear all"
            primary: root.confirmClear
            enabled: Sys.notifHistory.length > 0
            onClicked: {
                if (root.confirmClear) { Sys.clearNotifs(); root.confirmClear = false; confirmTimer.stop(); }
                else { root.confirmClear = true; confirmTimer.restart(); }
            }
        }
    }
}
