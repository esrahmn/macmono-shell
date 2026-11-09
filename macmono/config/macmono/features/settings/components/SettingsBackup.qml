import QtQuick
import "../../../core"

Column {
    id: root
    readonly property var svc: Sys.backup
    spacing: 0

    property string armed: ""
    property bool showAll: false

    readonly property var shownBackups: showAll ? svc.backups : svc.backups.slice(0, Theme.settingsBackupShown)

    function press(key, action) {
        if (armed !== key) {
            armed = key;
            confirmTimer.restart();
            return;
        }
        confirmTimer.stop();
        armed = "";
        action();
    }

    function statusFor(action) { return svc.lastAction === action ? svc.status : ""; }

    onVisibleChanged: {
        armed = "";
        showAll = false;
        if (visible) svc.refresh();
        else svc.status = "";
    }
    Component.onCompleted: svc.refresh()

    Connections {
        target: root.svc
        function onResetApplied() {
            Sys.hyprSync.syncInput();
            Sys.hyprSync.syncIdle();
        }
    }

    Timer {
        id: confirmTimer
        interval: Theme.settingsConfirmMs
        onTriggered: root.armed = ""
    }


    SettingsCaps { first: true; text: "BACKUP" }

    SettingsNote {
        width: root.width
        text: "Copies your settings and your Hyprland display and input config."
    }

    SettingsRow {
        width: root.width
        title: "Save a backup"
        SettingsButton {
            label: root.svc.busy ? "Working…" : "Back up now"
            primary: true
            enabled: !root.svc.busy
            onClicked: root.svc.createBackup()
        }
    }

    SettingsText {
        visible: root.statusFor("create") !== ""
        width: root.width
        leftPadding: Theme.settingsRowPadX
        text: root.statusFor("create")
        color: Theme.settingsDescText
        font.pixelSize: Theme.fontBody
    }

    SettingsText {
        visible: root.svc.backups.length === 0
        width: root.width
        leftPadding: Theme.settingsRowPadX
        topPadding: Theme.space4
        text: "No backups yet."
        color: Theme.dim
        font.pixelSize: Theme.fontBody
    }


    SettingsCaps {
        visible: root.svc.backups.length > 0
        text: "SAVED BACKUPS  ·  " + root.svc.backups.length
    }

    SettingsNote {
        visible: root.svc.backups.length > 0
        width: root.width
        text: "Restoring replaces your current settings and reloads Hyprland. The current state is saved as a backup first."
    }

    Repeater {
        model: root.shownBackups

        delegate: SettingsRow {
            id: backupRow
            required property var modelData
            required property int index

            width: root.width
            title: modelData.label
            separator: index > 0

            resettable: true
            resetLabel: root.armed === ("del:" + modelData.stamp) ? "Tap again to delete" : "Delete"
            onResetRequested: root.press("del:" + modelData.stamp, () => root.svc.remove(modelData))

            SettingsButton {
                readonly property bool isArmed: root.armed === backupRow.modelData.stamp
                label: isArmed ? "Tap again to restore" : "Restore"
                primary: isArmed
                enabled: !root.svc.busy
                onClicked: root.press(backupRow.modelData.stamp, () => root.svc.restore(backupRow.modelData))
            }
        }
    }

    Item {
        visible: root.svc.backups.length > Theme.settingsBackupShown
        width: root.width
        height: visible ? Theme.settingsListRowHeight : 0

        SettingsText {
            anchors { left: parent.left; leftMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
            text: root.showAll ? "Show less" : "Show all " + root.svc.backups.length
            color: showArea.containsMouse ? Theme.text : Theme.dim
            font.pixelSize: Theme.fontBodyLg
            font.underline: showArea.containsMouse
        }
        MouseArea {
            id: showArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showAll = !root.showAll
        }
    }

    SettingsText {
        readonly property string msg: root.statusFor("restore") || root.statusFor("remove")
        visible: msg !== ""
        width: root.width
        leftPadding: Theme.settingsRowPadX
        topPadding: Theme.space8
        text: msg
        color: Theme.settingsDescText
        font.pixelSize: Theme.fontBody
    }


    Item {
        width: root.width
        height: Theme.settingsGroupSpacing * 2

        Rectangle {
            x: Theme.settingsRowPadX
            y: (parent.height - height) / 2
            width: parent.width - Theme.settingsRowPadX * 2
            height: Theme.borderThin
            color: Theme.line
        }
    }


    SettingsCaps { first: true; text: "RESET" }

    SettingsNote {
        width: root.width
        text: "Reset sets every option back to its default and rewrites the Hyprland display and input config to match. The current state is saved as a backup first. Deleting backups cannot be undone."
    }

    SettingsRow {
        width: root.width
        title: "Reset all settings"

        SettingsButton {
            readonly property bool isArmed: root.armed === "reset"
            label: isArmed ? "Tap again to reset" : "Reset"
            primary: isArmed
            enabled: !root.svc.busy
            onClicked: root.press("reset", () => root.svc.resetSettings())
        }
    }

    SettingsText {
        visible: root.statusFor("reset") !== ""
        width: root.width
        leftPadding: Theme.settingsRowPadX
        text: root.statusFor("reset")
        color: Theme.settingsDescText
        font.pixelSize: Theme.fontBody
    }

    SettingsRow {
        visible: root.svc.backups.length > 0
        width: root.width
        height: visible ? implicitHeight : 0
        title: "Delete all backups"
        separator: true

        SettingsButton {
            readonly property bool isArmed: root.armed === "clear"
            label: isArmed ? "Tap again to delete " + root.svc.backups.length : "Delete all"
            primary: isArmed
            enabled: !root.svc.busy
            onClicked: root.press("clear", () => root.svc.clearAll())
        }
    }

    SettingsText {
        visible: root.statusFor("clear") !== ""
        width: root.width
        leftPadding: Theme.settingsRowPadX
        text: root.statusFor("clear")
        color: Theme.settingsDescText
        font.pixelSize: Theme.fontBody
    }
}
