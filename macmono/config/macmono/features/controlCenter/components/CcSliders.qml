import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int ccSliderLabelWidth: 40
    property string expanded: ""
    signal requestExpand(string key)

    Layout.fillWidth: true
    implicitHeight: sliderCol.implicitHeight + 2 * Theme.space12
    radius: Theme.radiusCard
    color: Theme.tile

    ColumnLayout {
        id: sliderCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
        spacing: Theme.space8

        RowLayout {
            visible: Sys.brightnessOk
            Layout.fillWidth: true
            spacing: Theme.space12
            SliderBar {
                Layout.fillWidth: true
                icon: "sun"
                value: Sys.brightness
                onMoved: (v) => Sys.setBrightness(v)
            }
            Text {
                Layout.preferredWidth: root.ccSliderLabelWidth
                horizontalAlignment: Text.AlignRight
                text: Math.round(Sys.brightness * 100) + "%"
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontSm
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space12
            SliderBar {
                Layout.fillWidth: true
                icon: Sys.muted ? "mute" : "volume"
                value: Sys.muted ? 0 : Sys.volume
                onMoved: (v) => Sys.setVolume(v)
            }
            // Tap the volume label to pick the output device.
            MouseArea {
                id: outArea
                Layout.preferredWidth: root.ccSliderLabelWidth
                Layout.fillHeight: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestExpand("sound")
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
                    color: outArea.containsMouse || root.expanded === "sound" ? Theme.text : Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontSm
                    Behavior on color { TweenColor { duration: Theme.durFast } }
                }
            }
        }
        DetailList {
            open: root.expanded === "sound"
            Layout.fillWidth: true
            color: Theme.tile
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
