import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../core"
import "../ui"

// Popup media berisi kontrol playback dan lirik tersinkron.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.mediaOpen && Sys.mediaScreen === modelData.name
            property real anim: 0
            NumberAnimation { id: openAnim; target: win; property: "anim"; from: 0; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
            onShownChanged: { if (shown) { openAnim.restart(); keys.forceActiveFocus(); } else { openAnim.stop(); anim = 0; } }

            visible: shown
            anchors { top: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight + 8; right: Sys.mediaPopupRightMargin }
            implicitWidth: Sys.mediaPopupWidth
            implicitHeight: card.height
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:media"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                windows: [win]
                active: win.shown
                onCleared: Sys.mediaOpen = false
            }

            property int playerIndex: -1
            readonly property var p: Sys.mediaPlayer(Mpris.players.values, playerIndex)
            // Spasi = play/pause, ←/→ = prev/next, Esc = tutup
            Item {
                id: keys
                focus: true
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) { Sys.mediaOpen = false; e.accepted = true; }
                    else if (!win.p) return;
                    else if (e.key === Qt.Key_Space) { win.p.togglePlaying(); e.accepted = true; }
                    else if (e.key === Qt.Key_Left) { win.p.previous(); e.accepted = true; }
                    else if (e.key === Qt.Key_Right) { win.p.next(); e.accepted = true; }
                }
            }

            Rectangle {
                id: card
                width: parent.width
                height: win.p ? content.implicitHeight + lyrics.height + Theme.space16 * 3
                    : empty.implicitHeight + Theme.space16 * 2
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                transformOrigin: Item.Top
                scale: 0.96 + 0.04 * win.anim
                opacity: Theme.openFromPanel + (1 - Theme.openFromPanel) * win.anim

                Text {
                    id: empty
                    visible: !win.p
                    anchors.centerIn: parent
                    text: "Nothing is playing"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                }

                MediaPlayerView {
                    id: content
                    visible: win.p !== null
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
                    roomy: true
                    player: win.p
                    players: Mpris.players.values
                    panelShown: win.shown
                    opacity: win.anim
                    onPlayerChangeRequested: index => win.playerIndex = index
                }

                LyricsView {
                    id: lyrics
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: content.bottom
                        leftMargin: Theme.space16
                        rightMargin: Theme.space16
                        topMargin: Theme.space16
                    }
                    height: 208
                    player: win.p
                    active: win.shown
                    visible: win.p !== null
                }
            }
        }
    }
}
