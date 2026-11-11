import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int osdWidth: 240
    readonly property int osdHeight: 56
    readonly property int osdSlideFrom: 48
    readonly property int osdLabelWidth: 34
    readonly property int osdTrackHeight: 6
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

            Reveal { id: reveal; open: win.active }

            visible: reveal.present
            anchors { top: true }
            margins { top: Theme.barMargin + Theme.barHeight + Theme.space8 }
            implicitWidth: root.osdWidth
            implicitHeight: root.osdHeight
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
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                opacity: reveal.progress
                transform: Translate { y: -root.osdSlideFrom * (1 - reveal.progress) }

                Glyph {
                    id: ic
                    anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    width: Theme.iconLg; height: Theme.iconLg
                    name: root.kind === "brightness" ? "sun" : (Sys.muted ? "mute" : "volume")
                    color: Theme.text
                }
                Rectangle {
                    anchors { left: ic.right; leftMargin: Theme.space16; right: pct.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    height: root.osdTrackHeight; radius: Math.min(width, height) / 2
                    color: Theme.tileHover
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.level))
                        height: parent.height; radius: Math.min(width, height) / 2
                        color: Theme.accent
                        Behavior on width { Tween { duration: Theme.durFast } }
                    }
                }
                Text {
                    id: pct
                    anchors { right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    width: root.osdLabelWidth
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100)
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightMedium
                }
            }
        }
    }
}
