import QtQuick
import QtQuick.Effects
import "../../../core"

Item {
    id: root

    readonly property int settingsPreviewSourceWidth: 960
    readonly property int settingsThumbSourceWidth: 380
    property string path: ""
    property bool thumb: false
    property int cornerRadius: Theme.radiusCard
    property bool useOrig: false
    readonly property bool ready: img.status === Image.Ready

    onPathChanged: useOrig = false

    Image {
        id: img
        anchors.fill: parent
        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.thumb ? root.settingsThumbSourceWidth : root.settingsPreviewSourceWidth
        source: root.path === "" ? "" : "file://" + ((root.thumb && !root.useOrig) ? Sys.thumbFor(root.path) : root.path)
        onStatusChanged: if (status === Image.Error && root.thumb && !root.useOrig) root.useOrig = true
    }

    Rectangle { id: mask; anchors.fill: parent; radius: root.cornerRadius; visible: false; layer.enabled: true }

    MultiEffect {
        anchors.fill: parent
        visible: img.status === Image.Ready
        source: img
        saturation: Sys.wallpaperMono ? -1.0 : 0.0
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle { anchors.fill: parent; radius: root.cornerRadius; color: Theme.tile; visible: img.status !== Image.Ready; z: -1 }
}
