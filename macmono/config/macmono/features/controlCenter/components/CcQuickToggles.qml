import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../core"
import "../../../shared/components"

// Kolom kanan Control Center: Focus, power profile, Night Light, Mic.
ColumnLayout {
    id: root

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.fillHeight: true
    spacing: Theme.space12

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.space8

        Rectangle {
            Layout.preferredWidth: Theme.ccProfileTileWidth
            Layout.fillHeight: true
            radius: Theme.radiusCard
            scale: focusArea.pressed ? Theme.buttonPressedScale : 1
            color: Sys.dnd ? Theme.inverse : (focusArea.containsMouse ? Theme.tileHover : Theme.tile)
            Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
            Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
            MouseArea {
                id: focusArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Sys.dnd = !Sys.dnd
            }
            Glyph {
                anchors.centerIn: parent
                width: Theme.icon20; height: Theme.icon20
                name: "moon"
                color: Sys.dnd ? Theme.inverseText : Theme.text
            }
        }

        Rectangle {
            id: profileButton
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusCard
            readonly property bool active: Sys.profile !== PowerProfile.PowerSaver
            scale: profileArea.pressed ? Theme.buttonPressedScale : 1
            color: active ? Theme.inverse : (profileArea.containsMouse ? Theme.tileHover : Theme.tile)
            Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
            Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
            Row {
                anchors { left: parent.left; right: parent.right; leftMargin: Theme.space12; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                spacing: Theme.space10
                Glyph {
                    id: profileGlyph
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.icon18; height: Theme.icon18
                    name: Sys.profileGlyph
                    color: profileButton.active ? Theme.inverseText : Theme.text
                    onNameChanged: profileGlyphAnimation.restart()
                    SequentialAnimation {
                        id: profileGlyphAnimation
                        NumberAnimation { target: profileGlyph; property: "opacity"; to: 0; duration: Theme.animPress }
                        NumberAnimation { target: profileGlyph; property: "opacity"; to: 1; duration: Theme.animHover }
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space2
                    Text {
                        text: "Power profile"
                        color: profileButton.active ? Theme.inverseDim : Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        id: profileLabel
                        text: Sys.profileLabel
                        color: profileButton.active ? Theme.inverseText : Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold
                        onTextChanged: profileLabelAnimation.restart()
                        SequentialAnimation {
                            id: profileLabelAnimation
                            NumberAnimation { target: profileLabel; property: "opacity"; to: 0; duration: Theme.animPress }
                            NumberAnimation { target: profileLabel; property: "opacity"; to: 1; duration: Theme.animHover }
                        }
                    }
                }
            }
            MouseArea {
                id: profileArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Sys.cycleProfile()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space12
        Repeater {
            model: [
                { key: "night", glyph: "sunhalf", label: "Night", on: Sys.nightLight },
                { key: "mic", glyph: Sys.micMuted ? "mic-off" : "mic", label: "Mic", on: !Sys.micMuted }
            ]
            delegate: Rectangle {
                id: sq
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: Theme.ccToggleTileHeight
                radius: Theme.radiusCard
                scale: sqArea.pressed ? Theme.buttonPressedScale : 1
                color: modelData.on ? Theme.inverse : (sqArea.containsMouse ? Theme.tileHover : Theme.tile)
                Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.space6
                    Glyph {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.icon22; height: Theme.icon22
                        name: sq.modelData.glyph
                        color: sq.modelData.on ? Theme.inverseText : Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: sq.modelData.label
                        color: sq.modelData.on ? Theme.inverseText : Theme.textSoft
                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                        font.weight: sq.modelData.on ? Font.DemiBold : Font.Normal
                    }
                }
                MouseArea {
                    id: sqArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sq.modelData.key === "night" ? Sys.toggleNightLight() : Sys.toggleMic()
                }
            }
        }
    }
}
