import QtQuick
import "../../../core"

Item {
    id: root

    readonly property int settingsPreviewBarHeight: 24
    readonly property int settingsPreviewPanelHeight: 84
    readonly property int settingsPreviewPanelMax: 260
    property real panelOpacity: 0.60
    property bool clock24h: true
    property bool seconds: false
    property bool showDate: false

    height: SettingsMetrics.settingsPreviewHeight

    readonly property color fill: Qt.rgba(0, 0, 0, Math.max(0.25, Math.min(1, panelOpacity)))

    readonly property string clockLabel: {
        const d = Sys.now;
        const pad = n => (n < 10 ? "0" : "") + n;
        let time;
        if (clock24h) {
            time = pad(d.getHours()) + ":" + pad(d.getMinutes());
            if (seconds) time += ":" + pad(d.getSeconds());
        } else {
            let h = d.getHours() % 12;
            if (h === 0) h = 12;
            time = h + ":" + pad(d.getMinutes());
            if (seconds) time += ":" + pad(d.getSeconds());
            time += d.getHours() < 12 ? " AM" : " PM";
        }
        return showDate ? Qt.formatDateTime(d, "ddd d MMM") + "  " + time : time;
    }

    SettingsWallpaperImage {
        anchors.fill: parent
        path: Sys.wallpaper
        cornerRadius: Theme.radiusCard
    }

    Rectangle {
        id: bar
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.space12 }
        height: root.settingsPreviewBarHeight
        radius: height / 2
        color: root.fill

        Row {
            anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
            spacing: Theme.space8
            Rectangle { width: SettingsMetrics.settingsDot; height: width; radius: width / 2; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
            SettingsText { text: "Desktop"; font.pixelSize: Theme.fontXs; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }
        SettingsText {
            anchors.centerIn: parent
            text: root.clockLabel
            font.pixelSize: Theme.fontXs
            font.weight: Theme.weightSemibold
        }
    }

    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; top: bar.bottom; topMargin: Theme.space12 }
        width: Math.min(parent.width * 0.5, root.settingsPreviewPanelMax)
        height: root.settingsPreviewPanelHeight
        radius: Theme.radiusCard
        color: root.fill
        border.width: Theme.borderThin
        border.color: Theme.line

        Column {
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space8
            SettingsText { text: "Panel"; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold }
            Rectangle { width: parent.width; height: Theme.space8; radius: height / 2; color: Theme.tileHover }
            Rectangle { width: parent.width * 0.6; height: Theme.space8; radius: height / 2; color: Theme.tile }
        }
    }

    Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: Theme.transparent; border.width: Theme.borderThin; border.color: Theme.line }
}
