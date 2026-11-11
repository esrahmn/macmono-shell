import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../shared/components"

RowLayout {
    id: root

    readonly property int ccNetworkTileHeight: 64
    readonly property int ccNetworkIconHit: 36
    readonly property int ccNetworkTextInset: 44
    property string expanded: ""
    signal requestExpand(string key)

    Layout.fillWidth: true
    spacing: Theme.space8

    Repeater {
        model: ["wifi", "bt"]
        delegate: CcTile {
            id: tile
            required property string modelData
            readonly property bool isWifi: modelData === "wifi"
            readonly property bool isOn: isWifi ? Sys.wifiOn : Sys.btOn
            readonly property bool open: root.expanded === modelData
            readonly property string sub: isWifi
                ? (Sys.wifiOn ? (Sys.wifiName || "On") : "Off")
                : (!Sys.btAvailable ? "Unavailable" : (Sys.btOn ? (Sys.btConnected ? Sys.btConnected.name : "On") : "Off"))

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: root.ccNetworkTileHeight
            active: isOn
            // Tile body opens the list; the icon on the left toggles on/off.
            onClicked: root.requestExpand(modelData)

            function toggle() {
                if (isWifi) Sys.toggleWifi();
                else Sys.toggleBt();
            }

            Item {
                anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                width: root.ccNetworkIconHit; height: root.ccNetworkIconHit
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: iconArea.pressed ? Theme.tilePress : iconArea.containsMouse ? Theme.tileHover : Theme.transparent
                    Behavior on color { TweenColor { duration: Theme.durFast } }
                }
                Glyph {
                    anchors.centerIn: parent
                    width: Theme.iconLg; height: Theme.iconLg
                    name: tile.isWifi ? "wifi" : "bluetooth"
                    color: Theme.text
                }
                MouseArea {
                    id: iconArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: tile.toggle()
                }
            }

            Column {
                anchors { left: parent.left; leftMargin: root.ccNetworkTextInset; right: chev.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: tile.isWifi ? "Wi-Fi" : "Bluetooth"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: tile.sub
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontSm
                }
            }

            Glyph {
                id: chev
                anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                width: Theme.iconSm; height: Theme.iconSm
                name: "chevron"
                rotation: tile.open ? 180 : -90
                color: Theme.dim
                Behavior on rotation { Tween {} }
            }
        }
    }
}
