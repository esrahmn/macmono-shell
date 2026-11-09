import QtQuick
import "../../../core"

Column {
    id: root
    spacing: Theme.settingsGroupSpacing

    property var shown: []
    function rebuild() {
        const cur = Sys.wallpaper;
        const rest = Sys.wallpapers.filter(p => p !== cur);
        const list = cur === "" ? rest : [cur].concat(rest);
        shown = list.slice(0, Theme.settingsThumbMax);
    }
    Connections { target: Sys; function onWallpapersChanged() { root.rebuild(); } }
    readonly property int cols: Math.max(2, Math.floor((width + Theme.space10) / (Theme.settingsThumbMin + Theme.space10)))
    readonly property real cellW: (width - Theme.space10 * (cols - 1)) / cols

    function nameOf(p) { return String(p).split("/").pop(); }

    property string hoverPath: ""
    property string pendingHover: ""
    readonly property string heroPath: hoverPath !== "" ? hoverPath : Sys.wallpaper
    readonly property bool previewing: hoverPath !== "" && hoverPath !== Sys.wallpaper
    function hoverOn(p) { pendingHover = p; hoverTimer.restart(); }
    function hoverOff() { pendingHover = ""; hoverTimer.restart(); }
    Timer { id: hoverTimer; interval: Theme.settingsHoverPreviewMs; onTriggered: root.hoverPath = root.pendingHover }

    onVisibleChanged: {
        if (visible) { Sys.loadWallpapers(); rebuild(); }
        else { hoverTimer.stop(); pendingHover = ""; hoverPath = ""; }
    }
    Component.onCompleted: rebuild()

    component Caption: SettingsText {
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }

    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: root.previewing ? "PREVIEW" : "CURRENT WALLPAPER" }

        Item {
            width: parent.width
            height: Theme.settingsHeroHeight

            SettingsWallpaperImage { anchors.fill: parent; path: root.heroPath; thumb: root.previewing; cornerRadius: Theme.radius }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Theme.settingsHeroScrimHeight
                radius: Theme.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.transparent }
                    GradientStop { position: 1.0; color: Theme.settingsScrim }
                }
            }
            SettingsText {
                anchors { left: parent.left; leftMargin: Theme.space16; right: randomBtn.left; rightMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space14 }
                text: root.heroPath === "" ? "No wallpaper set" : root.nameOf(root.heroPath)
                elide: Text.ElideMiddle
                font.weight: Font.DemiBold
            }
            SettingsButton {
                id: randomBtn
                anchors { right: parent.right; rightMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space8 }
                label: "Random"
                onClicked: Sys.randomWallpaper()
            }
            Rectangle { anchors.fill: parent; radius: Theme.radius; color: Theme.transparent; border.width: Theme.borderThin; border.color: Theme.cardStroke }
        }

        Rectangle {
            width: parent.width
            height: monoCol.height + Theme.settingsRowPadY * 2
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: Theme.cardStroke

            Column {
                id: monoCol
                anchors { left: parent.left; leftMargin: Theme.settingsRowPadX; right: monoToggle.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                spacing: Theme.space2
                SettingsText { text: "Black and white"; font.weight: Font.DemiBold }
                SettingsText { width: parent.width; text: "Show wallpapers in grayscale to match the MacMono look."; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody; wrapMode: Text.WordWrap }
            }
            SettingsToggle {
                id: monoToggle
                anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
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
            leftPadding: Theme.settingsRowPadX
            text: "No wallpapers found. Add a folder below."
            color: Theme.dim
            font.pixelSize: Theme.fontBody
        }

        Grid {
            columns: root.cols
            spacing: Theme.space10

            Repeater {
                model: root.shown

                delegate: Item {
                    id: cell
                    required property string modelData
                    readonly property bool picked: modelData === Sys.wallpaper
                    width: root.cellW
                    height: root.cellW * Theme.settingsThumbRatio
                    activeFocusOnTab: true
                    onActiveFocusChanged: { if (activeFocus) root.hoverOn(modelData); else root.hoverOff(); }
                    Keys.onReturnPressed: Sys.setWallpaper(modelData)
                    Keys.onSpacePressed: Sys.setWallpaper(modelData)

                    SettingsWallpaperImage {
                        anchors.fill: parent
                        path: cell.modelData
                        thumb: true
                        cornerRadius: Theme.radiusMedium
                        opacity: (cell.picked || area.containsMouse || cell.activeFocus) ? 1.0 : Theme.opacityDim
                        Behavior on opacity { NumberAnimation { duration: Theme.animHover } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusMedium
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
            visible: Sys.wallpapers.length > Theme.settingsThumbMax
            x: Theme.settingsRowPadX
            spacing: Theme.space12
            SettingsText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Showing " + Theme.settingsThumbMax + " of " + Sys.wallpapers.length
                color: Theme.dim
                font.pixelSize: Theme.fontBody
            }
            SettingsButton {
                label: "See all"
                onClicked: { Sys.settingsOpen = false; Sys.openWallpaper(); }
            }
        }
    }
}
