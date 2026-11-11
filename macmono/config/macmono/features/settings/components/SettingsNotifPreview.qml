import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: root

    readonly property int settingsNotifPreviewW: 300
    property bool dnd: false

    height: SettingsMetrics.settingsPreviewHeight

    SettingsWallpaperImage { anchors.fill: parent; path: Sys.wallpaper; cornerRadius: Theme.radiusCard }

    Rectangle {
        id: popup
        anchors { top: parent.top; right: parent.right; margins: Theme.space16 }
        width: Math.min(parent.width * 0.55, root.settingsNotifPreviewW)
        height: popBody.height + Theme.space16 * 2
        radius: Theme.radiusCard
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.line
        opacity: root.dnd ? 0.25 : 1
        Behavior on opacity { Tween { duration: Theme.durFast } }

        Column {
            id: popBody
            x: Theme.space16
            y: Theme.space16
            width: parent.width - Theme.space16 * 2
            spacing: Theme.space4
            SettingsText { width: parent.width; text: "Messages"; color: Theme.dim; font.pixelSize: Theme.fontSm; elide: Text.ElideRight }
            SettingsText { width: parent.width; text: "New message"; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold; elide: Text.ElideRight }
            SettingsText { width: parent.width; text: "Are we still on for 7 tonight?"; color: Theme.text; font.pixelSize: Theme.fontSm; elide: Text.ElideRight }
        }
    }

    Rectangle {
        visible: root.dnd
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.space16 }
        width: dndText.implicitWidth + Theme.space16 * 2
        height: SettingsMetrics.settingsButtonHeight
        radius: height / 2
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.line
        SettingsText { id: dndText; anchors.centerIn: parent; text: "Do Not Disturb is on. Pop-ups are hidden."; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold }
    }

    Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: Theme.transparent; border.width: Theme.borderThin; border.color: Theme.line }
}
