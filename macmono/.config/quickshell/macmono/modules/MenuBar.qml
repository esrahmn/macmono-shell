import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import "../core"
import "../components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            visible: Sys.barVisible
            anchors { top: true; left: true; right: true }
            margins { top: Theme.barMargin; left: Theme.barMargin; right: Theme.barMargin }  // sejajar dengan gaps_out (5)
            implicitHeight: Theme.barHeight
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:menubar"

            // Keep Awake: inhibit idle selama toggle aktif
            IdleInhibitor { window: bar; enabled: Sys.keepAwake }

            readonly property var activeTop: ToplevelManager.activeToplevel
            readonly property string appName: {
                const id = activeTop?.appId ?? "";
                if (!id) return "Desktop";
                const parts = id.split(".");
                const n = parts[parts.length - 1];
                return n.charAt(0).toUpperCase() + n.slice(1);
            }

            // ---------------- badan bar (floating) ----------------
            Rectangle {
                anchors.fill: parent
                radius: Theme.barHeight / 2
                color: Theme.bar

                // ============ kiri: logo, workspace, nama app ============
                Row {
                    anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space14

                    Glyph { // logo: ensō -> launcher
                        anchors.verticalCenter: parent.verticalCenter
                        width: 17; height: 17
                        name: "enso"
                        color: Theme.text
                        opacity: launcherArea.containsMouse ? 0.7 : 1
                        Behavior on opacity { NumberAnimation { duration: Theme.animHover } }
                        MouseArea {
                            id: launcherArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Sys.toggleLauncher()
                        }
                    }

                    // workspace: satu bulatan, hover -> melebar nampilin semua
                    Item {
                        id: ws
                        anchors.verticalCenter: parent.verticalCenter
                        height: 16
                        width: wsRow.width
                        readonly property bool open: wsArea.containsMouse
                        // minimal 5 titik, nambah otomatis kalau workspace 6-10 dipakai
                        readonly property int count: Math.min(10, Math.max(5, Hyprland.focusedWorkspace?.id ?? 0,
                                                                           ...Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0 && id <= 10)))

                        MouseArea {
                            id: wsArea
                            anchors.fill: wsRow
                            anchors.margins: -6
                            hoverEnabled: true
                            onWheel: (e) => {
                                Hyprland.dispatch("hl.dsp.focus({workspace = \"r" + (e.angleDelta.y > 0 ? "-1" : "+1") + "\"})");
                            }
                        }

                        Row {
                            id: wsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space0

                            Repeater {
                                model: ws.count
                                delegate: Item {
                                    id: cell
                                    required property int index
                                    readonly property int num: index + 1
                                    readonly property bool active: Hyprland.focusedWorkspace?.id === num
                                    readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === num)
                                    readonly property real dotW: ws.open ? (active ? 20 : 7) : (active ? 8 : 0)
                                    readonly property real gap: ws.open ? 8 : 0

                                    height: 16
                                    width: dotW + (index < ws.count - 1 ? gap : 0)
                                    clip: false
                                    Behavior on width { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: cell.dotW
                                        height: cell.dotW > 0 ? (cell.active && ws.open ? 7 : (cell.active ? 8 : 7)) : 0
                                        radius: height / 2
                                        color: cell.active ? Theme.text : (cell.occupied ? Theme.dim : Theme.faint)
                                        opacity: cell.dotW > 1 ? 1 : 0
                                        Behavior on width { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                                        Behavior on color { ColorAnimation { duration: Theme.animBase } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -2
                                        enabled: ws.open
                                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + cell.num + "})")
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 300)
                        elide: Text.ElideRight
                        text: bar.appName
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSubtitle
                        font.weight: Font.DemiBold
                    }
                }

                // ============ tengah: jam saja ============
                // klik jam -> kalender + notifikasi; titik kecil = ada notifikasi belum dilihat
                MouseArea {
                    id: clockArea
                    anchors.centerIn: parent
                    width: clockText.implicitWidth + 28
                    height: bar.height
                    onClicked: Sys.toggleCalendar(bar.screen.name)
                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(Sys.now, "HH:mm")
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontHeadingLg
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        visible: Sys.notifUnread > 0
                        anchors { left: clockText.right; leftMargin: 5; verticalCenter: clockText.verticalCenter }
                        width: 6; height: 6; radius: Math.min(width, height) / 2
                        color: Theme.text
                    }
                }

                // ============ kanan: tray, status ============
                Row {
                    id: rightContent
                    anchors { right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space14

                    MouseArea {
                        id: miniMediaArea
                        readonly property var player: Sys.mediaPlayer(Mpris.players.values, -1)
                        visible: player !== null
                        anchors.verticalCenter: parent.verticalCenter
                        width: Sys.mediaPopupWidth
                        height: bar.height - 4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Sys.toggleMedia(bar.screen.name,
                                                   Theme.barMargin + Theme.space16 + rightContent.width - x - width)

                        CavaWave {
                            id: miniMediaVisualizer
                            anchors.fill: parent
                            opacity: miniMediaArea.player?.isPlaying ? 1 : 0
                            visible: opacity > 0
                            levels: Sys.mediaVisualizerLevels
                            fillOpacity: 0.10
                            cornerRadius: height / 2
                        }
                    }

                    Row { // tray (di-desaturate biar tetap monochrome)
                        id: trayRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space14
                        // Satu layer untuk seluruh baris tray, bukan satu layer per ikon.
                        // Hasil visualnya sama (semua ikon jadi abu-abu), tapi biayanya 1 tekstur
                        // + 1 pass shader, bukan N: sebelumnya 10 ikon tray = 10 tekstur offscreen
                        // dan 10 pass tambahan setiap bar digambar ulang.
                        // Guard lebar > 0: saat baru start, SystemTray.items masih kosong dan Row
                        // berukuran 0x0 — tidak perlu bikin tekstur kosong untuk itu.
                        // Catatan: layer memotong anak yang keluar bounds item-nya, jadi jangan
                        // taruh badge/indikator yang menonjol keluar sel 18x18 ini.
                        layer.enabled: trayRow.width > 0
                        layer.effect: MultiEffect { saturation: -1.0 }
                        Repeater {
                            model: SystemTray.items
                            delegate: MouseArea {
                                id: trayItem
                                required property var modelData
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: (e) => {
                                    // kiri = buka app (atau menu kalau app-nya cuma punya menu),
                                    // kanan = menu tray, tengah = secondary action
                                    if (e.button === Qt.MiddleButton) { modelData.secondaryActivate(); return; }
                                    if (e.button === Qt.LeftButton && !modelData.onlyMenu) { modelData.activate(); return; }
                                    if (modelData.hasMenu) {
                                        const p = trayItem.mapToItem(null, 0, 0);
                                        Sys.openTrayMenu(modelData, bar.screen.name, p.x + Theme.barMargin + trayItem.width / 2);
                                    }
                                }
                                onWheel: (w) => modelData.scroll(w.angleDelta.y, false)
                                IconImage {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                }
                            }
                        }
                    }

                    // status (klik -> control center)
                    MouseArea {
                        anchors.verticalCenter: parent.verticalCenter
                        width: statusRow.implicitWidth
                        height: bar.height
                        onClicked: Sys.toggleCC(bar.screen.name)

                        Row {
                            id: statusRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space14

                            // rekam layar macmono: pil "● 0:42", klik untuk berhenti
                            Rectangle {
                                visible: Sys.recActive
                                anchors.verticalCenter: parent.verticalCenter
                                width: recRow.implicitWidth + 18; height: 22; radius: Math.min(width, height) / 2
                                color: recArea.containsMouse ? Theme.inverseHover : Theme.inverse
                                Row {
                                    id: recRow
                                    anchors.centerIn: parent
                                    spacing: Theme.space6
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 8; height: 8; radius: recArea.containsMouse ? Theme.radiusIndicator : Math.min(width, height) / 2   // titik -> kotak "stop" saat hover
                                        color: Theme.inverseText
                                        SequentialAnimation on opacity {
                                            running: Sys.recActive && !recArea.containsMouse; loops: Animation.Infinite
                                            NumberAnimation { to: 0.3; duration: Theme.animPulse }
                                            NumberAnimation { to: 1; duration: Theme.animPulse }
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: recArea.containsMouse ? "Stop" : Sys.recLabel
                                        color: Theme.inverseText
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold
                                        font.features: ({ "tnum": 1 })
                                    }
                                }
                                MouseArea {
                                    id: recArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Sys.recordStop()
                                }
                            }

                            // indikator privasi: lagi rekam layar / mic dipakai / kamera dipakai
                            Row {
                                visible: Sys.recording || Sys.micInUse || Sys.camInUse
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space8
                                Rectangle {   // rekam layar: titik berkedip
                                    visible: Sys.recording
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 9; height: 9; radius: Math.min(width, height) / 2
                                    color: Theme.text
                                    SequentialAnimation on opacity {
                                        running: Sys.recording; loops: Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: Theme.animPulse }
                                        NumberAnimation { to: 1; duration: Theme.animPulse }
                                    }
                                }
                                Rectangle {   // mic / kamera: pil putih kecil
                                    visible: Sys.micInUse || Sys.camInUse
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: privRow.implicitWidth + 12; height: 20; radius: Math.min(width, height) / 2
                                    color: Theme.inverse
                                    Row {
                                        id: privRow
                                        anchors.centerIn: parent
                                        spacing: Theme.space4
                                        Glyph { visible: Sys.camInUse; width: 13; height: 13; name: "camera"; color: Theme.inverseText }
                                        Glyph { visible: Sys.micInUse; width: 13; height: 13; name: "mic"; color: Theme.inverseText }
                                    }
                                }
                            }

                            Glyph {
                                visible: Sys.micMuted
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                name: "mic-off"
                                color: Theme.text
                            }
                            Glyph {
                                visible: Sys.dnd
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                name: "moon"
                                color: Theme.text
                            }
                            Glyph {
                                visible: Sys.keepAwake
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                name: "coffee"
                                color: Theme.text
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                name: Sys.wifiGlyph
                                color: Sys.wifiOn ? Theme.text : Theme.dim
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                name: Sys.muted ? "mute" : Sys.volume <= 0.005 ? "volume-zero" : Sys.volume < 0.5 ? "volume-low" : "volume"
                                color: Theme.text
                            }

                            Row { // baterai
                                visible: Sys.batAvailable
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(Sys.batPercent * 100) + "%"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontBodyLg
                                }
                                BatteryIcon { anchors.verticalCenter: parent.verticalCenter }
                                Glyph {
                                    visible: Sys.batCharging
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 11; height: 11
                                    name: "bolt"
                                    color: Theme.text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
