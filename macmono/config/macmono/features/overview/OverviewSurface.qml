import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    // Warm up Hyprland data before the first open so card geometry
    // does not change mid-animation when new monitors/clients arrive.
    Component.onCompleted: Sys.refreshHypr()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.overviewOpen && Sys.overviewScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: body }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onShownChanged: {
                if (!shown) return;
                Sys.refreshHypr();
                ov.resetCursor();
                keyLayer.forceActiveFocus();
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                enabled: win.shown && !Sys.capturing
                onPressed: Sys.overviewOpen = false
            }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Sys.overviewOpen = false
                Keys.onPressed: (e) => { if (ov.handleKey(e)) e.accepted = true; }
            }

            Item {
                id: body
                anchors.centerIn: parent
                width: ov.implicitWidth
                height: ov.implicitHeight
                opacity: win.anim
                scale: Math.min(1,
                    (win.width - Theme.space32 * 2) / Math.max(1, width),
                    (win.height - Theme.space32 * 2) / Math.max(1, height))

                Overview {
                    id: ov
                    anchors.fill: parent
                    screenInfo: win.modelData
                    // Live thumbnails start only after the fade is nearly done:
                    // if capture runs during the animation, each preview
                    // pops in one by one and the panel looks like it animates twice.
                    live: win.shown && win.anim > 0.55 && !Sys.capturing
                    onActivated: (cmd) => Sys.closeAndDispatch(cmd)
                }
            }
        }
    }
}
