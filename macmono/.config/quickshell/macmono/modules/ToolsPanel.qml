import QtQuick
import QtQuick.Layouts
import "../core"
import "../components"

Rectangle {
    id: root

    property bool open: false
    property bool recOptions: false
    property string recMode: "full"
    property string recAudio: "none"

    Layout.fillWidth: true
    implicitHeight: open ? toolsCol.implicitHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    visible: implicitHeight > 0.5
    color: Theme.transparent
    clip: true
    onOpenChanged: if (!open) recOptions = false

    ColumnLayout {
        id: toolsCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Theme.space8

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space4
            ActionTile {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                glyph: "camera"; label: "Screenshot"
                onClicked: Sys.screenshot("copy", true)
            }
            ActionTile {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                glyph: Sys.recActive ? "stop" : "record"
                label: Sys.recActive ? Sys.recLabel : "Record"
                hot: Sys.recActive || root.recOptions
                onClicked: {
                    if (Sys.recActive) Sys.recordStop();
                    else root.recOptions = !root.recOptions;
                }
            }
            ActionTile {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                glyph: "clipboard"; label: "Clipboard"
                onClicked: Sys.toggleClipboard()
            }
            ActionTile {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                glyph: "image"; label: "Wallpaper"
                onClicked: Sys.openWallpaper()
            }
        }

        ColumnLayout {
            visible: root.recOptions && !Sys.recActive
            Layout.fillWidth: true
            Layout.topMargin: Theme.space2
            spacing: Theme.space8

            Repeater {
                model: [
                    { title: "Capture", key: "mode", opts: [{ v: "full", l: "Full Screen" }, { v: "area", l: "Select Area" }] },
                    { title: "Audio", key: "audio", opts: [{ v: "none", l: "None" }, { v: "system", l: "System" }, { v: "mic", l: "Microphone" }] }
                ]
                delegate: ColumnLayout {
                    id: optGroup
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.space4

                    Text {
                        text: optGroup.modelData.title
                        leftPadding: 4
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.Medium
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space4
                        Repeater {
                            model: optGroup.modelData.opts
                            delegate: Rectangle {
                                id: segment
                                required property var modelData
                                readonly property bool selected: (optGroup.modelData.key === "mode" ? root.recMode : root.recAudio) === modelData.v
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 32
                                radius: Theme.radiusSmall
                                color: selected ? Theme.inverse : (segmentArea.containsMouse ? Theme.tileHover : Theme.tileFaint)

                                Text {
                                    anchors.centerIn: parent
                                    text: segment.modelData.l
                                    color: segment.selected ? Theme.inverseText : Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                                    font.weight: segment.selected ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: segmentArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (optGroup.modelData.key === "mode") root.recMode = segment.modelData.v;
                                        else root.recAudio = segment.modelData.v;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space2
                implicitHeight: 38
                hoverEnabled: true
                onClicked: Sys.recordStart(root.recMode, root.recAudio)
                Rectangle { anchors.fill: parent; radius: Theme.radiusMedium; color: parent.containsMouse ? Theme.inverseHover : Theme.inverse }
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.space8
                    Glyph { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; name: "record"; color: Theme.inverseText }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Start Recording"
                        color: Theme.inverseText
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.DemiBold
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Saved to ~/Videos/Recordings · click the timer in the bar to stop"
                wrapMode: Text.Wrap
                color: Theme.faint
                font.family: Theme.font; font.pixelSize: Theme.fontSmall
            }
        }
    }
}
