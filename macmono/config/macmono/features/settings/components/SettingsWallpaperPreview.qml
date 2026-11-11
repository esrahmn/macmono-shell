import QtQuick
import "../../../core"
import "../../../shared/components"

Column {
    id: root

    readonly property int settingsHeroHeight: 220
    readonly property int settingsHeroScrimHeight: 84
    readonly property color settingsScrim: Qt.rgba(0, 0, 0, 0.65)
    readonly property int settingsThumbMin: 150
    readonly property real settingsThumbRatio: 0.5625
    readonly property int settingsThumbMax: 12
    readonly property int settingsHoverPreviewMs: 140
    spacing: SettingsMetrics.settingsGroupSpacing

    property var shown: []
    function rebuild() {
        const cur = Sys.wallpaper;
        const rest = Sys.wallpapers.filter(p => p !== cur);
        const list = cur === "" ? rest : [cur].concat(rest);
        shown = list.slice(0, root.settingsThumbMax);
    }
    Connections { target: Sys; function onWallpapersChanged() { root.rebuild(); } }
    readonly property int cols: Math.max(2, Math.floor((width + Theme.space12) / (root.settingsThumbMin + Theme.space12)))
    readonly property real cellW: (width - Theme.space12 * (cols - 1)) / cols

    function nameOf(p) { return String(p).split("/").pop(); }

    property string hoverPath: ""
    property string pendingHover: ""
    readonly property string heroPath: hoverPath !== "" ? hoverPath : Sys.wallpaper
    readonly property bool previewing: hoverPath !== "" && hoverPath !== Sys.wallpaper
    function hoverOn(p) { pendingHover = p; hoverTimer.restart(); }
    function hoverOff() { pendingHover = ""; hoverTimer.restart(); }
    Timer { id: hoverTimer; interval: root.settingsHoverPreviewMs; onTriggered: root.hoverPath = root.pendingHover }

    onVisibleChanged: {
        if (visible) { Sys.loadWallpapers(); rebuild(); }
        else { hoverTimer.stop(); pendingHover = ""; hoverPath = ""; }
    }
    Component.onCompleted: rebuild()

    component Caption: SettingsText {
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
        leftPadding: SettingsMetrics.settingsRowPadX
    }

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: root.previewing ? "PREVIEW" : "CURRENT WALLPAPER" }

        Item {
            width: parent.width
            height: root.settingsHeroHeight

            SettingsWallpaperImage { anchors.fill: parent; path: root.heroPath; thumb: root.previewing; cornerRadius: Theme.radiusCard }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: root.settingsHeroScrimHeight
                radius: Theme.radiusCard
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.transparent }
                    GradientStop { position: 1.0; color: root.settingsScrim }
                }
            }
            SettingsText {
                anchors { left: parent.left; leftMargin: Theme.space16; right: randomBtn.left; rightMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space16 }
                text: root.heroPath === "" ? "No wallpaper set" : root.nameOf(root.heroPath)
                elide: Text.ElideMiddle
                font.weight: Theme.weightSemibold
            }
            SettingsButton {
                id: randomBtn
                anchors { right: parent.right; rightMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space8 }
                label: "Random"
                onClicked: Sys.randomWallpaper()
            }
            Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: Theme.transparent; border.width: Theme.borderThin; border.color: Theme.line }
        }

        Rectangle {
            width: parent.width
            height: monoCol.height + SettingsMetrics.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.line

            Column {
                id: monoCol
                anchors { left: parent.left; leftMargin: SettingsMetrics.settingsRowPadX; right: monoToggle.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                spacing: Theme.space2
                SettingsText { text: "Black and white"; font.weight: Theme.weightSemibold }
                SettingsText { width: parent.width; text: "Show wallpapers in grayscale to match the MacMono look."; color: SettingsMetrics.settingsDescText; font.pixelSize: Theme.fontSm; wrapMode: Text.WordWrap }
            }
            SettingsToggle {
                id: monoToggle
                anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
                checked: Sys.wallpaperMono
                onToggled: value => Sys.setWallpaperMono(value)
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: "CHOOSE ONE" }

        SettingsText {
            visible: root.shown.length === 0
            leftPadding: SettingsMetrics.settingsRowPadX
            text: "No wallpapers found. Add a folder below."
            color: Theme.dim
            font.pixelSize: Theme.fontSm
        }

        Grid {
            columns: root.cols
            spacing: Theme.space12

            Repeater {
                model: root.shown

                delegate: Item {
                    id: cell
                    required property string modelData
                    readonly property bool picked: modelData === Sys.wallpaper
                    width: root.cellW
                    height: root.cellW * root.settingsThumbRatio
                    activeFocusOnTab: true
                    onActiveFocusChanged: { if (activeFocus) root.hoverOn(modelData); else root.hoverOff(); }
                    Keys.onReturnPressed: Sys.setWallpaper(modelData)
                    Keys.onSpacePressed: Sys.setWallpaper(modelData)

                    SettingsWallpaperImage {
                        anchors.fill: parent
                        path: cell.modelData
                        thumb: true
                        cornerRadius: Theme.radiusCard
                        opacity: (cell.picked || area.containsMouse || cell.activeFocus) ? 1.0 : Theme.opacityDim
                        Behavior on opacity { Tween { duration: Theme.durFast } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: Theme.transparent
                        border.width: cell.picked ? Theme.borderStrong : Theme.borderThin
                        border.color: cell.picked ? Theme.text : Theme.line
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOn(cell.modelData)
                        onExited: root.hoverOff()
                        onClicked: Sys.setWallpaper(cell.modelData)
                    }
                }
            }
        }

        Row {
            visible: Sys.wallpapers.length > root.settingsThumbMax
            x: SettingsMetrics.settingsRowPadX
            spacing: Theme.space12
            SettingsText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Showing " + root.settingsThumbMax + " of " + Sys.wallpapers.length
                color: Theme.dim
                font.pixelSize: Theme.fontSm
            }
            SettingsButton {
                label: "See all"
                onClicked: { Sys.settingsOpen = false; Sys.openWallpaper(); }
            }
        }
    }
}
