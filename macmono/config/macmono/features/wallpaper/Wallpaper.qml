import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property real openDrop: 24
    readonly property int wpPillTop: 52
    readonly property int wpPillHeight: 40
    readonly property int wpTrayHeight: 176
    readonly property int wpTrayMargin: 24
    readonly property int wpBadgeHeight: 18
    readonly property int wpChipHeight: 28
    readonly property int wpCloseDelay: 170
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bg
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.scrim
            WlrLayershell.namespace: "macmono:wallpaper"
            WlrLayershell.layer: WlrLayer.Background

            Item {
                id: wall
                anchors.fill: parent
                clip: true

                property bool frontA: true
                property bool fading: false
                property string frontPath: ""
                property int dir: 1
                property var incoming: null
                readonly property string wanted: Sys.wallpaper
                readonly property real dpr: bg.screen ? bg.screen.devicePixelRatio : 1

                function front() { return wall.frontA ? layerA : layerB; }
                function back() { return wall.frontA ? layerB : layerA; }

                // Completes a running crossfade at once and frees the old image.
                function finish() {
                    if (!wall.fading) return;
                    fade.stop();
                    wall.fading = false;
                    const old = wall.front();
                    const incoming = wall.back();
                    incoming.reveal = 1;
                    old.outgoing = false;
                    old.reveal = 0;
                    old.wallpaperPath = "";
                    wall.incoming = null;
                    wall.frontPath = incoming.wallpaperPath;
                    wall.frontA = !wall.frontA;
                }

                function present(layer) {
                    Sys.markWallpaperReady(layer.wallpaperPath, bg.modelData.name);
                    wall.front().z = 1;
                    layer.z = 2;
                    wall.front().outgoing = true;
                    layer.outgoing = false;
                    wall.incoming = layer;
                    wall.fading = true;
                    if (Sys.wallpaperOpen) {
                        layer.reveal = 1;
                        wall.finish();
                        return;
                    }
                    fade.target = layer;
                    fade.restart();
                }

                function load(path) {
                    wall.finish();
                    if (path === wall.frontPath) {
                        wall.back().wallpaperPath = "";
                        return;
                    }
                    if (path === "") {
                        wall.front().wallpaperPath = "";
                        wall.front().reveal = 0;
                        wall.frontPath = "";
                        return;
                    }
                    const list = Sys.wallpapers;
                    const a = list.indexOf(wall.frontPath), b = list.indexOf(path);
                    if (a >= 0 && b >= 0 && a !== b) {
                        let fwd = b > a;
                        if (Math.abs(b - a) > list.length / 2) fwd = !fwd;
                        wall.dir = fwd ? 1 : -1;
                    }
                    wall.back().wallpaperPath = path;
                }

                function layerLoaded(layer, path) {
                    if (wall.fading || layer !== wall.back() || path !== wall.wanted) return;
                    wall.present(layer);
                }

                onWantedChanged: wall.load(wall.wanted)
                Component.onCompleted: wall.load(wall.wanted)

                NumberAnimation {
                    id: fade
                    property: "reveal"
                    from: 0
                    to: 1
                    duration: Theme.wallpaperFadeMs
                    easing.type: Easing.Linear   // class C: curve shaped in WallMotion
                    onFinished: wall.finish()
                }

                // dim in the middle of the change
                Rectangle {
                    anchors.fill: parent
                    z: 3
                    color: "black"
                    opacity: wall.incoming ? Theme.wallDip * Math.sin(Math.PI * wall.incoming.reveal) : 0
                }

                WallLayer {
                    id: layerA
                    partner: layerB
                    dir: wall.dir
                    pixelWidth: Math.round(bg.width * wall.dpr)
                    pixelHeight: Math.round(bg.height * wall.dpr)
                    onLoaded: (path) => wall.layerLoaded(layerA, path)
                    onFailed: (path) => Sys.markWallpaperLoadError(path)
                }
                WallLayer {
                    id: layerB
                    partner: layerA
                    dir: wall.dir
                    pixelWidth: Math.round(bg.width * wall.dpr)
                    pixelHeight: Math.round(bg.height * wall.dpr)
                    onLoaded: (path) => wall.layerLoaded(layerB, path)
                    onFailed: (path) => Sys.markWallpaperLoadError(path)
                }
            }

        }
    }
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: picker
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.wallpaperOpen && Sys.wallpaperScreen === modelData.name

            readonly property real anim: reveal.progress
            property real uiOut: 0
            readonly property real ui: anim * (1 - uiOut)
            Reveal { id: reveal; open: picker.shown }
            Tween { id: keepAnim; target: picker; property: "uiOut"; from: 0; to: 1; easing.type: Theme.easeIn }
            Timer { id: closeTimer; interval: root.wpCloseDelay; onTriggered: Sys.wallpaperOpen = false }
            Timer {
                id: wallpaperReadyTimeout; interval: Settings.wallpaperReadyTimeoutMs
                onTriggered: {
                    if (Sys.wallpaperLoadError === "" && Sys.wallpaperReadyScreens.length > 0) picker.finishKeep();
                    else picker.failKeep();
                }
            }

            property string folder: ""
            property string selPath: ""
            property string previousWallpaper: ""
            property bool keeping: false
            property bool frontA: true
            property real wheelAcc: 0
            property real swapT: 1       // progres pergantian preview (linear 0..1)
            property int swapDir: 1
            onFrontAChanged: swapAnim.restart()
            NumberAnimation {
                id: swapAnim
                target: picker; property: "swapT"
                from: 0; to: 1
                duration: Theme.wallpaperFadeMs
                easing.type: Easing.Linear   // class C: curve shaped in WallMotion
            }

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
                swapDir = pics.indexOf(p) >= selIndex ? 1 : -1;
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
                    "Wallpaper failed to load", "Previous wallpaper restored. Check the image file you selected."]);
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
                    keepAnim.stop(); swapAnim.stop(); swapT = 1; closeTimer.stop(); wallpaperReadyTimeout.stop(); previewTimer.stop();
                    reveal.value = 0; reveal.velocity = 0; uiOut = 0; keeping = false; wheelAcc = 0;
                    return;
                }
                folder = "";
                selPath = Sys.wallpaper !== "" ? Sys.wallpaper : (Sys.wallpapers.length > 0 ? Sys.wallpapers[0] : "");
                frontA = true;
                imgB.source = "";
                imgA.source = selPath !== "" ? "file://" + selPath : "";
                swapAnim.stop(); swapT = 1;
                keys.forceActiveFocus();
                Qt.callLater(syncStrip);
            }

            Item {
                id: preview
                anchors.fill: parent
                opacity: picker.ui
                clip: true
                layer.enabled: Sys.wallpaperMono
                layer.effect: MultiEffect { saturation: -1.0 }

                WallMotion { id: swapMotion; t: picker.swapT; dir: picker.swapDir; span: picker.width }

                Rectangle { anchors.fill: parent; color: Theme.scrim }
                Image {
                    id: imgA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: picker.width
                    z: picker.frontA ? 2 : 1
                    opacity: picker.frontA ? swapMotion.inOpacity : 1
                    scale: picker.frontA ? swapMotion.inScale : swapMotion.outScale
                    transform: Translate { x: picker.frontA ? swapMotion.inX : swapMotion.outX }
                    onStatusChanged: if (status === Image.Ready && !picker.frontA) picker.frontA = true
                }
                Image {
                    id: imgB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: picker.width
                    z: picker.frontA ? 1 : 2
                    opacity: picker.frontA ? 1 : swapMotion.inOpacity
                    scale: picker.frontA ? swapMotion.outScale : swapMotion.inScale
                    transform: Translate { x: picker.frontA ? swapMotion.outX : swapMotion.inX }
                    onStatusChanged: if (status === Image.Ready && picker.frontA) picker.frontA = false
                }

                Rectangle { anchors.fill: parent; z: 5; color: "black"; opacity: swapMotion.dip }
            }

            MouseArea {
                anchors.fill: parent
                enabled: picker.shown
                onWheel: (wheel) => {
                    picker.wheelAcc += wheel.angleDelta.y;
                    if (picker.wheelAcc <= -120) { picker.wheelAcc = 0; picker.step(1); }
                    else if (picker.wheelAcc >= 120) { picker.wheelAcc = 0; picker.step(-1); }
                }
            }

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

            Rectangle {
                id: pill
                visible: picker.selPath !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.wpPillTop - root.openDrop * (1 - reveal.travel)
                width: pillRow.implicitWidth + Theme.space16 * 2
                height: root.wpPillHeight
                radius: Math.min(width, height) / 2
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                opacity: picker.ui

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: pillRow
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space16

                    Text {
                        Layout.maximumWidth: Settings.wallpaperPillTextMaxWidth
                        elide: Text.ElideMiddle
                        text: picker.baseOf(picker.selPath).replace(/\.[^.]+$/, "")
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold
                    }
                    Chip {
                        implicitHeight: root.wpChipHeight
                        label: "Cancel"
                        onTapped: Sys.wallpaperOpen = false
                    }
                    Chip {
                        implicitHeight: root.wpChipHeight
                        label: "Keep"
                        strong: true
                        onTapped: picker.keep()
                    }
                }
            }

            Rectangle {
                id: tray
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: root.wpTrayMargin
                anchors.rightMargin: root.wpTrayMargin
                anchors.bottomMargin: root.wpTrayMargin - root.wpTrayMargin * (1 - reveal.travel)
                height: root.wpTrayHeight
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                opacity: picker.ui

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.space16
                    anchors.bottomMargin: Theme.space16
                    anchors.leftMargin: Theme.space16
                    anchors.rightMargin: Theme.space16
                    spacing: Theme.space12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space16

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
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: picker.pics.length > 0
                            text: (picker.selIndex >= 0 ? (picker.selIndex + 1) + " of " : "") + picker.pics.length
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: Theme.fontSm
                            font.features: ({ "tnum": 1 })
                        }
                        Chip {
                            label: "Monochrome"
                            on: Sys.wallpaperMono
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
                                Behavior on width { Tween {} }

                                Item {
                                    id: frame
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: cell.picked ? 118 : 94
                                    Behavior on height { Tween {} }

                                    Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: Theme.tile }

                                    Image {
                                        id: thumb
                                        anchors.fill: parent
                                        visible: false
                                        property bool useOrig: false
                                        readonly property int ver: Sys.thumbsVersion
                                        onVerChanged: if (useOrig) useOrig = false
                                        source: useOrig ? "file://" + cell.modelData : "file://" + Sys.thumbFor(cell.modelData)
                                        onStatusChanged: if (status === Image.Error && !useOrig) useOrig = true
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 380
                                    }
                                    Rectangle { id: thumbMask; anchors.fill: parent; radius: Theme.radiusCard; visible: false; layer.enabled: true }
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
                                        Behavior on opacity { Tween { duration: Theme.durFast } }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusCard
                                        color: Theme.transparent
                                        border.width: cell.picked ? 2 : 1
                                        border.color: cell.picked ? Theme.text : Theme.line
                                    }
                                    Rectangle {
                                        visible: cell.live
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.margins: Theme.space8
                                        width: curText.implicitWidth + 12
                                        height: root.wpBadgeHeight
                                        radius: Math.min(width, height) / 2
                                        color: Theme.scrim
                                        Text {
                                            id: curText
                                            anchors.centerIn: parent
                                            text: "Current"
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightMedium
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
                    }
                }

                Text {
                    visible: picker.pics.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: "No images yet.\nPut wallpapers in ~/Pictures/Wallpapers"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontMd
                }
            }
        }
    }

    component Chip: Item {
        readonly property int wpChipDefaultHeight: 30
        id: chip
        property string label: ""
        property bool selected: false
        property bool strong: false
        property bool on: false
        signal tapped()
        readonly property bool underlined: selected || strong
        readonly property bool bright: underlined || on || chipArea.containsMouse
        implicitWidth: chipText.implicitWidth + 4
        implicitHeight: wpChipDefaultHeight
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.bright ? Theme.text : Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontSm
            font.weight: chip.strong ? Theme.weightSemibold : Theme.weightMedium
            Behavior on color { TweenColor { duration: Theme.durFast } }
        }
        Rectangle {
            anchors { left: chipText.left; right: chipText.right; top: chipText.bottom; topMargin: Theme.space2 }
            height: Theme.borderThin
            color: Theme.text
            visible: chip.underlined
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.tapped()
        }
    }
}
