import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: root
    readonly property int screenCornerRadius: 4   // concentric with the bezel

    readonly property int settingsMonitorHeight: 110
    readonly property int settingsMonitorMaxW: 200
    readonly property int settingsMonitorNeckW: 10
    readonly property int settingsMonitorNeckH: 8
    readonly property int settingsMonitorStandW: 56
    readonly property int settingsMonitorStandH: 5
    property int resW: 1920
    property int resH: 1080
    property int transformV: 0

    readonly property bool swapped: (transformV % 2) === 1
    readonly property real aspect: (swapped ? resH : resW) / Math.max(1, swapped ? resW : resH)
    readonly property real screenW: Math.min(root.settingsMonitorHeight * aspect, root.settingsMonitorMaxW)
    readonly property real screenH: screenW / aspect

    implicitWidth: root.settingsMonitorMaxW
    implicitHeight: root.settingsMonitorHeight + root.settingsMonitorNeckH + root.settingsMonitorStandH

    Rectangle {
        id: screen
        x: (root.width - width) / 2
        y: root.settingsMonitorHeight - root.screenH
        width: root.screenW
        height: root.screenH
        radius: Theme.radiusControl
        color: SettingsMetrics.aboutLaptopBezelFill
        border.width: Theme.borderThin
        border.color: Theme.line
        Behavior on width { Tween { duration: Theme.durFast } }
        Behavior on height { Tween { duration: Theme.durFast } }

        SettingsWallpaperImage {
            anchors { fill: parent; margins: SettingsMetrics.aboutLaptopBezel }
            path: Sys.wallpaper
            cornerRadius: root.screenCornerRadius
            rotation: root.transformV === 2 ? 180 : 0
        }
    }

    Rectangle {
        x: (root.width - width) / 2
        y: root.settingsMonitorHeight
        width: root.settingsMonitorNeckW
        height: root.settingsMonitorNeckH
        color: SettingsMetrics.aboutLaptopBaseBottom
    }
    Rectangle {
        x: (root.width - width) / 2
        y: root.settingsMonitorHeight + root.settingsMonitorNeckH
        width: root.settingsMonitorStandW
        height: root.settingsMonitorStandH
        radius: height / 2
        color: SettingsMetrics.aboutLaptopBaseTop
    }
}
