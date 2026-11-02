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

        anchors { top: true; right: true }
        margins { top: Theme.barMargin + Theme.barHeight + 8; right: Theme.space8 }
        implicitWidth: 420
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
                    implicitHeight: Math.max(content.implicitHeight, pic.visible ? 56 : 0) + 32
                    radius: Theme.radiusLarge
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line

                    // masuk: geser dari kanan + fade (mulai 0.4 biar blur langsung nempel)
                    transform: Translate { id: slide; x: 0 }
                    ParallelAnimation {
                        running: true
                        NumberAnimation { target: slide; property: "x"; from: 48; to: 0; duration: Theme.animBase; easing.type: Theme.easeOut }
                        NumberAnimation { target: card; property: "opacity"; from: 0.4; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
                    }

                    HoverHandler { id: cardHover }   // kursor di atas kartu = jangan hilang dulu
                    // lama tampil: pakai timeout dari app (notify-send -t), default 6 detik; 0 = sampai ditutup
                    readonly property real timeoutMs: (card.modelData.expireTimeout ?? -1) > 0 ? card.modelData.expireTimeout : 6000   // nilainya milidetik (spesifikasi D-Bus)
                    Timer {
                        interval: card.timeoutMs
                        running: card.modelData.urgency !== NotificationUrgency.Critical && card.modelData.expireTimeout !== 0 && !cardHover.hovered
                        onTriggered: card.modelData.expire()   // timeout = expire, klik = dismiss
                    }

                    readonly property var actionList: (modelData.actions ?? []).filter(a => a.identifier !== "default")
                    readonly property var defaultAction: (modelData.actions ?? []).find(a => a.identifier === "default") ?? null
                    readonly property string img: modelData.image || ""

                    // klik kartu = aksi utama app (mis. buka chat), kalau nggak ada ya tutup
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (card.defaultAction) card.defaultAction.invoke();
                            else card.modelData.dismiss();
                        }
                    }

                    // tombol tutup (selalu kelihatan, lebih terang saat diarahkan)
                    MouseArea {
                        id: closeBtn
                        anchors { top: parent.top; right: parent.right; margins: Theme.space12 }
                        width: 28; height: 28
                        z: 5
                        hoverEnabled: true
                        onClicked: card.modelData.dismiss()
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusCard
                            color: closeBtn.containsMouse ? Theme.inverse : Theme.tileMid
                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                        }
                        Canvas {   // tanda silang
                            anchors.centerIn: parent
                            width: 12; height: 12
                            property color c: closeBtn.containsMouse ? Theme.inverseText : Theme.text
                            onCChanged: requestPaint()
                            onPaint: {
                                const x = getContext("2d"); x.reset();
                                x.strokeStyle = c; x.lineWidth = 1.8; x.lineCap = "round";
                                x.beginPath(); x.moveTo(1, 1); x.lineTo(11, 11); x.moveTo(11, 1); x.lineTo(1, 11); x.stroke();
                            }
                        }
                    }

                    // gambar notifikasi (avatar chat, cover lagu, dll.), dibuat abu-abu
                    Item {
                        id: pic
                        visible: card.img !== "" && picImg.status === Image.Ready
                        anchors { left: parent.left; top: parent.top; margins: Theme.space16 }
                        width: visible ? 56 : 0; height: 56
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
                        anchors { left: pic.visible ? pic.right : parent.left; right: parent.right; top: parent.top; margins: Theme.space16; rightMargin: 46 }
                        spacing: Theme.space4

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.appName
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.summary
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
                        }
                        Text {
                            visible: text !== ""
                            width: parent.width
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            text: card.modelData.body
                            color: Theme.textSoft
                            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                            textFormat: Text.PlainText
                        }

                        // tombol aksi dari app (Reply, Mark as read, dll.)
                        Row {
                            visible: card.actionList.length > 0
                            topPadding: 6
                            spacing: Theme.space6
                            Repeater {
                                model: card.actionList.slice(0, 3)
                                delegate: MouseArea {
                                    id: act
                                    required property var modelData
                                    width: actText.implicitWidth + 24; height: 32
                                    hoverEnabled: true
                                    onClicked: { act.modelData.invoke(); try { card.modelData.dismiss(); } catch (e) {} }
                                    Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: act.containsMouse ? Theme.tileHover : Theme.tile }
                                    Text {
                                        id: actText
                                        anchors.centerIn: parent
                                        text: act.modelData.text
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.Medium
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
