import QtQuick
import "../core"

// Daftar kecil yang muncul pas tile di-expand (jaringan wifi, perangkat bluetooth, output suara).
// Tinggi dianimasikan (buka/tutup halus), jadi layout di bawahnya ikut bergeser mulus.
Rectangle {
    id: root
    property bool open: false
    property var items: []            // [{ label, sub, on, ref }]
    property string emptyText: "Nothing here"
    signal picked(var item)

    readonly property real fullHeight: Math.max(1, col.implicitHeight) + 12
    implicitHeight: open ? fullHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    visible: implicitHeight > 0.5

    radius: Theme.radius
    // Daftar = kotak cekung di dalam panel, bukan kartu terangkat: kontennya terasa masuk.
    color: Theme.well
    border.width: Theme.borderThin; border.color: Theme.cardStroke
    clip: true

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space6 }

        Text {
            visible: root.items.length === 0
            width: parent.width
            height: Theme.listHeaderHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.emptyText
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
        }

        Repeater {
            model: root.items
            delegate: Rectangle {
                id: row
                required property var modelData
                width: col.width
                height: Theme.detailRowHeight
                radius: Theme.radiusSmall
                color: area.containsMouse ? Theme.tileMid : Theme.transparent

                Column {
                    anchors { left: parent.left; leftMargin: Theme.space10; right: tick.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.label
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSubtitle
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.sub || ""
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontSmall
                    }
                }
                Glyph {
                    id: tick
                    visible: row.modelData.on === true
                    anchors { right: parent.right; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                    width: Theme.icon14; height: Theme.icon14
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
