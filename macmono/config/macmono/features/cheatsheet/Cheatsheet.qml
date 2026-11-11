import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int cheatsheetWidth: 400
    readonly property int cheatsheetPadding: 20
    readonly property int cheatsheetGroupSpacing: 22
    readonly property int cheatsheetRowHeight: 26
    readonly property var groups: KeyList.groups

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.cheatOpen && Sys.cheatScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
            readonly property bool present: reveal.present
            onShownChanged: if (shown) keys.forceActiveFocus()

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea { anchors.fill: parent; enabled: win.shown; onPressed: Sys.cheatOpen = false }
            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => { Sys.cheatOpen = false; e.accepted = true; }
            }

            Rectangle {
                id: card
                anchors {
                    top: parent.top; bottom: parent.bottom; left: parent.left
                    topMargin: Theme.drawerGap; bottomMargin: Theme.space8; leftMargin: Theme.space8
                }
                width: Math.min(root.cheatsheetWidth, win.width - Theme.space8 * 2)
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                clip: true
                transform: Translate { x: Theme.drawerOffset(card.width + Theme.space8, win.travel) }

                MouseArea { anchors.fill: parent }

                Flickable {
                    id: flick
                    anchors { fill: parent; margins: root.cheatsheetPadding }
                    contentWidth: width
                    contentHeight: content.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: win.anim

                    Column {
                        id: content
                        width: flick.width
                        spacing: root.cheatsheetGroupSpacing

                        Text {
                            text: "Keyboard shortcuts"
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.font2xl; font.weight: Theme.weightSemibold; font.letterSpacing: Theme.trackTight
                        }

                        Repeater {
                            model: groups
                            delegate: Column {
                                id: grp
                                required property var modelData
                                spacing: Theme.space8
                                width: content.width

                                Text {
                                    text: grp.modelData.title.toUpperCase()
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                                    font.letterSpacing: Theme.trackCaps
                                }
                                Repeater {
                                    model: grp.modelData.items
                                    delegate: Item {
                                        id: row
                                        required property var modelData
                                        width: grp.width
                                        height: root.cheatsheetRowHeight
                                        Row {
                                            id: caps
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.space4
                                            Repeater {
                                                model: row.modelData[0].split(" + ")
                                                delegate: UiKeycap {
                                                    required property string modelData
                                                    label: modelData
                                                }
                                            }
                                        }
                                        Text {
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter; left: caps.right; leftMargin: Theme.space12 }
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideRight
                                            text: row.modelData[1]
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontSm
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Press any key to close"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: Theme.fontSm
                        }
                    }
                }
            }
        }
    }
}
