import QtQuick
import "../../core"

Item {
    implicitWidth: 27
    implicitHeight: 12

    Rectangle {
        width: 24; height: 12
        radius: height * 0.3
        color: Theme.transparent
        border.width: Theme.borderThin; border.color: Theme.dim

        Rectangle {
            x: 2; y: 2; height: parent.height - 4
            width: Math.max(2, (parent.width - 4) * Math.min(1, Sys.batPercent))
            radius: parent.radius * 0.45
            color: Sys.batCharging ? Theme.accent : Theme.text
        }
    }

    Rectangle { x: 25; y: 4; width: 2; height: 4; radius: Math.min(width, height) / 2; color: Theme.dim }
}
