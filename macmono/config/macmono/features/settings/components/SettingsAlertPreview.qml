import QtQuick
import "../../../core"

Rectangle {
    id: root
    property var warnLevels: [5, 10, 20]
    property int criticalLevel: 10

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

    height: alBody.height + SettingsMetrics.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    Item {
        id: alBody
        x: SettingsMetrics.settingsRowPadX
        y: SettingsMetrics.settingsRowPadY
        width: root.width - SettingsMetrics.settingsRowPadX * 2
        height: SettingsMetrics.settingsBatBar + Theme.space8 + Theme.fontSm + Theme.space8 + Theme.fontXs

        Rectangle {
            id: bar
            width: parent.width
            height: SettingsMetrics.settingsBatBar
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
                Rectangle { x: tick.cx - width / 2; y: -Theme.space2; width: Theme.borderStrong; height: bar.height + Theme.space2 * 2; color: Theme.dim }
                SettingsText {
                    x: Math.max(0, Math.min(alBody.width - width, tick.cx - width / 2))
                    y: bar.height + Theme.space8
                    text: tick.modelData + "%"
                    font.pixelSize: Theme.fontSm
                }
            }
        }
        SettingsText {
            y: bar.height + Theme.space8 + Theme.fontSm + Theme.space8
            text: "Solid area = urgent warnings (" + root.criticalLevel + "% and below). Lines = alert levels."
            color: SettingsMetrics.settingsDescText
            font.pixelSize: Theme.fontXs
        }
    }
}
