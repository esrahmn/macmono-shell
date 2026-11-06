pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../core"
import "../components"

// Tampilan satu monitor: wallpaper blur, jam, media card, kartu login.
Item {
    id: root

    required property var lock

    readonly property int cardWidth: 400
    readonly property int clockSize: 120
    readonly property var player: Sys.mediaPlayer(Mpris.players.values, -1)
    readonly property string userName: lock.fullName || (Quickshell.env("USER") ?? "")

    // ---------------- latar ----------------
    // sourceSize kecil = decode cepat + blur murah; cache: true -> lock berikutnya instan
    Image {
        id: wall
        anchors.fill: parent
        source: Sys.wallpaper !== "" ? "file://" + Sys.wallpaper : ""
        sourceSize.width: 640
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: Sys.wallpaperMono ? -1.0 : 0.0
        brightness: Theme.lockWallpaperDim
        opacity: wall.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: input.forceActiveFocus()
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }

        // ---------------- status kanan atas ----------------
        RowLayout {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.space22
            spacing: Theme.space16

            RowLayout {
                visible: Sys.wifiName !== ""
                spacing: Theme.space6
                Glyph { name: "wifi"; color: Theme.text; Layout.preferredWidth: Theme.icon16; Layout.preferredHeight: Theme.icon16 }
                Text {
                    text: Sys.wifiName
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBodyLg
                }
            }
            RowLayout {
                visible: Sys.batAvailable
                spacing: Theme.space6
                Text {
                    text: Math.round(Sys.batPercent * 100) + "%"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBodyLg
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

        // ---------------- tanggal + jam ----------------
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * Theme.lockClockTopRatio
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Sys.now, "dddd, d MMMM")
                color: Theme.textSoft
                font.family: Theme.font
                font.pixelSize: Theme.fontDisplayMd
                font.weight: Font.Medium
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Sys.now, "HH:mm")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: root.clockSize
                font.weight: Font.DemiBold
            }
        }

        // ---------------- media + login (bawah tengah) ----------------
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * Theme.lockInputBottomRatio
            spacing: Theme.space16

            LockMedia {
                Layout.preferredWidth: root.cardWidth
                visible: root.player !== null
                player: root.player
            }

            Rectangle {
                id: loginCard
                Layout.preferredWidth: root.cardWidth
                Layout.preferredHeight: loginCol.implicitHeight + Theme.space30 * 2
                radius: Theme.radiusXl
                color: Theme.panel
                border.width: 1
                border.color: Theme.lineStrong

                transform: Translate { id: shakeT }
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shakeT; property: "x"; to: -Theme.lockShakeAmplitude; duration: Theme.animShakeFast }
                    NumberAnimation { target: shakeT; property: "x"; to: Theme.lockShakeAmplitude; duration: Theme.animShakeSlow }
                    NumberAnimation { target: shakeT; property: "x"; to: -Theme.lockShakeAmplitudeSoft; duration: Theme.animShakeMid }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: Theme.animShakeFast }
                }
                Connections {
                    target: root.lock
                    function onShake() { shakeAnim.restart(); }
                    function onRefocus() { input.forceActiveFocus(); }
                }

                ColumnLayout {
                    id: loginCol
                    anchors.centerIn: parent
                    width: parent.width - Theme.space30 * 2
                    spacing: Theme.space14

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Settings.lockAvatarSize
                        Layout.preferredHeight: Settings.lockAvatarSize

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.tileMid
                            visible: avatarImg.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: (root.userName[0] ?? "?").toUpperCase()
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontDisplay
                                font.weight: Font.DemiBold
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
                        font.pixelSize: Theme.fontLead
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Settings.lockPasswordFieldHeight
                        radius: height / 2
                        color: Theme.inset
                        border.width: 1
                        border.color: root.lock.failed ? Theme.lineFocus : (input.activeFocus ? Theme.lineFocus : Theme.line)
                        opacity: root.lock.busy ? Theme.opacityDim : 1

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space18
                            anchors.rightMargin: Theme.space18
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "\u25CF"
                            color: Theme.text
                            selectionColor: Theme.selection
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSubtitle
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
                            color: root.lock.failed ? Theme.textSoft : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBodyLg
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.lock.capsLock
                        text: "Caps Lock is on"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
