import QtQuick
import QtQuick.Layouts
import "../core"
import "../components"

// Kartu media di Control Center: latar + padding, isinya dari ui/MediaPlayerView.
Rectangle {
    id: root

    property alias player: view.player
    property alias players: view.players
    property alias panelShown: view.panelShown
    signal playerChangeRequested(int index)

    visible: player !== null
    Layout.fillWidth: true
    implicitHeight: view.implicitHeight + 2 * Theme.space12
    radius: Theme.radiusLarge
    color: Theme.tile

    MediaPlayerView {
        id: view
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
        onPlayerChangeRequested: index => root.playerChangeRequested(index)
    }
}
