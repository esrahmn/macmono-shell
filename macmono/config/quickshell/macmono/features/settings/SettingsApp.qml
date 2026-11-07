import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"
import "components"

// Pengaturan Sistem = sidebar di kanan (Super+I atau `qs -c macmono ipc call shell toggleSettings`).
// Animasi buka/tutup SAMA dengan laci lain (Reveal bawaan, token Theme.reveal*): kartu geser masuk
// dari tepi kanan. Isi ada di components/SettingsPanel.qml.
// Klik di luar kartu atau Esc menutup; kalau ada perubahan yang belum diterapkan,
// klik di luar diabaikan dan Esc pertama membuang perubahan dulu.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.settingsOpen && Sys.settingsScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            // Window tetap seukuran layar di bawah bar (nggak di-resize tiap frame); yang bergerak cuma kartu.
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onShownChanged: {
                if (shown) panel.focusSearch();
                else panel.revert();
            }

            // Klik di luar kartu = tutup (kecuali masih ada perubahan yang belum diterapkan).
            MouseArea {
                anchors.fill: parent
                enabled: win.shown
                onPressed: if (!panel.dirty) Sys.settingsOpen = false
            }

            Item {
                id: card
                anchors {
                    top: parent.top; bottom: parent.bottom; right: parent.right
                    topMargin: Theme.drawerGap; bottomMargin: Theme.space8; rightMargin: Theme.space8
                }
                width: Math.min(Theme.settingsWidth, win.width - Theme.space8 * 2)
                // laci: kartu masuk dari tepi kanan layar
                transform: Translate { x: (card.width + Theme.space8) * (1 - Math.min(1, win.anim)) }

                MouseArea { anchors.fill: parent }   // klik di dalam kartu jangan tembus ke penutup

                SettingsPanel {
                    id: panel
                    anchors.fill: parent
                    onCloseRequested: Sys.settingsOpen = false
                }
            }
        }
    }
}
