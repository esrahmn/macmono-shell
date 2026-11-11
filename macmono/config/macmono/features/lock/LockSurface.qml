pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../core"
import "../../shared/components"
import "../media"

Item {
    id: root

    readonly property int lockPasswordWidth: 260
    readonly property int lockDateSize: 14
    readonly property real lockDateTracking: 3.1
    readonly property real lockClockTracking: -6
    readonly property real lockClockTopRatio: 0.09
    readonly property real lockInputBottomRatio: 0.1
    readonly property real lockWallpaperDim: -0.3
    readonly property int lockShakeAmplitude: 12
    readonly property int lockShakeAmplitudeSoft: 8
    readonly property int animShakeFast: 50
    readonly property int animShakeMid: 60
    readonly property int animShakeSlow: 70

    required property var lock

    readonly property int cardWidth: 400
    readonly property int clockSize: 120
    readonly property var player: Sys.mediaPlayer(Mpris.players.values, -1)
    readonly property string userName: lock.fullName || (Quickshell.env("USER") ?? "")

    Image {
        id: wall
        anchors.fill: parent
        source: Sys.wallpaper !== "" ? "file://" + Sys.wallpaper : ""
        sourceSize.width: 2560
        fillMode: Image.PreserveAspectCrop
        asynchronous: false      // first frame must already be the wallpaper, not a black screen
        cache: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blur: reveal.progress    // 0 = same as desktop; rises to 1 on lock, falls on unlock
        blurMax: 48
        saturation: Sys.wallpaperMono ? -1.0 : 0.0
        brightness: root.lockWallpaperDim * reveal.progress
        opacity: wall.status === Image.Ready ? 1 : 0
        Behavior on opacity { Tween {} }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: input.forceActiveFocus()
    }

    // Masuk: wallpaper desktop -> blur + redup, elemen naik berurutan. Keluar (unlock): kebalikannya,
    // then LockScreen.finishUnlock() opens the session. The surface is destroyed after the scene ends.
    readonly property int rise: 28
    Reveal {
        id: reveal
        open: !root.lock.unlocking
        openStiff: Theme.revealSceneOpenStiff
        closeStiff: Theme.revealSceneCloseStiff
        onSettled: (isOpen) => { if (!isOpen) root.lock.finishUnlock(); }
    }

    Item {
        id: content
        anchors.fill: parent

        RowLayout {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.space24
            spacing: Theme.space16
            opacity: reveal.span(0.45, 1)

            RowLayout {
                visible: Sys.wifiName !== ""
                spacing: Theme.space8
                Glyph { name: "wifi"; color: Theme.text; Layout.preferredWidth: Theme.iconMd; Layout.preferredHeight: Theme.iconMd }
                Text {
                    text: Sys.wifiName
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontMd
                }
            }
            RowLayout {
                visible: Sys.batAvailable
                spacing: Theme.space8
                Text {
                    text: Math.round(Sys.batPercent * 100) + "%"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontMd
                }
                BatteryIcon {}
                Glyph {
                    visible: Sys.batCharging
                    name: "bolt"
                    color: Theme.text
                    Layout.preferredWidth: Settings.lockBoltIconSize
                    Layout.preferredHeight: Settings.lockBoltIconSize
                }
            }
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * root.lockClockTopRatio
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Sys.now, "dddd  \u00B7  d MMMM").toUpperCase()
                opacity: reveal.span(0.05, 0.6)
                transform: Translate { y: -root.rise * (1 - reveal.spanTravel(0.05, 0.65)) }
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: root.lockDateSize
                font.weight: Theme.weightSemibold
                font.letterSpacing: root.lockDateTracking
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Sys.now, "HH:mm")
                opacity: reveal.span(0.12, 0.7)
                scale: 0.94 + 0.06 * reveal.spanTravel(0.12, 0.8)
                transform: Translate { y: -root.rise * (1 - reveal.spanTravel(0.12, 0.8)) }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: root.clockSize
                font.weight: Theme.weightSemibold
                font.letterSpacing: root.lockClockTracking
            }
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * root.lockInputBottomRatio
            spacing: Theme.space16

            MediaCard {
                Layout.preferredWidth: root.cardWidth
                player: root.player
                players: [root.player]
                panelShown: root.visible && Sys.locked
                opacity: reveal.span(0.3, 0.85)
                transform: Translate { y: root.rise * (1 - reveal.spanTravel(0.3, 0.9)) }
            }

            Rectangle {
                id: loginCard
                Layout.preferredWidth: root.cardWidth
                Layout.preferredHeight: loginCol.implicitHeight + Theme.space16 * 2
                color: Theme.transparent

                opacity: reveal.span(0.4, 0.95)
                transform: [
                    Translate { id: shakeT },
                    Translate { y: root.rise * 1.3 * (1 - reveal.spanTravel(0.4, 1.0)) }
                ]
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shakeT; property: "x"; to: -root.lockShakeAmplitude; duration: root.animShakeFast; easing.type: Theme.easeInOut }
                    NumberAnimation { target: shakeT; property: "x"; to: root.lockShakeAmplitude; duration: root.animShakeSlow; easing.type: Theme.easeInOut }
                    NumberAnimation { target: shakeT; property: "x"; to: -root.lockShakeAmplitudeSoft; duration: root.animShakeMid; easing.type: Theme.easeInOut }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: root.animShakeFast; easing.type: Theme.easeInOut }
                }
                Connections {
                    target: root.lock
                    function onShake() { shakeAnim.restart(); }
                    function onRefocus() { input.forceActiveFocus(); }
                }

                ColumnLayout {
                    id: loginCol
                    anchors.centerIn: parent
                    width: parent.width - Theme.space32 * 2
                    spacing: Theme.space16

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Settings.lockAvatarSize
                        Layout.preferredHeight: Settings.lockAvatarSize

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.tile
                            visible: avatarImg.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: (root.userName[0] ?? "?").toUpperCase()
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.font2xl
                                font.weight: Theme.weightSemibold
                            }
                        }
                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                            sourceSize.width: Settings.lockAvatarSize * 2
                            sourceSize.height: Settings.lockAvatarSize * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }
                        Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                        MultiEffect {
                            anchors.fill: parent
                            visible: avatarImg.status === Image.Ready
                            source: avatarImg
                            saturation: Sys.wallpaperMono ? -1.0 : 0.0
                            maskEnabled: true
                            maskSource: avatarMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.userName
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontLg
                        font.weight: Theme.weightSemibold
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.lockPasswordWidth
                        Layout.preferredHeight: Settings.lockPasswordFieldHeight
                        opacity: root.lock.busy ? Theme.opacityDim : 1

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: Theme.borderThin
                            color: (root.lock.failed || input.activeFocus) ? Theme.text : Theme.line
                        }

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space16
                            anchors.rightMargin: Theme.space16
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "\u25CF"
                            color: Theme.text
                            selectionColor: Theme.tileHover
                            font.family: Theme.font
                            font.pixelSize: Theme.fontMd
                            font.letterSpacing: 2
                            readOnly: root.lock.busy
                            focus: true
                            clip: true
                            text: root.lock.password
                            onTextEdited: root.lock.password = text
                            Component.onCompleted: forceActiveFocus()

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.lock.submit();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root.lock.password = "";
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_CapsLock) {
                                    capsDelay.restart();
                                }
                            }
                            Timer { id: capsDelay; interval: Settings.lockCapsRecheckMs; onTriggered: root.lock.checkCaps() }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: input.text === ""
                            text: root.lock.busy ? "Checking..."
                                : root.lock.failed ? "Wrong password" + (root.lock.attempts > 1 ? " (" + root.lock.attempts + ")" : "")
                                : "Enter password"
                            color: root.lock.failed ? Theme.text : Theme.faint
                            font.family: Theme.font
                            font.pixelSize: Theme.fontMd
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.lock.capsLock
                        text: "Caps Lock is on"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontXs
                    }
                }
            }
        }
    }
}
