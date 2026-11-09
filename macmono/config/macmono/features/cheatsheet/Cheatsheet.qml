import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
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
                width: Math.min(Theme.cheatsheetWidth, win.width - Theme.space8 * 2)
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                clip: true
                transform: Translate { x: -(card.width + Theme.space8) * (1 - Math.min(1, win.anim)) }

                MouseArea { anchors.fill: parent }

                Flickable {
                    id: flick
                    anchors { fill: parent; margins: Theme.cheatsheetPadding }
                    contentWidth: width
                    contentHeight: content.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: win.anim

                    Column {
                        id: content
                        width: flick.width
                        spacing: Theme.cheatsheetGroupSpacing

                        Text {
                            text: "Keyboard shortcuts"
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.panelTitleSize; font.weight: Font.DemiBold; font.letterSpacing: Theme.panelTitleTracking
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
                                    color: Theme.labelCapsText
                                    font.family: Theme.font; font.pixelSize: Theme.labelCapsSize; font.weight: Font.DemiBold
                                    font.letterSpacing: Theme.labelCapsTracking
                                }
                                Repeater {
                                    model: grp.modelData.items
                                    delegate: Item {
                                        id: row
                                        required property var modelData
                                        width: grp.width
                                        height: Theme.cheatsheetRowHeight
                                        Row {
                                            id: caps
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.space4
                                            Repeater {
                                                model: row.modelData[0].split(" + ")
                                                delegate: Rectangle {
                                                    required property string modelData
                                                    width: Math.max(Theme.cheatsheetKeycapMinWidth, capText.implicitWidth + Theme.cheatsheetKeycapPadding)
                                                    height: Theme.cheatsheetKeycapHeight
                                                    radius: Theme.radiusKey
                                                    color: Theme.tileMid
                                                    border.width: Theme.borderThin; border.color: Theme.lineStrong
                                                    Text {
                                                        id: capText
                                                        anchors.centerIn: parent
                                                        text: parent.modelData
                                                        color: Theme.text
                                                        font.family: Theme.font; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium
                                                    }
                                                }
                                            }
                                        }
                                        Text {
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter; left: caps.right; leftMargin: Theme.space12 }
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideRight
                                            text: row.modelData[1]
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Press any key to close"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                        }
                    }
                }
            }
        }
    }
}
