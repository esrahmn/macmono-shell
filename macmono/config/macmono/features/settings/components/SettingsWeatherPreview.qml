import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int settingsWeatherHeight: 96
    readonly property int settingsWeatherIcon: 40
    readonly property int settingsWeatherTempSize: 44
    readonly property real settingsWeatherTempTracking: -1.4
    readonly property var svc: Sys.weather
    readonly property bool ready: svc.available
    readonly property bool failed: !ready && !svc.loading && svc.error !== ""

    readonly property var today: svc.daily.length > 0 ? svc.daily[0] : null
    readonly property string detail: {
        if (!ready) return "";
        let t = "Feels like " + Math.round(svc.current.feels) + "°";
        if (today) t += "  ·  H " + Math.round(today.max) + "°  L " + Math.round(today.min) + "°";
        return t;
    }
    readonly property string headline: ready ? svc.describe(svc.current.code)
        : (svc.loading ? "Updating…" : (failed ? svc.error : "No data yet"))

    height: root.settingsWeatherHeight
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.line

    onVisibleChanged: if (visible) svc.ensureFresh()
    Component.onCompleted: if (visible) svc.ensureFresh()

    Row {
        x: SettingsMetrics.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space16

        Glyph {
            visible: root.ready
            anchors.verticalCenter: parent.verticalCenter
            width: root.settingsWeatherIcon
            height: width
            name: root.ready ? root.svc.iconFor(root.svc.current.code, root.svc.current.isDay) : ""
            color: Theme.text
        }

        SettingsText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.ready ? Math.round(root.svc.current.temp) + "°" : "–"
            color: root.ready ? Theme.text : Theme.faint
            font.pixelSize: root.settingsWeatherTempSize
            font.weight: Theme.weightSemibold
            font.letterSpacing: root.settingsWeatherTempTracking
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2
            SettingsText {
                text: root.headline
                color: root.ready ? Theme.text : Theme.dim
                font.pixelSize: Theme.fontLg
                font.weight: Theme.weightMedium
            }
            SettingsText {
                visible: root.ready
                text: root.detail
                color: Theme.dim
                font.pixelSize: Theme.fontSm
            }
        }
    }

    SettingsButton {
        visible: root.failed
        anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
        label: "Retry"
        onClicked: root.svc.refresh()
    }
}
