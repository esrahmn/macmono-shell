import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int notifWidth: 370
    readonly property int notifPadX: 16
    readonly property int notifPadTop: 20
    readonly property int notifPadBottom: 18
    readonly property int notifMinHeight: 0
    readonly property int notifMaxHeight: 320
    readonly property int notifImageSize: 56
    readonly property int notifImageGap: 14
    readonly property int notifCloseSize: 28
    readonly property int notifActionHeight: 40
    readonly property int notifTextInset: 46
    readonly property int notifSlideFrom: 56
    readonly property int notifDismissDelay: 280
    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: (n) => {
            if (Sys.notifIsMuted(n.appName)) {
                Qt.callLater(() => { try { n.dismiss(); } catch (e) {} });
                return;
            }
            Sys.pushNotif(n);
            if (!Sys.dnd && !Sys.calendarOpen) n.tracked = true;
        }
    }

    PanelWindow {
        screen: Quickshell.screens[0]
        visible: server.trackedNotifications.values.length > 0

        anchors { top: true }
        margins { top: Theme.barMargin + Theme.barHeight + Theme.space8 }
        implicitWidth: root.notifWidth
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

                    implicitHeight: Math.min(root.notifMaxHeight,
                                             Math.max(root.notifMinHeight,
                                                      row.implicitHeight + root.notifPadTop + root.notifPadBottom))
                    radius: Theme.radiusPanel
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    clip: true
                    opacity: reveal.progress

                    property bool leaving: false
                    property string leaveMode: "dismiss"
                    transform: Translate { y: -root.notifSlideFrom * (1 - reveal.progress) }

                    Reveal {
                        id: reveal
                        open: !card.leaving
                        onSettled: (isOpen) => {
                            if (isOpen || !card.leaving) return;
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
                        card.leaveMode = mode;
                        card.leaving = true;
                    }

                    HoverHandler { id: cardHover }

                    // Same on-screen lifetime for every popup; the Control Center history is separate and untouched.
                    readonly property real timeoutMs: Settings.notifDefaultTimeoutMs

                    Timer {
                        interval: card.timeoutMs
                        running: !card.leaving && !cardHover.hovered
                        onTriggered: card.beginLeave("expire")
                    }

                    readonly property var defaultAction: (modelData.actions ?? []).find(a => a.identifier === "default") ?? null
                    readonly property string img: modelData.image || ""

                    Timer {
                        id: dismissLater
                        interval: root.notifDismissDelay
                        onTriggered: card.beginLeave("dismiss")
                    }

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

                    MouseArea {
                        id: closeBtn
                        anchors { top: parent.top; right: parent.right; margins: Theme.space12 }
                        width: root.notifCloseSize; height: root.notifCloseSize
                        z: 5
                        hoverEnabled: true
                        enabled: !card.leaving
                        onClicked: card.beginLeave("dismiss")
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusCard
                            color: closeBtn.containsMouse ? Theme.tilePress : Theme.tile
                            Behavior on color { TweenColor { duration: Theme.durFast } }
                        }
                        Canvas {
                            anchors.centerIn: parent
                            width: Settings.notifCloseIconSize; height: Settings.notifCloseIconSize
                            property color c: Theme.text
                            onCChanged: requestPaint()
                            onPaint: {
                                const x = getContext("2d"); x.reset();
                                x.strokeStyle = c; x.lineWidth = 1.8; x.lineCap = "round";
                                x.beginPath(); x.moveTo(1, 1); x.lineTo(11, 11); x.moveTo(11, 1); x.lineTo(1, 11); x.stroke();
                            }
                        }
                    }

                    Row {
                        id: row
                        anchors {
                            left: parent.left; right: parent.right; top: parent.top
                            leftMargin: root.notifPadX
                            rightMargin: root.notifTextInset
                            topMargin: root.notifPadTop
                            bottomMargin: root.notifPadBottom
                        }
                        spacing: root.notifImageGap

                        Item {
                            id: pic
                            visible: card.img !== "" && picImg.status === Image.Ready
                            width: root.notifImageSize; height: root.notifImageSize
                            Image {
                                id: picImg
                                anchors.fill: parent
                                source: card.img
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 112; sourceSize.height: 112
                                asynchronous: true
                                visible: false
                            }
                            Rectangle { id: picMask; anchors.fill: parent; radius: Theme.radiusCard; visible: false; layer.enabled: true }
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
                            width: row.width - (pic.visible ? pic.width + row.spacing : 0)
                            spacing: Theme.space8

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.appName
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontMd
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.summary
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                text: card.modelData.body
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontMd
                                lineHeightMode: Text.FixedHeight
                                lineHeight: Math.round(Theme.fontMd * Theme.lineProse)
                                textFormat: Text.PlainText
                            }

                            Row {
                                id: actionRow
                                spacing: Theme.space8

                                visible: (card.modelData.actions ?? []).some(a => a.identifier !== "default")

                                Repeater {
                                    model: card.modelData.actions ?? []

                                    delegate: MouseArea {
                                        id: act
                                        required property var modelData

                                        visible: modelData.identifier !== "default"

                                        width: (actText.text ? actText.implicitWidth : 0) + 24
                                        height: root.notifActionHeight
                                        hoverEnabled: true

                                        onClicked: {
                                            dismissLater.restart();
                                            act.modelData.invoke();
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radiusCard
                                            color: act.containsMouse ? Theme.tileHover : Theme.tile
                                            Behavior on color { TweenColor { duration: Theme.durFast } }
                                        }

                                        Text {
                                            id: actText
                                            anchors.centerIn: parent
                                            text: modelData.text || modelData.identifier || "Action"
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightMedium
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
