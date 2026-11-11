import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int detailRowHeight: 44
    property bool open: false
    property var items: []
    property string emptyText: "Nothing here"
    signal picked(var item)

    readonly property real fullHeight: Math.max(1, col.implicitHeight) + 12
    implicitHeight: open ? fullHeight : 0
    Behavior on implicitHeight { Tween {} }
    opacity: open ? 1 : 0
    Behavior on opacity { Tween {} }
    visible: implicitHeight > 0.5

    radius: Theme.radiusCard
    color: Theme.scrim
    border.width: Theme.borderThin; border.color: Theme.line
    clip: true

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }

        Item {
            visible: root.items.length === 0
            width: parent.width
            height: Theme.listHeaderHeight
            UiEmptyState {
                anchors.centerIn: parent
                width: parent.width
                title: root.emptyText
            }
        }

        Repeater {
            model: root.items
            delegate: Rectangle {
                id: row
                required property var modelData
                width: col.width
                height: root.detailRowHeight
                radius: Theme.radiusControl
                color: area.containsMouse ? Theme.tile : Theme.transparent

                Column {
                    anchors { left: parent.left; leftMargin: Theme.space12; right: tick.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.label
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontMd
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.sub || ""
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontXs
                    }
                }
                Glyph {
                    id: tick
                    visible: row.modelData.on === true
                    anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    width: Theme.iconSm; height: Theme.iconSm
                    name: "check"
                    color: Theme.text
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.picked(row.modelData)
                }
            }
        }
    }
}
