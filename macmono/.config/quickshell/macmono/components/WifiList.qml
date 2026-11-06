import QtQuick
import "../core"

// Daftar Wi-Fi di Control Center: connect / putus, password untuk jaringan baru, tombol pengaturan.
Rectangle {
    id: root
    property bool open: false
    property string pwFor: ""                 // SSID yang lagi minta password
    readonly property bool typing: pwFor !== ""

    readonly property real fullHeight: col.implicitHeight + 12
    implicitHeight: open ? fullHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    visible: implicitHeight > 0.5
    radius: Theme.radius
    // Daftar = kotak cekung di dalam panel, bukan kartu terangkat: kontennya terasa masuk.
    color: Theme.well
    border.width: Theme.borderThin; border.color: Theme.cardStroke
    clip: true

    onOpenChanged: if (!open) pwFor = ""
    Connections {   // password salah -> buka lagi kolom password-nya
        target: Sys
        function onWifiErrorChanged() {
            if (Sys.wifiError !== "" && Sys.wifiError !== Sys.wifiName) {
                root.pwFor = Sys.wifiError;
                pw.text = "";
                pw.forceActiveFocus();
            }
        }
    }

    function pick(e) {
        if (Sys.wifiName !== "" && e.ssid === Sys.wifiName) { Sys.disconnectWifi(); return; }
        if (e.secure && !e.known) { pwFor = e.ssid; pw.text = ""; pw.forceActiveFocus(); return; }
        pwFor = "";
        Sys.connectWifi(e.ssid, "");
    }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space6 }

        Text {
            visible: Sys.wifiList.length === 0
            width: parent.width; height: Theme.listHeaderHeight
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: Sys.wifiOn ? "Searching for networks…" : "Wi-Fi is off"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
        }

        Repeater {
            model: Sys.wifiList
            delegate: Column {
                id: entry
                required property var modelData
                required property int index
                readonly property bool asking: root.pwFor === modelData.ssid
                // Pakai Sys.wifiName sebagai sumber kebenaran, bukan flag active di cache list
                // (cache bisa stale setelah disconnect sampai scan berikutnya).
                readonly property bool isActive: Sys.wifiName !== "" && modelData.ssid === Sys.wifiName
                readonly property string section: isActive ? "Connected"
                : ((index === 0 || (Sys.wifiList[index - 1] && Sys.wifiList[index - 1].ssid === Sys.wifiName)) ? "Other networks" : "")
                width: col.width

                Text {
                    visible: entry.section !== ""
                    width: parent.width; height: Theme.listSubheaderHeight
                    leftPadding: 10
                    verticalAlignment: Text.AlignBottom
                    bottomPadding: 4
                    text: entry.section
                    color: Theme.faint
                    font.family: Theme.font; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold
                }

                Rectangle {
                    width: parent.width; height: Theme.listRowHeight; radius: Theme.radiusSmall
                    color: area.containsMouse || entry.asking ? Theme.tileMid : Theme.transparent

                    Column {
                        anchors { left: parent.left; leftMargin: Theme.space10; right: status.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: entry.modelData.ssid
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontSubtitle
                            font.weight: entry.isActive ? Font.DemiBold : Font.Normal
                        }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: Sys.wifiConnecting === entry.modelData.ssid ? "Connecting…"
                            : entry.isActive
                            ? ("Connected · " + (entry.modelData.secure ? "Secured · " : "Open · ") + entry.modelData.signal + "%")
                            : Sys.wifiError === entry.modelData.ssid ? "Couldn't connect. Check the password."
                            : ((entry.modelData.known ? "Saved · " : "")
                            + (entry.modelData.secure ? "Secured · " : "Open · ") + entry.modelData.signal + "%")
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                        }
                    }
                    Text {
                        id: status
                        anchors { right: parent.right; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                        text: entry.isActive ? (area.containsMouse ? "Disconnect" : "✓") : ""
                        color: entry.isActive && area.containsMouse ? Theme.dim : Theme.text
                        font.family: Theme.font; font.pixelSize: entry.isActive && area.containsMouse ? Theme.fontSmall : Theme.fontBody
                    }
                    Glyph {   // jaringan baru yang butuh password
                        visible: !entry.isActive && entry.modelData.secure && !entry.modelData.known
                        anchors { right: parent.right; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                        width: Theme.icon13; height: Theme.icon13
                        name: "lock"
                        color: Theme.dim
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: Sys.wifiConnecting === ""
                        onClicked: root.pick(entry.modelData)
                    }
                }

                // kolom password (cuma untuk jaringan yang dipilih)
                Item {
                    visible: entry.asking
                    width: parent.width; height: visible ? Settings.wifiPasswordRowHeight : 0
                    Rectangle {
                        anchors { left: parent.left; right: joinBtn.left; rightMargin: Theme.space6; verticalCenter: parent.verticalCenter; leftMargin: Theme.space6 }
                        height: Theme.wifiPasswordHeight; radius: Math.min(width, height) / 2
                        color: Theme.inset
                        border.width: Theme.borderThin; border.color: pw.activeFocus ? Theme.lineFocus : Theme.line
                        TextInput {
                            id: pw
                            anchors { fill: parent; leftMargin: Theme.space14; rightMargin: 34 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                            color: Theme.text
                            selectionColor: Theme.selection
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                            clip: true
                            Keys.onReturnPressed: joinBtn.join()
                            Keys.onEnterPressed: joinBtn.join()
                            Keys.onEscapePressed: root.pwFor = ""
                            Text {
                                visible: pw.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password"
                                color: Theme.faint
                                font: pw.font
                            }
                        }
                        MouseArea {   // tampilkan / sembunyikan password
                            id: showPw
                            property bool checked: false
                            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                            width: Theme.wifiShowPwWidth; height: Theme.wifiShowPwHeight
                            onClicked: checked = !checked
                            Text {
                                anchors.centerIn: parent
                                text: showPw.checked ? "Hide" : "Show"
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontMicro
                            }
                        }
                    }
                    MouseArea {
                        id: joinBtn
                        function join() { if (pw.text.length >= 8) { Sys.connectWifi(entry.modelData.ssid, pw.text); root.pwFor = ""; } }
                        anchors { right: parent.right; rightMargin: Theme.space6; verticalCenter: parent.verticalCenter }
                        width: Theme.wifiJoinWidth; height: Theme.wifiJoinHeight
                        hoverEnabled: true
                        enabled: pw.text.length >= 8 && Sys.wifiConnecting === ""
                        opacity: enabled ? 1 : Theme.opacityDisabled
                        onClicked: join()
                        Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: Theme.inverse }
                        Text {
                            anchors.centerIn: parent
                            text: "Join"
                            color: Theme.inverseText
                            font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        // footer: scan ulang + pengaturan jaringan
        Item {
            width: col.width; height: Theme.listFooterHeight
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space6; rightMargin: Theme.space6 } height: 1; color: Theme.line }
            Row {
                anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                spacing: Theme.space4
                FooterButton { label: "Rescan"; onClicked: Sys.scanWifi() }
                FooterButton { label: "Wi-Fi Settings…"; onClicked: Sys.openWifiSettings() }
            }
        }
    }

    component FooterButton: MouseArea {
        id: fb
        property string label: ""
        width: fbText.implicitWidth + 20; height: Theme.listActionHeight
        hoverEnabled: true
        Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: fb.containsMouse ? Theme.tileMid : Theme.transparent }
        Text { id: fbText; anchors.centerIn: parent; text: fb.label; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontBodyLg }
    }
}
