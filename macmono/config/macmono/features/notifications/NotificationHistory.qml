import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../shared/components"

// Notification rows for the Control Center. Empty history = nothing shown (the panel collapses).
ColumnLayout {
    id: root

    readonly property int notifAvatarSize: 36
    visible: Sys.notifHistory.length > 0
    spacing: Theme.space8

    function ago(ms) {
        const s = Math.max(0, Math.floor((Sys.now.getTime() - ms) / 1000));
        if (s < 60) return "now";
        const m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        const h = Math.floor(m / 60);
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d";
    }

    RowLayout {
        // Only exists while the history does; an empty history still collapses the whole section.
        visible: Sys.notifHistory.length > 0
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        MouseArea {
            id: clearAll
            implicitWidth: clearAllText.implicitWidth + Theme.space12 * 2
            implicitHeight: Theme.listActionHeight
            hoverEnabled: true
            onClicked: Sys.clearNotifs()
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: clearAll.containsMouse ? Theme.tileHover : Theme.tile
                Behavior on color { TweenColor { duration: Theme.durFast } }
            }
            Text {
                id: clearAllText
                anchors.centerIn: parent
                text: "Clear all"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
            }
        }
    }

    Repeater {
        model: Sys.notifHistory
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property string title: modelData.summary || modelData.app || "Notification"
            readonly property string detail: modelData.body || (modelData.summary ? (modelData.app || "") : "")

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + 2 * Theme.space12
            radius: Theme.radiusCard
            color: area.containsMouse ? Theme.tileHover : Theme.tile
            Behavior on color { TweenColor { duration: Theme.durFast } }

            RowLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
                spacing: Theme.space12

                Rectangle {
                    Layout.preferredWidth: root.notifAvatarSize
                    Layout.preferredHeight: root.notifAvatarSize
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: Theme.tileHover
                    Text {
                        anchors.centerIn: parent
                        text: row.title.charAt(0).toUpperCase()
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.space2
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.title
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold
                    }
                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: row.detail
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontSm
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignTop
                    text: area.containsMouse ? "✕" : root.ago(row.modelData.time)
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontXs
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Sys.removeNotif(row.modelData.id)
            }
        }
    }
}
