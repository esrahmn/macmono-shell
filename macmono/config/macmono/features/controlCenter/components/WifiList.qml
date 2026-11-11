import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int wifiPasswordHeight: 32
    readonly property int wifiShowPwWidth: 28
    readonly property int wifiShowPwHeight: 24
    readonly property int wifiJoinWidth: 64
    readonly property int wifiJoinHeight: 32
    property bool open: false
    property string pwFor: ""
    readonly property bool typing: pwFor !== ""

    readonly property real fullHeight: col.implicitHeight + 12
    implicitHeight: open ? fullHeight : 0
    Behavior on implicitHeight { Tween {} }
    opacity: open ? 1 : 0
    Behavior on opacity { Tween {} }
    visible: implicitHeight > 0.5
    radius: Theme.radiusCard
    color: Theme.scrim
    border.width: Theme.borderThin; border.color: Theme.line
    clip: true

    onOpenChanged: if (!open) pwFor = ""
    Connections {
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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }

        Text {
            visible: Sys.wifiList.length === 0
            width: parent.width; height: Theme.listHeaderHeight
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: Sys.wifiOn ? "Searching for networks…" : "Wi-Fi is off"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontMd
        }

        Repeater {
            model: Sys.wifiList
            delegate: Column {
                id: entry
                required property var modelData
                required property int index
                readonly property bool asking: root.pwFor === modelData.ssid
                readonly property bool isActive: Sys.wifiName !== "" && modelData.ssid === Sys.wifiName
                readonly property string section: isActive ? "Connected"
                : ((index === 0 || (Sys.wifiList[index - 1] && Sys.wifiList[index - 1].ssid === Sys.wifiName)) ? "Other networks" : "")
                width: col.width

                Text {
                    visible: entry.section !== ""
                    width: parent.width; height: Theme.listSubheaderHeight
                    leftPadding: Theme.space12
                    verticalAlignment: Text.AlignBottom
                    bottomPadding: Theme.space4
                    text: entry.section
                    color: Theme.faint
                    font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                }

                Rectangle {
                    width: parent.width; height: Theme.listRowHeight; radius: Theme.radiusControl
                    color: area.containsMouse || entry.asking ? Theme.tile : Theme.transparent

                    Column {
                        anchors { left: parent.left; leftMargin: Theme.space12; right: status.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: entry.modelData.ssid
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontMd
                            font.weight: entry.isActive ? Theme.weightSemibold : Theme.weightRegular
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
                            font.family: Theme.font; font.pixelSize: Theme.fontXs
                        }
                    }
                    Text {
                        id: status
                        anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                        text: entry.isActive ? (area.containsMouse ? "Disconnect" : "✓") : ""
                        color: entry.isActive && area.containsMouse ? Theme.dim : Theme.text
                        font.family: Theme.font; font.pixelSize: entry.isActive && area.containsMouse ? Theme.fontXs : Theme.fontSm
                    }
                    Glyph {
                        visible: !entry.isActive && entry.modelData.secure && !entry.modelData.known
                        anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                        width: Theme.iconSm; height: Theme.iconSm
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

                Item {
                    visible: entry.asking
                    width: parent.width; height: visible ? Settings.wifiPasswordRowHeight : 0
                    Rectangle {
                        anchors { left: parent.left; right: joinBtn.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter; leftMargin: Theme.space8 }
                        height: root.wifiPasswordHeight; radius: Math.min(width, height) / 2
                        color: Theme.scrim
                        border.width: Theme.borderThin; border.color: pw.activeFocus ? Theme.lineFocus : Theme.line
                        TextInput {
                            id: pw
                            anchors { fill: parent; leftMargin: Theme.space16; rightMargin: root.wifiShowPwWidth + Theme.space8 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                            color: Theme.text
                            selectionColor: Theme.tileHover
                            font.family: Theme.font; font.pixelSize: Theme.fontSm
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
                        MouseArea {
                            id: showPw
                            property bool checked: false
                            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                            width: root.wifiShowPwWidth; height: root.wifiShowPwHeight
                            onClicked: checked = !checked
                            Text {
                                anchors.centerIn: parent
                                text: showPw.checked ? "Hide" : "Show"
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontXs
                            }
                        }
                    }
                    MouseArea {
                        id: joinBtn
                        function join() { if (pw.text.length >= 8) { Sys.connectWifi(entry.modelData.ssid, pw.text); root.pwFor = ""; } }
                        anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        width: root.wifiJoinWidth; height: root.wifiJoinHeight
                        hoverEnabled: true
                        enabled: pw.text.length >= 8 && Sys.wifiConnecting === ""
                        opacity: enabled ? 1 : Theme.opacityDisabled
                        onClicked: join()
                        Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: Theme.accent }
                        Text {
                            anchors.centerIn: parent
                            text: "Join"
                            color: Theme.textOnAccent
                            font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
                        }
                    }
                }
            }
        }

        Item {
            width: col.width; height: Theme.listFooterHeight
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space8; rightMargin: Theme.space8 } height: 1; color: Theme.line }
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
        Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: fb.containsMouse ? Theme.tile : Theme.transparent }
        Text { id: fbText; anchors.centerIn: parent; text: fb.label; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontMd }
    }
}
