import QtQuick
import "../../../core"

// Bagian atas halaman Wallpaper: wallpaper sekarang (besar), saklar hitam-putih, dan grid pilihan.
// Semua langsung berlaku (tanpa Apply), lewat Sys.setWallpaper / Sys.setWallpaperMono.
Column {
    id: root
    spacing: Theme.settingsGroupSpacing

    // Wallpaper aktif ditaruh paling depan. Urutan dihitung saat halaman dibuka / daftar berubah,
    // bukan tiap klik, supaya grid tidak loncat di bawah kursor.
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

    // Pratinjau hover: kursor (atau fokus keyboard) di thumbnail menampilkannya di kartu atas tanpa menerapkan.
    // Diberi jeda kecil: kursor yang cuma lewat tidak bikin kartu kedip, dan pindah dari satu thumbnail
    // ke thumbnail sebelahnya tidak sempat balik ke wallpaper sekarang.
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

    // ---- wallpaper sekarang ----
    Column {
        width: parent.width
        spacing: Theme.space8
        Caption { text: root.previewing ? "PREVIEW" : "CURRENT WALLPAPER" }

        Item {
            width: parent.width
            height: Theme.settingsHeroHeight

            // Saat pratinjau, hero memakai thumbnail yang sama dengan grid (sudah ada di cache, jadi muncul
            // seketika tanpa kedip). Begitu dipilih / kursor pergi, balik ke gambar penuh.
            SettingsWallpaperImage { anchors.fill: parent; path: root.heroPath; thumb: root.previewing; cornerRadius: Theme.radius }

            // Bayangan tipis di bawah supaya nama file terbaca di atas gambar terang
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

        // Saklar hitam-putih
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

    // ---- grid pilihan ----
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
                // Settings ditutup dulu supaya dua panel tidak bertumpuk.
                onClicked: { Sys.settingsOpen = false; Sys.openWallpaper(); }
            }
        }
    }
}
