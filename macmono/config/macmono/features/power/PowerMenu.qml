import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int fontClock: 84
    readonly property int powerButtonSize: 76
    readonly property int powerGlyphSize: 30
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.powerOpen && Sys.powerScreen === modelData.name
            property int sel: 2
            Reveal { id: reveal; open: win.shown; openStiff: Theme.revealSceneOpenStiff; closeStiff: Theme.revealSceneCloseStiff }
            readonly property int rise: 28
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:power"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var items: [
                { act: "lock",     label: "Lock",      glyph: "lock",    key: "L" },
                { act: "sleep",    label: "Sleep",     glyph: "sleep",   key: "S" },
                { act: "logout",   label: "Log out",   glyph: "logout",  key: "O" },
                { act: "restart",  label: "Restart",   glyph: "restart", key: "R" },
                { act: "shutdown", label: "Shut down", glyph: "power",   key: "P" }
            ]

            function run(act) { Sys.powerOpen = false; Sys.power(act); }

            onShownChanged: {
                if (!shown) return;
                sel = 2;
                keys.forceActiveFocus();
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.anim
            }
            MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: Sys.powerOpen = false }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) { Sys.powerOpen = false; e.accepted = true; return; }
                    if (e.key === Qt.Key_Left)  { win.sel = (win.sel + 4) % 5; e.accepted = true; return; }
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { win.sel = (win.sel + 1) % 5; e.accepted = true; return; }
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.run(win.items[win.sel].act); e.accepted = true; return; }
                    const t = (e.text || "").toUpperCase();
                    for (const it of win.items) if (it.key === t) { win.run(it.act); e.accepted = true; return; }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.space32

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.space2
                    opacity: reveal.span(0, 0.6)
                    scale: 0.94 + 0.06 * reveal.spanTravel(0, 0.85)
                    transform: Translate { y: win.rise * (1 - reveal.spanTravel(0, 0.85)) }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(Sys.now, "HH:mm")
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: root.fontClock; font.weight: Theme.weightSemibold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontLg
                    }
                }
                Item { width: 1; height: Theme.space16 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.space32
                    Repeater {
                        model: win.items
                        delegate: Column {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool active: win.sel === index
                            // buttons appear in sequence; the order reverses by itself on close
                            readonly property real t0: 0.14 + index * 0.075
                            spacing: Theme.space16
                            opacity: reveal.span(card.t0, card.t0 + 0.5)
                            scale: 0.8 + 0.2 * reveal.spanTravel(card.t0, card.t0 + 0.5)
                            transform: Translate { y: win.rise * 1.3 * (1 - reveal.spanTravel(card.t0, card.t0 + 0.5)) }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: root.powerButtonSize; height: root.powerButtonSize; radius: height / 2
                                color: card.active ? Theme.tile : (ma.containsMouse ? Theme.tileHover : Theme.tile)
                                border.width: Theme.borderThin
                                border.color: card.active ? Theme.text : Theme.line
                                scale: card.active ? 1.06 : 1.0
                                Behavior on color { TweenColor { duration: Theme.durFast } }
                                Behavior on scale { Tween { duration: Theme.durFast } }
                                Glyph {
                                    anchors.centerIn: parent
                                    width: root.powerGlyphSize; height: root.powerGlyphSize
                                    name: card.modelData.glyph
                                    color: Theme.text
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: win.sel = card.index
                                    onClicked: win.run(card.modelData.act)
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: card.modelData.label
                                color: card.active ? Theme.text : Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightMedium
                            }
                        }
                    }
                }
            }
        }
    }
}
