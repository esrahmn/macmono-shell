import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../shared/components"

// Kartu jaringan kiri di Control Center: Wi-Fi / Bluetooth / Keep Awake.
Rectangle {
    id: root
    property string expanded: ""
    signal requestExpand(string key)

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.fillHeight: true
    implicitHeight: netCol.implicitHeight + Theme.space16
    radius: Theme.radiusCard
    // Kartu terangkat: latar lebih terang dari panel + garis tipis supaya batasnya jelas.
    color: Theme.tile
    border.width: Theme.borderThin; border.color: Theme.cardStroke

    Column {
        id: netCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }
        spacing: Theme.space2
        Repeater {
            model: [
                { key: "wifi", glyph: "wifi",      title: "Wi-Fi",
                  on: Sys.wifiOn, sub: Sys.wifiOn ? (Sys.wifiName || "On") : "Off", list: true },
                { key: "bt",   glyph: "bluetooth", title: "Bluetooth",
                  on: Sys.btOn, sub: !Sys.btAvailable ? "Unavailable" : (Sys.btOn ? (Sys.btConnected ? Sys.btConnected.name : "On") : "Off"), list: true },
                { key: "awake", glyph: "coffee",   title: "Keep Awake",
                  on: Sys.keepAwake, sub: Sys.keepAwake ? "On" : "Off", list: false }
            ]
            delegate: Rectangle {
                id: nr
                required property var modelData
                readonly property bool open: root.expanded === modelData.key
                width: netCol.width
                height: Theme.ccNetworkTileHeight
                radius: Theme.radiusCard
                scale: rowArea.pressed ? Theme.buttonPressedScale : 1
                color: open ? Theme.tileMid : (rowArea.containsMouse ? Theme.tileFaint : Theme.transparent)
                Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }

                function toggle() {
                    if (modelData.key === "wifi") Sys.toggleWifi();
                    else if (modelData.key === "bt") Sys.toggleBt();
                    else Sys.keepAwake = !Sys.keepAwake;
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: nr.modelData.list ? root.requestExpand(nr.modelData.key) : nr.toggle()
                }
                Rectangle {
                    id: dot
                    anchors { left: parent.left; leftMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                    width: Theme.ccNetworkIconCircle; height: Theme.ccNetworkIconCircle; radius: Math.min(width, height) / 2
                    scale: dotArea.pressed ? Theme.buttonPressedScale : 1
                    color: nr.modelData.on ? Theme.inverse : (dotArea.containsMouse ? Theme.tileStrong : Theme.tileMid)
                    Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                    Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                    Glyph {
                        anchors.centerIn: parent
                        width: Theme.icon18; height: Theme.icon18
                        name: nr.modelData.glyph
                        color: nr.modelData.on ? Theme.inverseText : Theme.text
                    }
                    MouseArea { id: dotArea; anchors.fill: parent; hoverEnabled: true; onClicked: nr.toggle() }
                }
                Column {
                    anchors { left: dot.right; leftMargin: Theme.space12; right: chev.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: nr.modelData.title
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: nr.modelData.sub
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                    }
                }
                Glyph {
                    id: chev
                    visible: nr.modelData.list
                    anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                    width: visible ? Theme.icon13 : 0; height: Theme.icon13
                    name: "chevron"
                    rotation: nr.open ? 180 : -90
                    color: Theme.dim
                    Behavior on rotation { NumberAnimation { duration: Theme.animBase } }
                }
            }
        }
    }
}
