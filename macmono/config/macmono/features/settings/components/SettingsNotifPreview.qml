import QtQuick
import "../../../core"

// Pratinjau Notifications: desktop mini dengan satu notifikasi di pojok kanan atas, seperti aslinya.
// Kalau Do Not Disturb sedang nyala, notifikasinya meredup dan ada keterangan bahwa pop-up disembunyikan.
Item {
    id: root
    property bool dnd: false

    height: Theme.settingsPreviewHeight

    SettingsWallpaperImage { anchors.fill: parent; path: Sys.wallpaper; cornerRadius: Theme.radius }

    Rectangle {
        id: popup
        anchors { top: parent.top; right: parent.right; margins: Theme.space16 }
        width: Math.min(parent.width * 0.55, Theme.settingsNotifPreviewW)
        height: popBody.height + Theme.space14 * 2
        radius: Theme.radius
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        opacity: root.dnd ? 0.25 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.animHover } }

        Column {
            id: popBody
            x: Theme.space14
            y: Theme.space14
            width: parent.width - Theme.space14 * 2
            spacing: Theme.space4
            SettingsText { width: parent.width; text: "Messages"; color: Theme.dim; font.pixelSize: Theme.fontBody; elide: Text.ElideRight }
            SettingsText { width: parent.width; text: "New message"; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; elide: Text.ElideRight }
            SettingsText { width: parent.width; text: "Are we still on for 7 tonight?"; color: Theme.textSoft; font.pixelSize: Theme.fontBody; elide: Text.ElideRight }
        }
    }

    Rectangle {
        visible: root.dnd
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.space14 }
        width: dndText.implicitWidth + Theme.space16 * 2
        height: Theme.settingsButtonHeight
        radius: height / 2
        color: Theme.bar
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        SettingsText { id: dndText; anchors.centerIn: parent; text: "Do Not Disturb is on. Pop-ups are hidden."; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold }
    }

    Rectangle { anchors.fill: parent; radius: Theme.radius; color: Theme.transparent; border.width: Theme.borderThin; border.color: Theme.cardStroke }
}
