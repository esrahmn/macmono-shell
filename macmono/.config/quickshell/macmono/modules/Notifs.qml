import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../core"

// Popup notifikasi: gambar (abu-abu), tombol aksi dari app, klik = aksi utama / tutup.
// Riwayatnya disimpan di Sys.notifHistory (lihat kalender di jam).
Scope {
    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: (n) => { Sys.pushNotif(n); if (!Sys.dnd && !Sys.calendarOpen) n.tracked = true; }
    }

    PanelWindow {
        screen: Quickshell.screens[0]
        visible: server.trackedNotifications.values.length > 0

        // Tengah atas, tepat di bawah menubar (sejajar OSD).
        anchors { top: true }
        margins { top: Theme.barMargin + Theme.barHeight + Theme.space8 }
        implicitWidth: Theme.notifWidth
        implicitHeight: list.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: Theme.transparent
        WlrLayershell.namespace: "macmono:notif"
        WlrLayershell.layer: WlrLayer.Overlay

        mask: Region { item: list }

        Column {
            id: list
            width: parent.width
            spacing: Theme.space8

            Repeater {
                model: server.trackedNotifications
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: list.width

                    // Tinggi kartu = tinggi isi (Row) + padding atas/bawah, lalu di-clamp
                    // ke token Theme.notifMinHeight / notifMaxHeight.
                    // Sengaja TIDAK pakai Math.max(isi, ukuran gambar) + padding seperti versi
                    // sebelumnya: cara itu menyembunyikan salah hitung anak dan membuat kartu
                    // melar tanpa batas kalau satu elemen punya implicitHeight aneh.
                    implicitHeight: Math.min(Theme.notifMaxHeight,
                                             Math.max(Theme.notifMinHeight,
                                                      row.implicitHeight + Theme.notifPadTop + Theme.notifPadBottom))
                    radius: Theme.radiusLarge
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    // Jaga-jaga kalau isi melebihi notifMaxHeight: potong, jangan bocor keluar kartu.
                    clip: true
                    opacity: 0

                    // Masuk: turun dari atas bar. Keluar: naik lagi, baru dismiss/expire.
                    property bool leaving: false
                    property string leaveMode: "dismiss"   // "dismiss" | "expire"
                    transform: Translate { id: slide; y: -Theme.notifSlideFrom }

                    ParallelAnimation {
                        id: inAnim
                        running: true
                        NumberAnimation {
                            target: slide; property: "y"
                            from: -Theme.notifSlideFrom; to: 0
                            duration: Theme.animOpen; easing.type: Theme.easeOut
                        }
                        NumberAnimation {
                            target: card; property: "opacity"
                            from: Theme.openFromPanel; to: 1
                            duration: Theme.animBase; easing.type: Theme.easeOut
                        }
                    }

                    ParallelAnimation {
                        id: outAnim
                        NumberAnimation {
                            target: slide; property: "y"
                            to: -Theme.notifSlideFrom
                            duration: Theme.animBase; easing.type: Theme.easeIn
                        }
                        NumberAnimation {
                            target: card; property: "opacity"
                            to: 0
                            duration: Theme.animBase; easing.type: Theme.easeIn
                        }
                        onFinished: {
                            try {
                                if (card.leaveMode === "expire")
                                    card.modelData.expire();
                                else
                                    card.modelData.dismiss();
                            } catch (e) {}
                        }
                    }

                    function beginLeave(mode) {
                        if (card.leaving)
                            return;
                        card.leaving = true;
                        card.leaveMode = mode;
                        inAnim.stop();
                        outAnim.start();
                    }

                    HoverHandler { id: cardHover }   // kursor di atas kartu = jangan hilang dulu

                    readonly property real timeoutMs: (card.modelData.expireTimeout ?? -1) > 0 ? card.modelData.expireTimeout : Settings.notifDefaultTimeoutMs

                    Timer {
                        interval: card.timeoutMs
                        running: !card.leaving && card.modelData.urgency !== NotificationUrgency.Critical && card.modelData.expireTimeout !== 0 && !cardHover.hovered
                        onTriggered: card.beginLeave("expire")
                    }

                    readonly property var defaultAction: (modelData.actions ?? []).find(a => a.identifier === "default") ?? null
                    readonly property string img: modelData.image || ""

                    Timer {
                        id: dismissLater
                        interval: Theme.notifDismissDelay
                        onTriggered: card.beginLeave("dismiss")
                    }

                    // klik kartu = aksi utama app (mis. buka chat), kalau nggak ada ya tutup
                    MouseArea {
                        anchors.fill: parent
                        enabled: !card.leaving
                        onClicked: {
                            if (card.defaultAction) {
                                dismissLater.restart();
                                card.defaultAction.invoke();
                            } else {
                                card.beginLeave("dismiss");
                            }
                        }
                    }

                    // tombol tutup
                    MouseArea {
                        id: closeBtn
                        anchors { top: parent.top; right: parent.right; margins: Theme.space12 }
                        width: Theme.notifCloseSize; height: Theme.notifCloseSize
                        z: 5
                        hoverEnabled: true
                        enabled: !card.leaving
                        onClicked: card.beginLeave("dismiss")
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusCard
                            color: closeBtn.containsMouse ? Theme.inverse : Theme.tileMid
                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                        }
                        Canvas {
                            anchors.centerIn: parent
                            width: Settings.notifCloseIconSize; height: Settings.notifCloseIconSize
                            property color c: closeBtn.containsMouse ? Theme.inverseText : Theme.text
                            onCChanged: requestPaint()
                            onPaint: {
                                const x = getContext("2d"); x.reset();
                                x.strokeStyle = c; x.lineWidth = 1.8; x.lineCap = "round";
                                x.beginPath(); x.moveTo(1, 1); x.lineTo(11, 11); x.moveTo(11, 1); x.lineTo(1, 11); x.stroke();
                            }
                        }
                    }

                    // Isi kartu: [gambar] [app / judul / body / tombol aksi].
                    // Row ini yang menentukan tinggi kartu; padding diambil dari token.
                    Row {
                        id: row
                        anchors {
                            left: parent.left; right: parent.right; top: parent.top
                            leftMargin: Theme.notifPadX
                            rightMargin: Theme.notifTextInset
                            topMargin: Theme.notifPadTop
                            bottomMargin: Theme.notifPadBottom
                        }
                        spacing: Theme.notifImageGap

                        // gambar notifikasi
                        Item {
                            id: pic
                            visible: card.img !== "" && picImg.status === Image.Ready
                            width: Theme.notifImageSize; height: Theme.notifImageSize
                            Image {
                                id: picImg
                                anchors.fill: parent
                                source: card.img
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 112; sourceSize.height: 112
                                asynchronous: true
                                visible: false
                            }
                            Rectangle { id: picMask; anchors.fill: parent; radius: Theme.radiusMedium; visible: false; layer.enabled: true }
                            MultiEffect {
                                anchors.fill: parent
                                source: picImg
                                saturation: -1.0
                                maskEnabled: true
                                maskSource: picMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                        }

                        Column {
                            id: content
                            // Lebar kolom teks = sisa Row setelah gambar; kalau gambar tidak ada,
                            // teks memakai seluruh lebar. Tanpa ini lebar jadi melingkar (parent.width).
                            width: row.width - (pic.visible ? pic.width + row.spacing : 0)
                            spacing: Theme.space6

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.appName
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.summary
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontHeading; font.weight: Font.DemiBold
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                text: card.modelData.body
                                color: Theme.textSoft
                                font.family: Theme.font; font.pixelSize: Theme.fontSubtitle
                                // Body dibaca sebagai kalimat, jadi diberi leading.
                                // lineHeightMode WAJIB eksplisit: bawaan Text itu ProportionalHeight,
                                // jadi tanpa mode, Math.round(px) dibaca sebagai pengali dan baris melar.
                                lineHeightMode: Text.FixedHeight
                                lineHeight: Math.round(Theme.fontSubtitle * Theme.lineProse)
                                textFormat: Text.PlainText
                            }

                            // ==========================================================
                            // TOMBOL AKSI (Bersih, tanpa trik JS)
                            // ==========================================================
                            Row {
                                id: actionRow
                                spacing: Theme.space6

                                // Cek apakah ada aksi yang bukan "default"
                                visible: (card.modelData.actions ?? []).some(a => a.identifier !== "default")

                                Repeater {
                                    // Bind langsung ke list native Quickshell.
                                    // QML akan otomatis me-render ulang jika D-Bus melakukan replace.
                                    model: card.modelData.actions ?? []

                                    delegate: MouseArea {
                                        id: act
                                        required property var modelData

                                        // Sembunyikan tombol "default".
                                        // Row QML otomatis merapatkan tombol yang visible: false.
                                        visible: modelData.identifier !== "default"

                                        width: (actText.text ? actText.implicitWidth : 0) + 24
                                        height: Theme.notifActionHeight
                                        hoverEnabled: true

                                        onClicked: {
                                            dismissLater.restart();
                                            act.modelData.invoke();
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radiusCard
                                            color: act.containsMouse ? Theme.tileHover : Theme.tile
                                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                        }

                                        Text {
                                            id: actText
                                            anchors.centerIn: parent
                                            // Fallback ke identifier kalau app tidak mengirim teks
                                            text: modelData.text || modelData.identifier || "Action"
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.Medium
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
