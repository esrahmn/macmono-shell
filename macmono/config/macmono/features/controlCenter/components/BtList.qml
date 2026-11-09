import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    property bool open: false

    readonly property real fullHeight: col.implicitHeight + 12
    implicitHeight: open ? fullHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    visible: implicitHeight > 0.5
    radius: Theme.radiusCard
    color: Theme.well
    border.width: Theme.borderThin; border.color: Theme.cardStroke
    clip: true

    onOpenChanged: Sys.setBtScan(open)

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space6 }

        Text {
            visible: Sys.btOn && Sys.btDevices.length === 0
            width: parent.width; height: Theme.btHeaderHeight
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: "No paired devices"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
        }
        Item {
            visible: !Sys.btOn
            width: parent.width; height: Theme.btHintHeight
            Column {
                anchors.centerIn: parent
                spacing: Theme.space8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Sys.btAvailable ? "Bluetooth is off" : "No Bluetooth adapter"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                }
                MouseArea {
                    id: onBtn
                    visible: Sys.btAvailable
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: onText.implicitWidth + 28; height: Theme.btToggleHeight
                    hoverEnabled: true
                    onClicked: Sys.toggleBt()
                    Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: onBtn.containsMouse ? Theme.inverseHover : Theme.inverse }
                    Text { id: onText; anchors.centerIn: parent; text: "Turn On"; color: Theme.inverseText; font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold }
                }
            }
        }

        Repeater {
            model: Sys.btOn ? Sys.btDevices : []
            delegate: DeviceRow {
                required property var modelData
                dev: modelData
                width: col.width
                sub: modelData.connected ? ("Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : ""))
                     : (modelData.state === 3 ? "Connecting…" : "Paired")
                onPicked: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
            }
        }

        Text {
            visible: Sys.btOn
            width: parent.width; height: Theme.listSubheaderHeight
            leftPadding: 10
            verticalAlignment: Text.AlignBottom
            text: Sys.btScanning ? "Nearby devices · scanning…" : "Nearby devices"
            color: Theme.faint
            font.family: Theme.font; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold
        }
        Repeater {
            model: Sys.btOn ? Sys.btNew : []
            delegate: DeviceRow {
                required property var modelData
                dev: modelData
                width: col.width
                sub: Sys.btPairing === modelData ? "Pairing…" : "Click to pair"
                onPicked: Sys.pairBt(modelData)
            }
        }

        Item {
            width: col.width; height: Theme.listFooterHeight
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space6; rightMargin: Theme.space6 } height: 1; color: Theme.line }
            MouseArea {
                id: setBtn
                anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                width: setText.implicitWidth + 20; height: Theme.listActionHeight
                hoverEnabled: true
                onClicked: Sys.openBtSettings()
                Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: setBtn.containsMouse ? Theme.tileMid : Theme.transparent }
                Text { id: setText; anchors.centerIn: parent; text: "Bluetooth Settings…"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontBodyLg }
            }
        }
    }

    component DeviceRow: Rectangle {
        id: dr
        property var dev: null
        property string sub: ""
        signal picked()
        height: Theme.listRowHeight; radius: Theme.radiusSmall
        color: ma.containsMouse ? Theme.tileMid : Theme.transparent
        Column {
            anchors { left: parent.left; leftMargin: Theme.space10; right: tick.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: dr.dev?.name ?? ""
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontSubtitle
                font.weight: dr.dev?.connected ? Font.DemiBold : Font.Normal
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: dr.sub
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontSmall
            }
        }
        Glyph {
            id: tick
            visible: dr.dev?.connected ?? false
            anchors { right: parent.right; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
            width: Theme.icon14; height: Theme.icon14
            name: "check"
            color: Theme.text
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: dr.picked() }
    }
}
