import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../core"
import "../../shared/components"
import "components"
import "../notifications"

Scope {
    id: root

    readonly property int ccWidth: 480
    readonly property int ccPadding: 20
    readonly property int ccAvatarSize: 44
    readonly property int ccHeaderButtonSize: 36
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.ccOpen && Sys.ccScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
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
            // The panel always opens from the top, not at the last scroll position.
            onShownChanged: if (shown) flick.contentY = 0

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
                width: root.ccWidth
                height: card.height
                transform: Translate { y: Theme.drawerOffset(body.height + Theme.drawerGap, win.travel) }

                Rectangle {
                    id: card
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.min(col.implicitHeight + 2 * root.ccPadding, win.height - Theme.space8)
                    Behavior on height {
                        Tween {}
                    }
                    radius: Theme.radiusPanel
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                }

                Flickable {
                    id: flick
                    anchors { top: card.top; left: card.left; right: card.right; bottom: card.bottom; margins: root.ccPadding }
                    opacity: win.anim
                    contentHeight: col.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: Theme.space16

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space12

                            Rectangle {
                                implicitWidth: root.ccAvatarSize; implicitHeight: root.ccAvatarSize; radius: Math.min(width, height) / 2
                                color: Theme.tileHover
                                // Round avatar without a color effect: ClippingRectangle clips the corners directly,
                                // with no separate layer mask + shader effect (two offscreen renders).
                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Theme.transparent
                                    visible: avatarImg.status === Image.Ready
                                    Image {
                                        id: avatarImg
                                        anchors.fill: parent
                                        source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 72; sourceSize.height: 72
                                        asynchronous: true
                                    }
                                }
                                Text {
                                    visible: avatarImg.status !== Image.Ready
                                    anchors.centerIn: parent
                                    text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Quickshell.env("USER") || "user"
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontXl; font.weight: Theme.weightSemibold
                                    font.letterSpacing: Theme.trackSnug
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontSm
                                }
                            }

                            CcTile {
                                Layout.preferredWidth: root.ccHeaderButtonSize
                                Layout.preferredHeight: root.ccHeaderButtonSize
                                radius: height / 2
                                active: Sys.recActive || Sys.recStartPending
                                onClicked: {
                                    if (Sys.recActive) Sys.recordStop();
                                    else if (!Sys.recStartPending) Sys.recordStart("full", "none");
                                }
                                Glyph {
                                    anchors.centerIn: parent; width: Theme.iconLg; height: Theme.iconLg
                                    name: Sys.recActive ? "stop" : "record"
                                    color: Theme.text
                                }
                            }
                        }


                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space8

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

                        CcMedia {
                            player: win.player
                            players: Mpris.players.values
                            panelShown: win.shown
                            onPlayerChangeRequested: (index) => win.playerIndex = index
                        }

                        NotificationHistory { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}
