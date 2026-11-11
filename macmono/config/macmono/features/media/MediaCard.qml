import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../shared/components"
import "components"

Rectangle {
    id: root

    property alias player: view.player
    property alias players: view.players
    property alias panelShown: view.panelShown
    signal playerChangeRequested(int index)

    visible: player !== null
    Layout.fillWidth: true
    implicitHeight: view.implicitHeight + 2 * Theme.space12
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin; border.color: Theme.line

    MediaPlayerView {
        id: view
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
        onPlayerChangeRequested: index => root.playerChangeRequested(index)
    }
}
