import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../components"

// Klik jam di bar -> kalender bulan + riwayat notifikasi (ala Notification Center macOS).
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.calendarOpen && Sys.calendarScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present
            property var selectedDate: new Date()
            onShownChanged: {
                if (!shown) return;
                const d = new Date();
                viewYear = d.getFullYear(); viewMonth = d.getMonth();
                selectedDate = d;
            }

            // tinggi window tetap, kartu di dalamnya yang berubah; area kosong tembus klik
            visible: present
            anchors { top: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            implicitWidth: 420
            implicitHeight: modelData.height - (Theme.barMargin + Theme.barHeight) - 8
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            // Mask JANGAN pakai item: card. Region(item) nggak ngikutin transform/Translate,
            // jadi pas anim=0 kartu ada di atas layar -> mask kosong -> semua klik tembus ->
            // HyprlandFocusGrab ke-clear -> kalender nutup. Pakai posisi akhir (statis).
            mask: Region { x: 0; y: Theme.drawerGap; width: win.width; height: card.height }
            WlrLayershell.namespace: "macmono:calendar"
            WlrLayershell.layer: WlrLayer.Overlay

            HyprlandFocusGrab {
                windows: [win]
                active: win.shown && !Sys.capturing
                onCleared: if (!Sys.capturing && !win.active) Sys.calendarOpen = false
            }

            // ---------------- data kalender ----------------
            property int viewYear: new Date().getFullYear()
            property int viewMonth: new Date().getMonth()     // 0..11
            function shiftMonth(n) {
                let m = viewMonth + n, y = viewYear;
                while (m < 0) { m += 12; y--; }
                while (m > 11) { m -= 12; y++; }
                viewMonth = m; viewYear = y;
            }
            // 42 sel (6 minggu), minggu mulai Senin
            readonly property var cells: {
                const first = new Date(viewYear, viewMonth, 1);
                const offset = (first.getDay() + 6) % 7;
                const out = [];
                const today = Sys.now;
                for (let i = 0; i < 42; i++) {
                    const d = new Date(viewYear, viewMonth, 1 - offset + i);
                    out.push({
                        date: d,
                        day: d.getDate(),
                        inMonth: d.getMonth() === viewMonth,
                        today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
                    });
                }
                return out;
            }
            function selectDate(date) {
                selectedDate = date;
                if (date.getFullYear() !== viewYear || date.getMonth() !== viewMonth) {
                    viewYear = date.getFullYear();
                    viewMonth = date.getMonth();
                }
            }
            function ago(t) {
                const s = Math.max(0, Math.floor((Sys.now.getTime() - t) / 1000));
                if (s < 60) return "now";
                if (s < 3600) return Math.floor(s / 60) + "m";
                if (s < 86400) return Math.floor(s / 3600) + "h";
                return Math.floor(s / 86400) + "d";
            }

            Item {
                id: body
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.drawerGap }
                height: card.height
                // laci: kartu keluar dari tepi bawah bar (bagian di atas window terpotong otomatis)
                transform: Translate { y: -(body.height + Theme.drawerGap) * (1 - Math.min(1, win.anim)) }

                Rectangle {
                    id: card
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.min(col.implicitHeight + 32, win.height)
                    radius: Theme.radiusPanel
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
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
                        spacing: Theme.space14

                        // ---- tanggal besar ----
                        ColumnLayout {
                            spacing: Theme.space0
                            Text {
                                text: Qt.formatDate(win.selectedDate, "dddd")
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.Medium
                            }
                            Text {
                                text: Qt.formatDate(win.selectedDate, "d MMMM yyyy")
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontDisplay; font.weight: Font.DemiBold
                            }
                        }

                        // ---- kalender ----
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: calCol.implicitHeight + 28
                            radius: Theme.radius
                            color: Theme.tile

                            ColumnLayout {
                                id: calCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space14 }
                                spacing: Theme.space10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: Qt.formatDate(new Date(win.viewYear, win.viewMonth, 1), "MMMM yyyy")
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
                                        MouseArea {   // klik judul bulan -> balik ke bulan ini
                                            anchors.fill: parent
                                            onClicked: {
                                                const d = new Date();
                                                win.viewYear = d.getFullYear();
                                                win.viewMonth = d.getMonth();
                                                win.selectedDate = d;
                                            }
                                        }
                                    }
                                    Repeater {
                                        model: [-1, 1]
                                        delegate: MouseArea {
                                            id: nav
                                            required property int modelData
                                            Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                            hoverEnabled: true
                                            onClicked: win.shiftMonth(modelData)
                                            Rectangle { anchors.fill: parent; radius: Theme.radiusXs; color: nav.containsMouse ? Theme.tileHover : Theme.transparent }
                                            Glyph {
                                                anchors.centerIn: parent
                                                width: 15; height: 15
                                                name: "chevron"
                                                rotation: nav.modelData < 0 ? 90 : -90
                                                color: Theme.text
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    id: grid
                                    Layout.preferredWidth: calCol.width
                                    columns: 7
                                    readonly property real cw: calCol.width / 7
                                    Repeater {
                                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                        delegate: Text {
                                            required property string modelData
                                            width: grid.cw; height: 30
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData
                                            color: Theme.faint
                                            font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.Medium
                                        }
                                    }
                                    Repeater {
                                        model: win.cells
                                        delegate: Item {
                                            id: dayCell
                                            required property var modelData
                                            width: grid.cw; height: 46
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 40; height: 40; radius: Math.min(width, height) / 2
                                                color: dayArea.containsMouse && !isSelected ? Theme.tileHover : (isSelected ? Theme.inverse : Theme.transparent)
                                                border.width: modelData.today && !isSelected ? 1 : 0
                                                border.color: Theme.dim
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day
                                                color: isSelected ? Theme.inverseText : (modelData.inMonth ? Theme.text : Theme.faint)
                                                font.family: Theme.font; font.pixelSize: Theme.fontTitle
                                                font.weight: isSelected || modelData.today ? Font.DemiBold : Font.Normal
                                            }
                                            readonly property bool isSelected: modelData.date.getFullYear() === win.selectedDate.getFullYear()
                                                && modelData.date.getMonth() === win.selectedDate.getMonth()
                                                && modelData.date.getDate() === win.selectedDate.getDate()
                                            MouseArea {
                                                id: dayArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: win.selectDate(dayCell.modelData.date)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---- notifikasi ----
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Notifications"
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
                            }
                            // Do Not Disturb cepat
                            MouseArea {
                                id: dndBtn
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28
                                hoverEnabled: true
                                onClicked: Sys.dnd = !Sys.dnd
                                Rectangle {
                                    anchors.fill: parent; radius: Math.min(width, height) / 2
                                    color: Sys.dnd ? Theme.inverse : (dndBtn.containsMouse ? Theme.tileHover : Theme.transparent)
                                }
                                Glyph {
                                    anchors.centerIn: parent; width: 14; height: 14
                                    name: "moon"
                                    color: Sys.dnd ? Theme.inverseText : Theme.text
                                }
                            }
                            MouseArea {
                                id: clearBtn
                                visible: Sys.notifHistory.length > 0
                                Layout.preferredWidth: clearText.implicitWidth + 18; Layout.preferredHeight: 26
                                hoverEnabled: true
                                onClicked: Sys.clearNotifs()
                                Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: clearBtn.containsMouse ? Theme.tileHover : Theme.tile }
                                Text {
                                    id: clearText
                                    anchors.centerIn: parent
                                    text: "Clear all"
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                }
                            }
                        }

                        Text {
                            visible: Sys.notifHistory.length === 0
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space6; Layout.bottomMargin: Theme.space10
                            horizontalAlignment: Text.AlignHCenter
                            text: Sys.dnd ? "Do Not Disturb is on" : "No notifications"
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                        }

                        Repeater {
                            model: Sys.notifHistory
                            delegate: Rectangle {
                                id: nrow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: ncol.implicitHeight + 20
                                radius: Theme.radius
                                color: nArea.containsMouse ? Theme.tileHover : Theme.tile

                                ColumnLayout {
                                    id: ncol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space10; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                                    spacing: Theme.space2
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: nrow.modelData.app || "Notification"
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                        }
                                        Text {
                                            text: nArea.containsMouse ? "✕" : win.ago(nrow.modelData.time)
                                            color: Theme.faint
                                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: nrow.modelData.summary
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.DemiBold
                                    }
                                    Text {
                                        visible: text !== ""
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        text: nrow.modelData.body
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                                    }
                                }
                                MouseArea {   // klik = hapus dari riwayat
                                    id: nArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Sys.removeNotif(nrow.modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
