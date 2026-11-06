import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../core"
import "../components"

Scope {
    // ---------------- layer wallpaper (di belakang semua window) ----------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bg
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.canvas
            WlrLayershell.namespace: "macmono:wallpaper"
            WlrLayershell.layer: WlrLayer.Background

            Image {
                anchors.fill: parent
                visible: Sys.wallpaper !== ""
                property string wallpaperPath: Sys.wallpaper
                source: Sys.wallpaper !== "" ? "file://" + Sys.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                // Decode di resolusi fisik, bukan logis: pada fractional scaling
                // (scale 1.2) sourceSize = lebar logis membuat wallpaper ikut di-upscale
                // compositor sehingga terlihat sedikit lembut.
                sourceSize.width: Math.round(bg.width * (bg.screen ? bg.screen.devicePixelRatio : 1))
                sourceSize.height: Math.round(bg.height * (bg.screen ? bg.screen.devicePixelRatio : 1))
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                layer.enabled: Sys.wallpaperMono
                layer.effect: MultiEffect { saturation: -1.0 }
                onStatusChanged: {
                    if (status === Image.Ready) Sys.markWallpaperReady(wallpaperPath, bg.modelData.name);
                    else if (status === Image.Error) Sys.markWallpaperLoadError(wallpaperPath);
                }
            }

        }
    }
    // ---------------- picker wallpaper: filmstrip + live preview ----------------
    // Layar penuh menampilkan wallpaper yang sedang disorot (preview), strip thumbnail di bawah.
    // Wallpaper asli baru diganti saat Keep / Enter / double-click. Esc = batal (nggak ada yang berubah).
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: picker
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.wallpaperOpen && Sys.wallpaperScreen === modelData.name

            // animasi buka (preview + UI) dan fade-out UI waktu Keep
            property real anim: 0
            property real uiOut: 0
            readonly property real ui: anim * (1 - uiOut)
            NumberAnimation { id: openAnim; target: picker; property: "anim"; from: 0; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
            NumberAnimation { id: keepAnim; target: picker; property: "uiOut"; from: 0; to: 1; duration: Theme.animFade; easing.type: Theme.easeIn }
            Timer { id: closeTimer; interval: Theme.wpCloseDelay; onTriggered: Sys.wallpaperOpen = false }
            Timer {
                id: wallpaperReadyTimeout; interval: Settings.wallpaperReadyTimeoutMs
                // Ada layar yang belum lapor siap, tapi gambar sudah termuat di layar lain dan nggak error -> terima saja.
                onTriggered: {
                    if (Sys.wallpaperLoadError === "" && Sys.wallpaperReadyScreens.length > 0) picker.finishKeep();
                    else picker.failKeep();
                }
            }

            // state picker
            property string folder: ""        // "" = semua folder
            property string selPath: ""
            property string previousWallpaper: ""
            property bool keeping: false
            property bool frontA: true        // preview ping-pong: gambar baru dimuat di belakang, lalu crossfade
            property real wheelAcc: 0

            readonly property var folders: {
                const seen = {};
                const out = [];
                for (const p of Sys.wallpapers) {
                    const d = dirOf(p);
                    if (!seen[d]) { seen[d] = true; out.push(d); }
                }
                return out;
            }
            readonly property var pics: folder === "" ? Sys.wallpapers : Sys.wallpapers.filter(p => dirOf(p) === folder)
            readonly property int selIndex: pics.indexOf(selPath)

            function dirOf(p) { return p.substring(0, p.lastIndexOf("/")); }
            function baseOf(p) { return p.substring(p.lastIndexOf("/") + 1); }

            function select(p) {
                if (keeping) return;
                selPath = p;
                previewTimer.restart();
                keys.forceActiveFocus();
            }
            function step(d) {
                if (pics.length === 0) return;
                let i = selIndex;
                if (i < 0) i = d > 0 ? -1 : pics.length;
                i = Math.max(0, Math.min(pics.length - 1, i + d));
                if (pics[i] !== selPath) select(pics[i]);
            }
            function shuffle() {
                if (pics.length === 0) return;
                if (pics.length === 1) { select(pics[0]); return; }
                let p = selPath;
                while (p === selPath) p = pics[Math.floor(Math.random() * pics.length)];
                select(p);
            }
            function setFolder(f) {
                folder = f;
                if (pics.indexOf(selPath) < 0 && pics.length > 0) select(pics[0]);
                Qt.callLater(syncStrip);
            }
            function keep() {
                if (keeping) return;
                if (selPath === "") { Sys.wallpaperOpen = false; return; }
                keeping = true;
                previousWallpaper = Sys.wallpaper;
                const changed = selPath !== Sys.wallpaper;
                if (changed) {
                    Sys.wallpaper = selPath;
                    wallpaperReadyTimeout.restart();
                    if (Sys.wallpaperReady) finishKeep();
                    return;
                }
                finishKeep();
            }
            function finishKeep() {
                if (!keeping || Sys.wallpaper !== selPath) return;
                wallpaperReadyTimeout.stop();
                Sys.saveState("wallpaper", selPath);
                keeping = false;
                keepAnim.restart();
                closeTimer.restart();
            }
            function failKeep() {
                if (!keeping) return;
                wallpaperReadyTimeout.stop();
                keeping = false;
                keepAnim.stop();
                uiOut = 0;
                if (Sys.wallpaper === selPath) Sys.wallpaper = previousWallpaper;
                Quickshell.execDetached(["notify-send", "-a", "Wallpaper", "-u", "critical",
                    "Wallpaper gagal dimuat", "Wallpaper sebelumnya dipulihkan. Periksa file gambar yang dipilih."]);
            }
            function loadPreview() {
                const url = selPath !== "" ? "file://" + selPath : "";
                const front = frontA ? imgA : imgB;
                const back = frontA ? imgB : imgA;
                if (String(front.source) === url) return;
                if (String(back.source) === url && back.status === Image.Ready) { frontA = !frontA; return; }
                back.source = url;
            }
            function syncStrip() {
                strip.currentIndex = selIndex;
                if (selIndex >= 0) strip.positionViewAtIndex(selIndex, ListView.Center);
            }

            Timer { id: previewTimer; interval: Settings.wallpaperPreviewDebounceMs; onTriggered: picker.loadPreview() }
            onSelIndexChanged: strip.currentIndex = selIndex

            Connections {
                target: Sys
                // daftar wallpaper dimuat async waktu picker dibuka
                function onWallpapersChanged() {
                    if (!picker.shown) return;
                    if (picker.selPath === "" && Sys.wallpapers.length > 0) picker.select(Sys.wallpapers[0]);
                    Qt.callLater(picker.syncStrip);
                }
                function onWallpaperReadyChanged() {
                    if (picker.keeping && Sys.wallpaperReady) picker.finishKeep();
                }
                function onWallpaperLoadErrorChanged() {
                    if (picker.keeping && Sys.wallpaperLoadError === picker.selPath) picker.failKeep();
                }
            }

            // Buka: animasi di QML. Tutup: langsung hilang, sama seperti panel macmono lain.
            visible: shown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:wallpaper-picker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onShownChanged: {
                if (!shown) {
                    if (keeping && Sys.wallpaper === selPath) Sys.wallpaper = previousWallpaper;
                    openAnim.stop(); keepAnim.stop(); closeTimer.stop(); wallpaperReadyTimeout.stop(); previewTimer.stop();
                    anim = 0; uiOut = 0; keeping = false; wheelAcc = 0;
                    return;
                }
                folder = "";
                selPath = Sys.wallpaper !== "" ? Sys.wallpaper : (Sys.wallpapers.length > 0 ? Sys.wallpapers[0] : "");
                // preview langsung pakai gambar yang dipilih, tanpa crossfade
                frontA = true;
                imgB.source = "";
                imgA.source = selPath !== "" ? "file://" + selPath : "";
                openAnim.restart();
                keys.forceActiveFocus();
                Qt.callLater(syncStrip);
            }

            // ---------- preview layar penuh ----------
            Item {
                id: preview
                anchors.fill: parent
                opacity: picker.anim
                layer.enabled: Sys.wallpaperMono
                layer.effect: MultiEffect { saturation: -1.0 }

                Rectangle { anchors.fill: parent; color: Theme.canvas }
                Image {
                    id: imgA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: picker.width
                    opacity: picker.frontA ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                    onStatusChanged: if (status === Image.Ready && !picker.frontA) picker.frontA = true
                }
                Image {
                    id: imgB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: picker.width
                    opacity: picker.frontA ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                    onStatusChanged: if (status === Image.Ready && picker.frontA) picker.frontA = false
                }
            }

            // klik di area preview nggak ngapa-ngapain; scroll = ganti gambar
            MouseArea {
                anchors.fill: parent
                enabled: picker.shown
                onWheel: (wheel) => {
                    picker.wheelAcc += wheel.angleDelta.y;
                    if (picker.wheelAcc <= -120) { picker.wheelAcc = 0; picker.step(1); }
                    else if (picker.wheelAcc >= 120) { picker.wheelAcc = 0; picker.step(-1); }
                }
            }

            // ---------- keyboard ----------
            Item {
                id: keys
                focus: true
                anchors.fill: parent
                Keys.onPressed: (e) => {
                    switch (e.key) {
                    case Qt.Key_Escape: Sys.wallpaperOpen = false; break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:  picker.keep(); break;
                    case Qt.Key_Left:
                    case Qt.Key_H:      picker.step(-1); break;
                    case Qt.Key_Right:
                    case Qt.Key_L:      picker.step(1); break;
                    case Qt.Key_Home:   if (picker.pics.length) picker.select(picker.pics[0]); break;
                    case Qt.Key_End:    if (picker.pics.length) picker.select(picker.pics[picker.pics.length - 1]); break;
                    case Qt.Key_R:      picker.shuffle(); break;
                    case Qt.Key_M:      Sys.setWallpaperMono(!Sys.wallpaperMono); break;
                    default: return;
                    }
                    e.accepted = true;
                }
            }

            // ---------- pill atas: nama + Keep ----------
            Rectangle {
                id: pill
                visible: picker.selPath !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.wpPillTop - Theme.openDrop * (1 - picker.anim)
                width: pillRow.implicitWidth + 22
                height: Theme.wpPillHeight
                radius: Math.min(width, height) / 2
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.lineStrong
                opacity: picker.ui

                MouseArea { anchors.fill: parent }   // jangan tembus

                RowLayout {
                    id: pillRow
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space10

                    Text {
                        Layout.maximumWidth: Settings.wallpaperPillTextMaxWidth
                        elide: Text.ElideMiddle
                        text: picker.baseOf(picker.selPath)
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.DemiBold
                    }
                    Text {
                        text: picker.selPath === Sys.wallpaper ? "Current wallpaper · Esc to close"
                                                               : "Previewing · ↵ to keep, Esc to revert"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                    }
                    Chip {
                        implicitHeight: Theme.wpChipHeight
                        label: "Cancel"
                        onTapped: Sys.wallpaperOpen = false
                    }
                    Chip {
                        implicitHeight: Theme.wpChipHeight
                        label: "Keep"
                        strong: true
                        onTapped: picker.keep()
                    }
                }
            }

            // ---------- tray bawah: filter + filmstrip ----------
            Rectangle {
                id: tray
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Theme.wpTrayMargin
                anchors.rightMargin: Theme.wpTrayMargin
                anchors.bottomMargin: Theme.wpTrayMargin - Theme.wpTrayMargin * (1 - picker.anim)
                height: Theme.wpTrayHeight
                radius: Theme.radiusXl
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.lineStrong
                opacity: picker.ui

                MouseArea { anchors.fill: parent }   // jangan tembus ke preview

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.space14
                    anchors.bottomMargin: Theme.space14
                    anchors.leftMargin: Theme.space16
                    anchors.rightMargin: Theme.space16
                    spacing: Theme.space12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space8

                        Chip {
                            label: "All"
                            selected: picker.folder === ""
                            onTapped: picker.setFolder("")
                        }
                        Repeater {
                            model: picker.folders.length > 1 ? picker.folders.slice(0, 6) : []
                            delegate: Chip {
                                required property string modelData
                                label: picker.baseOf(modelData)
                                selected: picker.folder === modelData
                                onTapped: picker.setFolder(modelData)
                            }
                        }
                        Text {
                            Layout.leftMargin: Theme.space6
                            visible: picker.pics.length > 0
                            text: (picker.selIndex >= 0 ? (picker.selIndex + 1) + " of " : "") + picker.pics.length
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                            font.features: ({ "tnum": 1 })
                        }
                        Item { Layout.fillWidth: true }
                        Chip {
                            label: "Monochrome · " + (Sys.wallpaperMono ? "On" : "Off")
                            onTapped: Sys.setWallpaperMono(!Sys.wallpaperMono)
                        }
                        Chip {
                            label: "Shuffle"
                            onTapped: picker.shuffle()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.space12

                        RoundBtn { turn: 90; onTapped: picker.step(-1) }

                        ListView {
                            id: strip
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            orientation: ListView.Horizontal
                            spacing: Theme.space12
                            clip: true
                            model: picker.pics
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: 800
                            highlightRangeMode: ListView.ApplyRange
                            preferredHighlightBegin: width / 2 - 95
                            preferredHighlightEnd: width / 2 + 95
                            highlightMoveDuration: 220

                            delegate: Item {
                                id: cell
                                required property string modelData
                                readonly property bool picked: modelData === picker.selPath
                                readonly property bool live: modelData === Sys.wallpaper
                                width: picked ? 190 : 150
                                height: ListView.view.height
                                Behavior on width { NumberAnimation { duration: Theme.animFade; easing.type: Theme.easeOut } }

                                Item {
                                    id: frame
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: cell.picked ? 118 : 94
                                    Behavior on height { NumberAnimation { duration: Theme.animFade; easing.type: Theme.easeOut } }

                                    Rectangle { anchors.fill: parent; radius: Theme.radiusMedium; color: Theme.tile }

                                    Image {
                                        id: thumb
                                        anchors.fill: parent
                                        visible: false
                                        // thumbnail dari cache dulu; kalau belum ada, pakai file aslinya
                                        property bool useOrig: false
                                        readonly property int ver: Sys.thumbsVersion
                                        onVerChanged: if (useOrig) useOrig = false
                                        source: useOrig ? "file://" + cell.modelData : "file://" + Sys.thumbFor(cell.modelData)
                                        onStatusChanged: if (status === Image.Error && !useOrig) useOrig = true
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 380
                                    }
                                    Rectangle { id: thumbMask; anchors.fill: parent; radius: Theme.radiusMedium; visible: false; layer.enabled: true }
                                    MultiEffect {
                                        anchors.fill: parent
                                        visible: thumb.status === Image.Ready
                                        source: thumb
                                        saturation: Sys.wallpaperMono ? -1.0 : 0.0
                                        maskEnabled: true
                                        maskSource: thumbMask
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1.0
                                        opacity: (cell.picked || cellArea.containsMouse) ? 1.0 : Theme.opacityDim
                                        Behavior on opacity { NumberAnimation { duration: Theme.animHover } }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusMedium
                                        color: Theme.transparent
                                        border.width: cell.picked ? 2 : 1
                                        border.color: cell.picked ? Theme.text : Theme.line
                                    }
                                    // label kecil "Current" di wallpaper yang sedang dipakai
                                    Rectangle {
                                        visible: cell.live
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.margins: Theme.space7
                                        width: curText.implicitWidth + 12
                                        height: Theme.wpBadgeHeight
                                        radius: Math.min(width, height) / 2
                                        color: Theme.badge
                                        Text {
                                            id: curText
                                            anchors.centerIn: parent
                                            text: "Current"
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontCaption; font.weight: Font.Medium
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cellArea
                                    anchors.fill: frame
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: picker.select(cell.modelData)
                                    onDoubleClicked: { picker.select(cell.modelData); picker.keep(); }
                                }
                            }
                        }

                        RoundBtn { turn: -90; onTapped: picker.step(1) }
                    }
                }

                // pesan kalau kosong
                Text {
                    visible: picker.pics.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: "No images yet.\nPut wallpapers in ~/Pictures/Wallpapers"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                }
            }
        }
    }

    // ---------------- komponen kecil ----------------
    // tombol pill (chip filter, Cancel, Keep)
    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        property bool strong: false      // tombol putih (Keep)
        signal tapped()
        readonly property bool light: selected || strong
        implicitWidth: chipText.implicitWidth + 28
        implicitHeight: Theme.wpChipDefaultHeight
        radius: height / 2
        color: light ? (chipArea.containsMouse ? Theme.inverseHover : Theme.inverse)
                     : (chipArea.containsMouse ? Theme.tileHover : Theme.tile)
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.light ? Theme.inverseText : Theme.text
            font.family: Theme.font; font.pixelSize: Theme.fontBody
            font.weight: chip.strong ? Font.DemiBold : Font.Medium
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.tapped()
        }
    }

    // tombol bulat prev/next (chevron diputar)
    component RoundBtn: Rectangle {
        id: rb
        property real turn: 0
        signal tapped()
        implicitWidth: Theme.wpRoundButton
        implicitHeight: Theme.wpRoundButton
        radius: Math.min(width, height) / 2
        color: rbArea.containsMouse ? Theme.tileHover : Theme.tile
        scale: rbArea.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animPress } }
        Glyph {
            anchors.centerIn: parent
            width: Theme.icon16; height: Theme.icon16
            name: "chevron"
            color: Theme.text
            rotation: rb.turn
        }
        MouseArea {
            id: rbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.tapped()
        }
    }
}
