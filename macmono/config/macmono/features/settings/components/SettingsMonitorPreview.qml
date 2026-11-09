import QtQuick
import "../../../core"

// Gambar monitor mini: bentuknya ikut resolusi dan rotasi yang dipilih (draft), isinya wallpaper aktif.
Item {
    id: root
    property int resW: 1920
    property int resH: 1080
    property int transformV: 0

    readonly property bool swapped: (transformV % 2) === 1
    readonly property real aspect: (swapped ? resH : resW) / Math.max(1, swapped ? resW : resH)
    readonly property real screenW: Math.min(Theme.settingsMonitorHeight * aspect, Theme.settingsMonitorMaxW)
    readonly property real screenH: screenW / aspect

    implicitWidth: Theme.settingsMonitorMaxW
    implicitHeight: Theme.settingsMonitorHeight + Theme.settingsMonitorNeckH + Theme.settingsMonitorStandH

    // layar + bezel
    Rectangle {
        id: screen
        x: (root.width - width) / 2
        y: Theme.settingsMonitorHeight - root.screenH
        width: root.screenW
        height: root.screenH
        radius: Theme.radiusKey
        color: Theme.aboutLaptopBezelFill
        border.width: Theme.borderThin
        border.color: Theme.lineStrong
        Behavior on width { NumberAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
        Behavior on height { NumberAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }

        SettingsWallpaperImage {
            anchors { fill: parent; margins: Theme.aboutLaptopBezel }
            path: Sys.wallpaper
            cornerRadius: Theme.radiusIndicator * 2
            rotation: root.transformV === 2 ? 180 : 0
        }
    }

    // kaki: leher + alas
    Rectangle {
        x: (root.width - width) / 2
        y: Theme.settingsMonitorHeight
        width: Theme.settingsMonitorNeckW
        height: Theme.settingsMonitorNeckH
        color: Theme.aboutLaptopBaseBottom
    }
    Rectangle {
        x: (root.width - width) / 2
        y: Theme.settingsMonitorHeight + Theme.settingsMonitorNeckH
        width: Theme.settingsMonitorStandW
        height: Theme.settingsMonitorStandH
        radius: height / 2
        color: Theme.aboutLaptopBaseTop
    }
}
