import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"
import "components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.settingsOpen && Sys.settingsScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing)
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                enabled: win.shown && !Sys.capturing
                acceptedButtons: Qt.AllButtons
                onPressed: Sys.settingsOpen = false
            }

            Item {
                id: body
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                y: Theme.drawerGap
                width: Math.min(Theme.settingsWidth, Math.max(320, win.width - Theme.space16 * 2))
                height: Math.min(Theme.settingsHeight, Math.max(360, win.height - Theme.space16 * 2))

                transform: Translate {
                    y: -(body.height + Theme.drawerGap) * (1 - Math.min(1, win.anim))
                }

                SettingsPanel {
                    id: panel
                    anchors.fill: parent
                    onCloseRequested: Sys.settingsOpen = false
                }
            }

            onShownChanged: {
                if (shown) panel.focusPanel();
                else panel.revert();
            }
        }
    }
}
