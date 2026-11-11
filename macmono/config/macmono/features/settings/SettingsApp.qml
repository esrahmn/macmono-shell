import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"
import "components"

Scope {
    id: root

    readonly property int settingsWidth: 960
    readonly property int settingsHeight: 760
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.settingsOpen && Sys.settingsScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
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
                width: Math.min(root.settingsWidth, Math.max(320, win.width - Theme.space16 * 2))
                height: Math.min(root.settingsHeight, Math.max(360, win.height - Theme.space16 * 2))

                transform: Translate {
                    y: Theme.drawerOffset(body.height + Theme.drawerGap, win.travel)
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
