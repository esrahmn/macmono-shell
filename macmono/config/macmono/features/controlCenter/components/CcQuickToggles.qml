import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../core"
import "../../../shared/components"

RowLayout {
    id: root

    readonly property int ccToggleTileHeight: 88

    Layout.fillWidth: true
    spacing: Theme.space8

    Repeater {
        model: ["dnd", "awake", "mic", "power"]
        delegate: CcTile {
            id: tile
            required property string modelData
            readonly property var info: {
                switch (modelData) {
                case "dnd": return { glyph: Sys.dnd ? "bell-off" : "bell", title: "DND", sub: Sys.dnd ? "On" : "", on: Sys.dnd };
                case "awake": return { glyph: "coffee", title: "Awake", sub: Sys.keepAwake ? "On" : "", on: Sys.keepAwake };
                // Mic is always live; the tile only reflects mute so a missing input is explained by the state itself.
                case "mic": return { glyph: Sys.micMuted ? "mic-off" : "mic", title: "Mic", sub: Sys.micMuted ? "Muted" : "", on: Sys.micMuted };
                default: return { glyph: Sys.profileGlyph, title: "Power", sub: Sys.profileLabel, on: Sys.profile !== PowerProfile.PowerSaver };
                }
            }

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: root.ccToggleTileHeight
            active: info.on
            onClicked: {
                if (modelData === "dnd") Sys.dnd = !Sys.dnd;
                else if (modelData === "awake") Sys.keepAwake = !Sys.keepAwake;
                else if (modelData === "mic") Sys.toggleMic();
                else Sys.cycleProfile();
            }

            Glyph {
                anchors { left: parent.left; top: parent.top; leftMargin: Theme.space12; topMargin: Theme.space12 }
                width: Theme.iconLg; height: Theme.iconLg
                name: tile.info.glyph
                color: Theme.text
            }

            Column {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: Theme.space12; rightMargin: Theme.space8; bottomMargin: Theme.space12 }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: tile.info.title
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
                }
                Text {
                    visible: text !== ""
                    width: parent.width; elide: Text.ElideRight
                    text: tile.info.sub
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontXs
                }
            }
        }
    }
}
