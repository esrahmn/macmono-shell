import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root
    property string kind: "volume"
    property string screenName: ""
    property bool shown: false
    property bool ready: false

    readonly property real level: kind === "volume" ? (Sys.muted ? 0 : Math.min(1, Sys.volume)) : Sys.brightness

    Timer { interval: Settings.osdStartupGraceMs; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: Settings.osdHideMs; onTriggered: root.shown = false }

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

            readonly property bool active: root.shown && root.screenName === win.modelData.name

            visible: pill.opacity > 0.01
            anchors { top: true }
            margins { top: Theme.barMargin + Theme.barHeight + Theme.space8 }
            implicitWidth: Theme.osdWidth
            implicitHeight: Theme.osdHeight
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            mask: Region {}
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
                opacity: win.active ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: win.active ? Theme.animFade : Theme.animBase
                        easing.type: win.active ? Theme.easeOut : Theme.easeIn
                    }
                }
                transform: Translate {
                    id: slide
                    y: win.active ? 0 : -Theme.osdSlideFrom
                    Behavior on y {
                        NumberAnimation {
                            duration: win.active ? Theme.animOpen : Theme.animBase
                            easing.type: win.active ? Theme.easeOut : Theme.easeIn
                        }
                    }
                }

                Glyph {
                    id: ic
                    anchors { left: parent.left; leftMargin: Theme.space18; verticalCenter: parent.verticalCenter }
                    width: Theme.icon20; height: Theme.icon20
                    name: root.kind === "brightness" ? "sun" : (Sys.muted ? "mute" : "volume")
                    color: Theme.text
                }
                Rectangle {
                    anchors { left: ic.right; leftMargin: Theme.space14; right: pct.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    height: Theme.osdTrackHeight; radius: Math.min(width, height) / 2
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
                    width: Theme.osdLabelWidth
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100)
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.Medium
                }
            }
        }
    }
}
