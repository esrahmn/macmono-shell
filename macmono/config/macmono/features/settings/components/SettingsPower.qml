import QtQuick
import Quickshell.Services.UPower
import "../../../core"
import "../../../shared/components"

Column {
    id: root

    readonly property int settingsSegHeight: 38
    spacing: SettingsMetrics.settingsGroupSpacing

    readonly property var profiles: {
        const list = [
            { label: "Saver", p: PowerProfile.PowerSaver, info: "Lowers performance to stretch the battery. Best when you are away from a charger." },
            { label: "Balanced", p: PowerProfile.Balanced, info: "A good mix of speed and battery life for everyday use." }
        ];
        if (Sys.hasPerformance) list.push({ label: "Performance", p: PowerProfile.Performance, info: "Full speed. Uses more power and runs warmer, and works best on the charger." });
        return list;
    }
    readonly property var current: {
        for (const x of profiles) if (x.p === Sys.profile) return x;
        return profiles[0];
    }

    readonly property int pct: Math.round(Sys.batPercent * 100)
    readonly property bool full: Sys.batPercent >= 0.995 && !Sys.batCharging
    readonly property string status: full ? "Fully charged" : (Sys.batCharging ? "Charging" : "On battery")
    readonly property string timeText: {
        if (full) return "";
        const s = Sys.batSeconds;
        if (!s || s <= 0) return "Estimating time…";
        const h = Math.floor(s / 3600);
        const m = Math.round((s % 3600) / 60);
        const t = h > 0 ? h + " h " + m + " min" : m + " min";
        return t + (Sys.batCharging ? " until full" : " remaining");
    }

    component Caption: SettingsText {
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
        leftPadding: SettingsMetrics.settingsRowPadX
    }

    Column {
        visible: Sys.batAvailable
        width: parent.width
        spacing: Theme.space8
        Caption { text: "BATTERY" }

        Rectangle {
            width: parent.width
            height: batBody.height + SettingsMetrics.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.line

            Column {
                id: batBody
                x: SettingsMetrics.settingsRowPadX
                y: SettingsMetrics.settingsRowPadY
                width: parent.width - SettingsMetrics.settingsRowPadX * 2
                spacing: Theme.space12

                Item {
                    width: parent.width
                    height: pctText.height
                    SettingsText {
                        id: pctText
                        text: root.pct + "%"
                        font.pixelSize: Theme.font2xl
                        font.weight: Theme.weightSemibold
                        font.letterSpacing: Theme.trackSnug
                    }
                    Column {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space2
                        SettingsText { anchors.right: parent.right; text: root.status; font.weight: Theme.weightSemibold }
                        SettingsText {
                            anchors.right: parent.right
                            visible: root.timeText !== ""
                            text: root.timeText
                            color: SettingsMetrics.settingsDescText
                            font.pixelSize: Theme.fontSm
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: SettingsMetrics.settingsBatBar
                    radius: height / 2
                    color: Theme.tileHover
                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, Math.min(1, Sys.batPercent))
                        radius: height / 2
                        color: Theme.text
                        Behavior on width { Tween { duration: Theme.durFast } }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: "POWER PROFILE" }

        Rectangle {
            width: parent.width
            height: profBody.height + SettingsMetrics.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.line

            Column {
                id: profBody
                x: SettingsMetrics.settingsRowPadX
                y: SettingsMetrics.settingsRowPadY
                width: parent.width - SettingsMetrics.settingsRowPadX * 2
                spacing: Theme.space12

                Rectangle {
                    width: parent.width
                    height: root.settingsSegHeight
                    radius: Theme.radiusCard
                    color: Theme.tile

                    Row {
                        anchors { fill: parent; margins: Theme.space2 }
                        Repeater {
                            model: root.profiles
                            delegate: Rectangle {
                                id: seg
                                required property var modelData
                                readonly property bool on: Sys.profile === modelData.p
                                width: parent.width / root.profiles.length
                                height: parent.height
                                radius: Theme.radiusControl
                                color: on ? Theme.text : (segArea.containsMouse ? Theme.tile : Theme.transparent)
                                Behavior on color { TweenColor { duration: Theme.durFast } }

                                SettingsText {
                                    anchors.centerIn: parent
                                    text: seg.modelData.label
                                    color: seg.on ? Theme.panel : Theme.text
                                    font.pixelSize: Theme.fontSm
                                    font.weight: Theme.weightSemibold
                                }
                                MouseArea {
                                    id: segArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Sys.setProfile(seg.modelData.p)
                                }
                            }
                        }
                    }
                }

                SettingsText {
                    width: parent.width
                    text: root.current.info
                    color: SettingsMetrics.settingsDescText
                    font.pixelSize: Theme.fontSm
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
