import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

// Menu power layar penuh (pengganti wlogout): Lock, Sleep, Log out, Restart, Shut down.
// Tombol cepat: L / S / O / R / P, panah + Enter, Esc untuk batal.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.powerOpen && Sys.powerScreen === modelData.name
            property real anim: 0
            property int sel: 2
            Behavior on anim { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }   // fade saja
            readonly property bool present: shown || anim > 0.002

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
                if (!shown) { anim = 0; return; }
                anim = 1;
                sel = 2;
                keys.forceActiveFocus();
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.powerScrim
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
                spacing: Theme.space30
                opacity: win.anim

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.space2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(Sys.now, "HH:mm")
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontClock; font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontHeading
                    }
                }
                Item { width: 1; height: Theme.space14 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.space30
                    Repeater {
                        model: win.items
                        delegate: Column {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool active: win.sel === index
                            spacing: Theme.space14

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Theme.powerButtonSize; height: Theme.powerButtonSize; radius: height / 2
                                color: card.active ? Theme.tileMid : (ma.containsMouse ? Theme.tileHover : Theme.tile)
                                border.width: Theme.borderThin
                                border.color: card.active ? Theme.text : Theme.lineStrong
                                scale: card.active ? 1.06 : 1.0
                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                Behavior on scale { NumberAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                Glyph {
                                    anchors.centerIn: parent
                                    width: Theme.powerGlyphSize; height: Theme.powerGlyphSize
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
                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.Medium
                            }
                        }
                    }
                }
            }
        }
    }
}
