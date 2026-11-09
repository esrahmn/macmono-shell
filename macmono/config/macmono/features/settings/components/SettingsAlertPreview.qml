import QtQuick
import "../../../core"

// Pratinjau grup "Battery alerts" (halaman Power): batang baterai 0..100% dengan tanda tiap level
// peringatan dan zona "urgent". Dibaca dari draft (belum di-Apply).
// Dipasang tepat di atas pengaturannya lewat `preview: "alert"` di SettingsSchema (bukan di level halaman).
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

    height: alBody.height + Theme.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    Item {
        id: alBody
        x: Theme.settingsRowPadX
        y: Theme.settingsRowPadY
        width: root.width - Theme.settingsRowPadX * 2
        height: Theme.settingsBatBar + Theme.space8 + Theme.fontBody + Theme.space8 + Theme.fontCaption

        // batang 0..100%
        Rectangle {
            id: bar
            width: parent.width
            height: Theme.settingsBatBar
            radius: height / 2
            color: Theme.tileHover
            // zona urgent: dari 0 sampai level kritis
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.criticalLevel)) / 100
                height: parent.height
                radius: height / 2
                color: Theme.text
            }
        }
        // tanda tiap level peringatan
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
