import QtQuick
import Quickshell
import "../../../core"
import "../../../shared/components"

SettingsRow {
    id: root
    required property var item
    property var value
    signal edit(var v)

    readonly property bool isReadOnly: item.ro === true

    title: item.label
    stacked: item.type === "chips" || item.type === "slider"
    valueText: item.type === "slider" ? SettingsSchema.format(item, value)
             : item.type === "info" ? infoText(item.info, uptimeTick)
             : ""
    resettable: !isReadOnly && !item.live && JSON.stringify(value) !== JSON.stringify(item.def)
    onResetRequested: edit(item.def)

    property int uptimeTick: 0
    Timer {
        interval: 30000
        repeat: true
        running: root.item && root.item.info === "uptime"
        onTriggered: root.uptimeTick++
    }

    function infoText(name, tick) {
        switch (name) {
        case "os":           return Sys.osName;
        case "kernel":       return Sys.kernelVersion;
        case "arch":         return Sys.architecture;
        case "uptime":       return formatUptime(Sys.uptimeSeconds());
        case "settingsPath": return SettingsStore.path;
        case "configFolder": return SettingsStore.dir;
        case "counts":       return SettingsSchema.pages.length + " pages · " + SettingsSchema.settingCount + " settings";
        default:             return "";
        }
    }

    function formatUptime(seconds) {
        const s = Math.max(0, Math.floor(Number(seconds) || 0));
        const days = Math.floor(s / 86400);
        const hours = Math.floor((s % 86400) / 3600);
        const minutes = Math.floor((s % 3600) / 60);
        const plural = (n, unit) => n + " " + unit + (n === 1 ? "" : "s");
        if (days > 0) return plural(days, "day") + ", " + plural(hours, "hour");
        if (hours > 0) return minutes > 0 ? plural(hours, "hour") + ", " + plural(minutes, "minute") : plural(hours, "hour");
        if (minutes > 0) return plural(minutes, "minute");
        return plural(s, "second");
    }

    function runAction(name) {
        if (name === "openFolder")
            Sys.spawn(["xdg-open", SettingsStore.dir]);
    }

    Loader {
        active: root.item.type === "slider"
        width: root.stacked ? parent.width : 0
        sourceComponent: SettingsSlider {
            showValue: false
            value: root.value
            minValue: root.item.min
            maxValue: root.item.max
            step: root.item.step
            valueText: SettingsSchema.format(root.item, root.value)
            defaultValue: typeof root.item.def === "number" ? root.item.def : NaN
            onMoved: v => root.edit(v)
        }
    }

    Loader {
        active: root.item.type === "stepper"
        sourceComponent: SettingsStepper {
            value: root.value
            minValue: root.item.min
            maxValue: root.item.max
            step: root.item.step
            onMoved: v => root.edit(v)
        }
    }

    Loader {
        active: root.item.type === "toggle"
        sourceComponent: SettingsToggle {
            checked: root.value === true
            onToggled: v => root.edit(v)
        }
    }

    Loader {
        active: root.item.type === "chips"
        width: root.stacked ? parent.width : 0
        sourceComponent: SettingsChips {
            model: root.value
            mono: root.item.mono === true
            numeric: root.item.num === true
            onEdited: list => root.edit(list)
        }
    }

    Loader {
        active: root.item.type === "action"

        sourceComponent: Component {
            Rectangle {
                implicitWidth: actionLabel.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
                implicitHeight: SettingsMetrics.settingsButtonHeight
                radius: Theme.radiusControl
                color: actionArea.containsMouse ? Theme.tileHover : Theme.tile
                Behavior on color { TweenColor { duration: Theme.durFast } }

                SettingsText {
                    id: actionLabel
                    anchors.centerIn: parent
                    text: "Open"
                    font.weight: Theme.weightMedium
                }

                MouseArea {
                    id: actionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runAction(root.item.action)
                }
            }
        }
    }
}
