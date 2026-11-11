import QtQuick
import Quickshell
import "../../core"
import "../../shared/components"
import "../../shared/components/GlyphPaths.js" as Icons

// Side by side check of the vector icons (left) against the old canvas drawing (right),
// at two sizes. Run:  qs -p scripts/development/glyph-preview.qml
// Only icons present in GlyphPaths.js are listed.
ShellRoot {
    FloatingWindow {
        title: "macmono glyph preview"
        implicitWidth: 820
        implicitHeight: 700
        color: "#1c1c1e"

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            contentWidth: width
            contentHeight: grid.height
            clip: true

            Grid {
                id: grid
                width: parent.width
                columns: 2
                columnSpacing: 24
                rowSpacing: 10

                Repeater {
                    model: Object.keys(Icons.paths).sort()

                    Row {
                        id: cell
                        required property string modelData
                        spacing: 12

                        Text {
                            width: 96
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.modelData
                            color: "#8e8e93"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Glyph { width: 18; height: 18; name: cell.modelData; color: "#ffffff" }
                        Glyph { width: 40; height: 40; name: cell.modelData; color: "#ffffff" }
                        Item { width: 16; height: 1 }
                        GlyphLegacy { width: 18; height: 18; name: cell.modelData; color: "#ffffff" }
                        GlyphLegacy { width: 40; height: 40; name: cell.modelData; color: "#ffffff" }
                    }
                }
            }
        }
    }
}
