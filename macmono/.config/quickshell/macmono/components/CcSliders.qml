import QtQuick
import QtQuick.Layouts
import "../core"

// Kartu slider kecerahan + volume + daftar output di Control Center.
Rectangle {
    id: root
    property string expanded: ""
    signal requestExpand(string key)

    Layout.fillWidth: true
    implicitHeight: sliderCol.implicitHeight + 24
    radius: Theme.radiusLarge
    color: Theme.tile

    ColumnLayout {
        id: sliderCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
        spacing: Theme.space10

        RowLayout {
            visible: Sys.brightnessOk
            Layout.fillWidth: true
            spacing: Theme.space10
            SliderBar {
                Layout.fillWidth: true
                icon: "sun"
                value: Sys.brightness
                onMoved: (v) => Sys.setBrightness(v)
            }
            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Math.round(Sys.brightness * 100) + "%"
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontBody
            }
            Item { Layout.preferredWidth: 26 }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space10
            SliderBar {
                Layout.fillWidth: true
                icon: Sys.muted ? "mute" : "volume"
                value: Sys.muted ? 0 : Sys.volume
                onMoved: (v) => Sys.setVolume(v)
            }
            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontBody
            }
            MouseArea {
                id: outBtn
                Layout.preferredWidth: 26; Layout.preferredHeight: 26
                hoverEnabled: true
                onClicked: root.requestExpand("sound")
                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    scale: outBtn.pressed ? Theme.buttonPressedScale : 1
                    color: outBtn.containsMouse || root.expanded === "sound" ? Theme.tileMid : Theme.transparent
                    Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                    Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                }
                Glyph {
                    anchors.centerIn: parent
                    width: 13; height: 13
                    name: "chevron"
                    rotation: root.expanded === "sound" ? 180 : -90
                    color: Theme.text
                    Behavior on rotation { NumberAnimation { duration: Theme.animBase } }
                }
            }
        }
        DetailList {
            open: root.expanded === "sound"
            Layout.fillWidth: true
            color: Theme.tileFaint
            emptyText: "No output devices"
            items: Sys.outputDevices.map(n => ({
                label: Sys.nodeLabel(n),
                sub: "",
                on: n === Sys.sink,
                ref: n
            }))
            onPicked: (item) => Sys.setOutput(item.ref)
        }
    }
}
