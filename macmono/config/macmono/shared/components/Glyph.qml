import QtQuick
import QtQuick.Shapes
import "../../core"
import "GlyphPaths.js" as Icons

// Icon. Same API as before (name, color, thickness, size).
// Icons found in GlyphPaths.js are vector paths drawn by the GPU: changing the color
// only changes a value, nothing is redrawn into an image. Icons that are not there yet
// fall back to the old canvas drawing (GlyphLegacy.qml), so migrating is gradual.
// Update the data with scripts/development/fetch-icons.py.
Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property real thickness: 1.8

    implicitWidth: Theme.iconMd
    implicitHeight: Theme.iconMd

    readonly property var icon: Icons.paths[name] ?? null
    readonly property bool hasStroke: icon !== null && icon.mode !== "fill"
    readonly property bool hasFill: icon !== null && icon.mode !== "stroke"

    Shape {
        visible: root.icon !== null
        width: root.icon ? root.icon.w : 1
        height: width
        // The paths live in their own grid (usually 24): scale that grid to the item.
        scale: Math.min(root.width, root.height) / width
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.hasStroke ? root.color : "transparent"
            strokeWidth: root.hasStroke ? root.thickness : -1
            fillColor: root.hasFill ? root.color : "transparent"
            fillRule: ShapePath.WindingFill
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.icon ? root.icon.d : "" }
        }
    }

    Loader {
        active: root.icon === null
        anchors.fill: parent
        sourceComponent: Component {
            GlyphLegacy {
                anchors.fill: parent
                name: root.name
                color: root.color
                thickness: root.thickness
            }
        }
    }
}
