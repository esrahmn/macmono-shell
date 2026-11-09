import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../../core"
import "../../shared/components"
import "components"

// Popup media berisi kontrol playback dan lirik tersinkron.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.mediaOpen && Sys.mediaScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present
            onShownChanged: { if (shown) keys.forceActiveFocus(); }

            // Window penuh di bawah bar; klik di luar kartu = tutup (pola ControlCenter, tanpa
            // HyprlandFocusGrab). Saat menutup cuma area kartu yang menangkap klik.
            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:media"
            WlrLayershell.layer: WlrLayer.Overlay
            // Exclusive supaya spasi / panah / Esc langsung jalan tanpa harus klik kartu dulu
            // (dulu fokus datang dari HyprlandFocusGrab).
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Klik di luar kartu = tutup. Dimatiin selama screenshot (pemilih area).
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                enabled: win.shown && !Sys.capturing
                onPressed: Sys.mediaOpen = false
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
                anchors { top: parent.top; right: parent.right; topMargin: Theme.drawerGap; rightMargin: Sys.mediaPopupRightMargin }
                width: Sys.mediaPopupWidth
                height: win.p ? content.implicitHeight + lyrics.height + Theme.space16 * 3
                    : empty.implicitHeight + Theme.space16 * 2
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                // laci: kartu keluar dari tepi bawah bar
                transform: Translate { y: -(card.height + Theme.drawerGap) * (1 - Math.min(1, win.anim)) }

                // klik di bagian kartu yang kosong jangan tembus ke penangkap klik di bawahnya
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; z: -1 }

                // cava: area gunung di dasar kartu, di belakang konten
                CavaWave {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: Theme.borderThin
                    }
                    height: Math.min(card.height * 0.4, 150)
                    visible: win.p !== null && Settings.visualizerEnabled && Settings.visualizerInPopup
                    opacity: win.anim
                    levels: Sys.mediaVisualizerLevels
                    cornerRadius: Theme.radiusPanel - Theme.borderThin
                }

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
                    height: Theme.mediaPopupLyricsHeight
                    player: win.p
                    active: win.shown
                    visible: win.p !== null
                }
            }
        }
    }
}
