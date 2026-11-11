import QtQuick
import "../../../core"

Column {
    id: root

    property int changedCount: 0
    property string pageKey: ""
    signal confirmed()

    property bool armed: false
    spacing: 0

    onPageKeyChanged: { armed = false; confirmTimer.stop(); }
    onChangedCountChanged: if (changedCount === 0) { armed = false; confirmTimer.stop(); }

    Timer {
        id: confirmTimer
        interval: SettingsMetrics.settingsConfirmMs
        onTriggered: root.armed = false
    }

    Item {
        width: root.width
        height: SettingsMetrics.settingsGroupSpacing * 2

        Rectangle {
            x: SettingsMetrics.settingsRowPadX
            y: (parent.height - height) / 2
            width: parent.width - SettingsMetrics.settingsRowPadX * 2
            height: Theme.borderThin
            color: Theme.line
        }
    }

    SettingsRow {
        width: root.width
        title: "Reset this page"

        SettingsButton {
            label: root.armed ? "Tap again to reset" : "Reset"
            primary: root.armed
            enabled: root.changedCount > 0
            onClicked: {
                if (!root.armed) {
                    root.armed = true;
                    confirmTimer.restart();
                    return;
                }
                confirmTimer.stop();
                root.armed = false;
                root.confirmed();
            }
        }
    }

    SettingsNote {
        width: root.width
        text: root.changedCount > 0
            ? "Sets " + root.changedCount + (root.changedCount === 1 ? " option" : " options")
              + " on this page back to default. Nothing is saved until you Apply."
            : "Everything on this page is already at its default."
    }
}
