import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../ui"

// OSD volume / kecerahan: pill kecil di bawah layar, hilang sendiri.
Scope {
    id: root
    property string kind: "volume"      // "volume" | "brightness"
    property string screenName: ""
    property bool shown: false
    property bool ready: false          // abaikan perubahan nilai awal saat shell baru start

    readonly property real level: kind === "volume" ? (Sys.muted ? 0 : Math.min(1, Sys.volume)) : Sys.brightness

    Timer { interval: 2500; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1400; onTriggered: root.shown = false }

    function pop(k) {
        if (!ready || Sys.ccOpen || Sys.capturing) return;
        kind = k;
        screenName = Sys.focusedScreenName();
        shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Sys
        function onVolumeChanged() { root.pop("volume"); }
        function onMutedChanged() { root.pop("volume"); }
        function onBrightnessChanged() { root.pop("brightness"); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: pill.opacity > 0.01
            anchors { bottom: true }
            margins { bottom: 90 }
            implicitWidth: 240
            implicitHeight: 56
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            mask: Region {}          // klik tembus
            WlrLayershell.namespace: "macmono:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: height / 2
                color: Theme.popup
                border.width: Theme.borderThin
                border.color: Theme.lineStrong
                opacity: (root.shown && root.screenName === win.modelData.name) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFade; easing.type: Theme.easeOut } }

                Glyph {
                    id: ic
                    anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                    width: 20; height: 20
                    name: root.kind === "brightness" ? "sun" : (Sys.muted ? "mute" : "volume")
                    color: Theme.text
                }
                Rectangle {
                    anchors { left: ic.right; leftMargin: Theme.space14; right: pct.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    height: 6; radius: Math.min(width, height) / 2
                    color: Theme.tileHover
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.level))
                        height: parent.height; radius: Math.min(width, height) / 2
                        color: Theme.text
                        Behavior on width { NumberAnimation { duration: Theme.animPress } }
                    }
                }
                Text {
                    id: pct
                    anchors { right: parent.right; rightMargin: Theme.space18; verticalCenter: parent.verticalCenter }
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100)
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.Medium
                }
            }
        }
    }
}
