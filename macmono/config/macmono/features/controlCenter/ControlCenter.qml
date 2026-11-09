import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../../core"
import "../../shared/components"
import "components"
import "../power"
import "../tools"
import "../battery"
import "../media"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.ccOpen && Sys.ccScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:cc"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: !shown ? WlrKeyboardFocus.None
                : wifiList.typing ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.OnDemand

            property string expanded: ""
            function toggleExpand(name) {
                expanded = expanded === name ? "" : name;
                if (expanded === "wifi") Sys.scanWifi();
            }
            onVisibleChanged: if (!visible) expanded = ""

            readonly property bool holdOpen: wifiList.typing || Sys.wifiConnecting !== ""

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                enabled: win.shown && !Sys.capturing && !win.holdOpen
                onPressed: Sys.closeCC()
            }

            property int playerIndex: -1
            readonly property var player: Sys.mediaPlayer(Mpris.players.values, playerIndex)

            Item {
                id: body
                anchors { top: parent.top; right: parent.right; topMargin: Theme.drawerGap; rightMargin: Theme.space8 }
                width: Theme.ccWidth
                height: card.height
                transform: Translate { y: -(body.height + Theme.drawerGap) * (1 - Math.min(1, win.anim)) }

                Rectangle {
                    id: card
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.min(col.implicitHeight + Theme.ccCardPadding, win.height - Theme.space8)
                    Behavior on height {
                        NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut }
                    }
                    radius: Theme.radiusXl
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                }

                Flickable {
                    id: flick
                    anchors { top: card.top; left: card.left; right: card.right; bottom: card.bottom; margins: Theme.space16 }
                    opacity: win.anim
                    contentHeight: col.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: Theme.space12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space6

                            Rectangle {
                                implicitWidth: Theme.ccAvatarSize; implicitHeight: Theme.ccAvatarSize; radius: Math.min(width, height) / 2
                                color: Theme.tile
                                border.width: Theme.borderThin; border.color: Theme.line
                                Image {
                                    id: avatarImg
                                    anchors.fill: parent
                                    source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 72; sourceSize.height: 72
                                    asynchronous: true
                                    visible: false
                                }
                                Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                                MultiEffect {
                                    anchors.fill: parent
                                    visible: avatarImg.status === Image.Ready
                                    source: avatarImg
                                    maskEnabled: true
                                    maskSource: avatarMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }
                                Text {
                                    visible: avatarImg.status !== Image.Ready
                                    anchors.centerIn: parent
                                    text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontHeading; font.weight: Font.DemiBold
                                }
                            }
                            ColumnLayout {
                                spacing: Theme.space0
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Quickshell.env("USER") || "user"
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.panelTitleSize; font.weight: Font.DemiBold
                                    font.letterSpacing: Theme.panelTitleTracking
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                                }
                            }

                            Repeater {
                                model: [ { key: "tools", glyph: "more" }, { key: "power", glyph: "power" } ]
                                delegate: Rectangle {
                                    id: hb
                                    required property var modelData
                                    readonly property bool on: win.expanded === modelData.key
                                    implicitWidth: Theme.ccHeaderButtonSize; implicitHeight: Theme.ccHeaderButtonSize
                                    radius: Math.min(width, height) / 2
                                    scale: hbArea.pressed ? Theme.buttonPressedScale : 1
                                    color: on ? Theme.inverse : (hbArea.containsMouse ? Theme.tileHover : Theme.tile)
                                    Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                    Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                    Glyph {
                                        anchors.centerIn: parent; width: Theme.icon18; height: Theme.icon18
                                        name: hb.modelData.glyph
                                        color: hb.on ? Theme.inverseText : Theme.text
                                    }
                                    MouseArea {
                                        id: hbArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: win.toggleExpand(hb.modelData.key)
                                    }
                                }
                            }
                        }

                        ToolsPanel { open: win.expanded === "tools" }
                        PowerActions { open: win.expanded === "power" }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Theme.space12; rowSpacing: Theme.space12

                            CcNetworkTiles {
                                expanded: win.expanded
                                onRequestExpand: (key) => win.toggleExpand(key)
                            }
                            CcQuickToggles {}
                        }

                        WifiList {
                            id: wifiList
                            open: win.expanded === "wifi"
                            Layout.fillWidth: true
                        }
                        BtList {
                            open: win.expanded === "bt"
                            Layout.fillWidth: true
                        }

                        CcSliders {
                            expanded: win.expanded
                            onRequestExpand: (key) => win.toggleExpand(key)
                        }

                        MediaCard {
                            player: win.player
                            players: Mpris.players.values
                            panelShown: win.shown
                            onPlayerChangeRequested: (index) => win.playerIndex = index
                        }

                        BatteryStatus {}
                    }
                }
            }
        }
    }
}
