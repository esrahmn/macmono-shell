import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int btHeaderHeight: 36
    readonly property int btHintHeight: 64
    readonly property int btToggleHeight: 30
    property bool open: false

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

    onOpenChanged: Sys.setBtScan(open)

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }

        Text {
            visible: Sys.btOn && Sys.btDevices.length === 0
            width: parent.width; height: root.btHeaderHeight
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: "No paired devices"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontMd
        }
        Item {
            visible: !Sys.btOn
            width: parent.width; height: root.btHintHeight
            Column {
                anchors.centerIn: parent
                spacing: Theme.space8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Sys.btAvailable ? "Bluetooth is off" : "No Bluetooth adapter"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontMd
                }
                MouseArea {
                    id: onBtn
                    visible: Sys.btAvailable
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: onText.implicitWidth + 28; height: root.btToggleHeight
                    hoverEnabled: true
                    onClicked: Sys.toggleBt()
                    Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: onBtn.containsMouse ? Theme.accentHover : Theme.accent }
                    Text { id: onText; anchors.centerIn: parent; text: "Turn On"; color: Theme.textOnAccent; font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold }
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
            leftPadding: Theme.space12
            verticalAlignment: Text.AlignBottom
            text: Sys.btScanning ? "Nearby devices · scanning…" : "Nearby devices"
            color: Theme.faint
            font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
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
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space8; rightMargin: Theme.space8 } height: 1; color: Theme.line }
            MouseArea {
                id: setBtn
                anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                width: setText.implicitWidth + 20; height: Theme.listActionHeight
                hoverEnabled: true
                onClicked: Sys.openBtSettings()
                Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: setBtn.containsMouse ? Theme.tile : Theme.transparent }
                Text { id: setText; anchors.centerIn: parent; text: "Bluetooth Settings…"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontMd }
            }
        }
    }

    component DeviceRow: Rectangle {
        id: dr
        property var dev: null
        property string sub: ""
        signal picked()
        height: Theme.listRowHeight; radius: Theme.radiusControl
        color: ma.containsMouse ? Theme.tile : Theme.transparent
        Column {
            anchors { left: parent.left; leftMargin: Theme.space12; right: tick.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: dr.dev?.name ?? ""
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontMd
                font.weight: dr.dev?.connected ? Theme.weightSemibold : Theme.weightRegular
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: dr.sub
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontXs
            }
        }
        Glyph {
            id: tick
            visible: dr.dev?.connected ?? false
            anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
            width: Theme.iconSm; height: Theme.iconSm
            name: "check"
            color: Theme.text
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: dr.picked() }
    }
}
