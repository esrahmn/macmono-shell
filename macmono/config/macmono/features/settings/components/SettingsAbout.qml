import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../../../core"
import "../../../shared/components"

Column {
    id: root

    readonly property int aboutContentMax: 640
    readonly property int aboutHeroGap: 36
    readonly property int aboutLaptopWidth: 260
    readonly property int aboutLaptopHeight: 162
    readonly property int aboutLaptopBaseWidth: 288
    readonly property int aboutLaptopBaseHeight: 11
    readonly property int aboutLaptopCutoutWidth: 44
    readonly property int aboutLaptopCutoutHeight: 7
    readonly property int aboutLaptopNotch: 60
    readonly property int aboutLaptopNotchDepth: 3
    readonly property int aboutNameSize: 24
    readonly property real aboutNameTracking: -0.5
    readonly property int aboutStatValueSize: 18
    readonly property int aboutStatGapX: 40
    readonly property int aboutStatGapY: 20
    readonly property int aboutStatPad: 12
    readonly property int aboutLayerHeight: 40
    readonly property int aboutLayerGap: 6
    readonly property int aboutLayerGrowX: 10
    readonly property int aboutLayerGrowY: 4
    readonly property color aboutLayerHoverFill: Qt.rgba(1, 1, 1, 0.30)
    readonly property color aboutLayerHoverStroke: Qt.rgba(1, 1, 1, 0.34)
    readonly property int aboutStatBar: 6
    spacing: 0

    readonly property var d: Sys.systemDetails
    property int tick: 0
    property bool copied: false

    onVisibleChanged: if (visible) Sys.loadSystemDetails()
    Timer { interval: 30000; repeat: true; running: root.visible && Sys.settingsOpen; onTriggered: root.tick++ }
    Timer { id: copiedTimer; interval: 1600; onTriggered: root.copied = false }


    function clean(s) { return String(s ?? "").trim(); }
    function junk(s) { return /o\.e\.m|default string|system (manufacturer|product)|not specified|^none$/i.test(s); }

    readonly property string computerName: {
        const v = junk(clean(d.vendor)) ? "" : clean(d.vendor);
        const p = junk(clean(d.product)) ? "" : clean(d.product);
        if (p === "") return Sys.osName;
        return (v === "" || p.toLowerCase().indexOf(v.toLowerCase()) === 0) ? p : v + " " + p;
    }

    readonly property string cpuName: clean(d.cpu).replace(/\((R|TM)\)/g, "").replace(/\s+with .*Graphics/i, "").replace(/\s+\d+-Core Processor/i, "").replace(/\s+/g, " ").trim()

    readonly property int cpuThreads: {
        const t = parseInt(d.threads);
        return t > 0 ? t : 0;
    }

    readonly property int cpuCores: {
        const c = parseInt(d.cores);
        return c > 0 ? c : 0;
    }

    readonly property string cpuSub: cpuCores > 0 && cpuThreads > 0 ? cpuCores + " cores · " + cpuThreads + " threads"
                                   : cpuThreads > 0 ? cpuThreads + " threads" : ""

    readonly property string processor: cpuName === "" ? "" : (cpuSub !== "" ? cpuName + " · " + cpuSub : cpuName)

    readonly property string gpuRaw: clean(d.gpu)
        .replace("Advanced Micro Devices, Inc. [AMD/ATI]", "AMD")
        .replace("NVIDIA Corporation", "NVIDIA")
        .replace("Intel Corporation", "Intel")

    readonly property string gpuVendor: {
        const m = gpuRaw.match(/^(AMD|NVIDIA|Intel)\b/);
        return m ? m[1] : "";
    }

    readonly property string graphics: {
        if (gpuRaw === "") return "";
        const m = gpuRaw.match(/\[([^\]]+)\]/);
        if (m && gpuVendor !== "") return gpuVendor + " " + m[1];
        if (gpuVendor === "AMD") return "AMD Radeon Graphics";
        if (gpuVendor === "Intel") return "Intel Graphics";
        return gpuRaw;
    }

    readonly property bool gpuIntegrated: {
        if (gpuVendor === "NVIDIA") return false;
        if (gpuVendor === "Intel") return !/\barc\b|\bDG[12]\b|alchemist|battlemage/i.test(gpuRaw);
        if (gpuVendor === "AMD") return /radeon/i.test(clean(d.cpu)) && !/\bRX\b|\bpro\b/i.test(gpuRaw);
        return false;
    }

    readonly property string graphicsSub: {
        if (graphics === "") return "";
        if (gpuIntegrated) return "Integrated · shares system memory";
        const gb = Math.round((Number(d.gpuvram) || 0) / 1073741824);
        return gb > 0 ? "Discrete · " + gb + " GB" : "Discrete";
    }

    readonly property real memUsableGb: {
        const kb = parseInt(d.memkb);
        return kb > 0 ? kb / 1048576 : 0;
    }

    readonly property int memInstalledGb: {
        if (memUsableGb <= 0) return 0;
        for (const s of [2, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512])
            if (s >= memUsableGb) return s;
        return Math.ceil(memUsableGb);
    }

    readonly property string memory: memInstalledGb > 0 ? memInstalledGb + " GB" : ""
    readonly property string memorySub: memInstalledGb > 0 && Math.round(memUsableGb) !== memInstalledGb ? Math.round(memUsableGb) + " GB usable" : ""

    readonly property var diskParts: clean(d.disk).split(" ")
    readonly property real diskTotalKb: parseInt(diskParts[0]) || 0
    readonly property real diskUsedKb: parseInt(diskParts[1]) || 0
    function diskGb(kb) { return Math.round(kb * 1024 / 1e9); }

    readonly property real storageRatio: diskTotalKb > 0 ? Math.min(1, diskUsedKb / diskTotalKb) : -1
    readonly property string storageTotal: diskTotalKb > 0 ? diskGb(diskTotalKb) + " GB" : ""
    readonly property string storageSub: diskTotalKb > 0 ? diskGb(diskUsedKb) + " GB used · " + Math.round(storageRatio * 100) + "%" : ""
    readonly property string storage: diskTotalKb > 0 ? diskGb(diskUsedKb) + " GB used of " + diskGb(diskTotalKb) + " GB" : ""

    readonly property string hyprVersion: {
        const m = clean(d.hypr).match(/Hyprland\s+v?([0-9][^\s,]*)/);
        return m ? m[1] : "";
    }

    readonly property string qsVersion: {
        const m = clean(d.qs).match(/quickshell\s+v?([0-9][^\s,]*)/i);
        return m ? m[1] : "";
    }

    readonly property string desktop: hyprVersion !== "" ? "Hyprland " + hyprVersion : (clean(d.hypr) !== "" ? "Hyprland" : "")

    readonly property string shell: qsVersion !== "" ? "MacMono on Quickshell " + qsVersion : "MacMono"

    function uptimeText(tickValue) {
        const s = Math.max(0, Math.floor(Number(Sys.uptimeSeconds()) || 0));
        const days = Math.floor(s / 86400), hours = Math.floor((s % 86400) / 3600), minutes = Math.floor((s % 3600) / 60);
        const plural = (n, u) => n + " " + u + (n === 1 ? "" : "s");
        if (days > 0) return plural(days, "day") + ", " + plural(hours, "hour");
        if (hours > 0) return minutes > 0 ? plural(hours, "hour") + ", " + plural(minutes, "minute") : plural(hours, "hour");
        if (minutes > 0) return plural(minutes, "minute");
        return "less than a minute";
    }

    readonly property var statCells: [
        { label: "Processor", value: cpuName, sub: cpuSub, ratio: -1 },
        { label: "Graphics", value: graphics, sub: graphicsSub, ratio: -1 },
        { label: "Memory", value: memory, sub: memorySub, ratio: -1 },
        { label: "Storage", value: storageTotal, sub: storageSub, ratio: storageRatio }
    ].filter(c => c.value !== "")

    readonly property var layers: [
        { name: "MacMono", value: "Shell", copy: shell },
        { name: "Quickshell", value: qsVersion, copy: "Quickshell " + qsVersion },
        { name: "Hyprland", value: hyprVersion, copy: "Hyprland " + hyprVersion },
        { name: String(Sys.osName ?? ""), value: clean(Sys.kernelVersion) !== "" ? "Linux " + clean(Sys.kernelVersion) : "",
          copy: String(Sys.osName ?? "") + ", Linux " + clean(Sys.kernelVersion) }
    ].filter(l => l.name !== "" && (l.name === "MacMono" || l.value !== ""))

    readonly property var hardwareRows: [
        { label: "Processor", value: processor },
        { label: "Graphics", value: graphics },
        { label: "Memory", value: memory + (memorySub !== "" ? " (" + memorySub + ")" : "") },
        { label: "Storage", value: storage }
    ].filter(r => r.value !== "")

    readonly property var softwareRows: [
        { label: "System", value: Sys.osName },
        { label: "Kernel", value: Sys.kernelVersion },
        { label: "Desktop", value: desktop },
        { label: "Shell", value: shell }
    ].filter(r => r.value !== "")

    function report() {
        const lines = [computerName, ""];
        for (const r of hardwareRows) lines.push(r.label + ": " + r.value);
        for (const r of softwareRows) lines.push(r.label + ": " + r.value);
        lines.push("Uptime: " + uptimeText(tick));
        return lines.join("\n");
    }

    function copyInfo() {
        copyProc.stdinEnabled = true;
        copyProc.running = true;
        copied = true;
        copiedTimer.restart();
    }

    property int copiedLayer: -1
    Timer { id: layerCopiedTimer; interval: 1400; onTriggered: root.copiedLayer = -1 }
    Process {
        id: layerCopy
        property string text: ""
        command: ["wl-copy", "--", text]
    }
    function copyLayer(i, text) {
        layerCopy.text = text;
        layerCopy.running = true;
        copiedLayer = i;
        layerCopiedTimer.restart();
    }

    Process {
        id: copyProc
        command: ["wl-copy"]
        stdinEnabled: true
        onStarted: { write(root.report()); stdinEnabled = false; }
    }


    component SectionLabel: SettingsText {
        readonly property int aboutSectionGap: 32
        topPadding: aboutSectionGap
        bottomPadding: Theme.space12
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
    }

    component PillButton: Rectangle {
        id: pb
        property string label: ""
        property bool flat: false
        signal clicked()
        implicitWidth: pbText.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
        implicitHeight: SettingsMetrics.settingsButtonHeight
        radius: Theme.radiusControl
        color: flat ? (pbArea.containsMouse ? Theme.tile : Theme.transparent)
                    : (pbArea.containsMouse ? Theme.tileHover : Theme.tile)
        Behavior on color { TweenColor { duration: Theme.durFast } }
        SettingsText {
            id: pbText
            anchors.centerIn: parent
            text: pb.label
            color: pb.flat ? Theme.text : Theme.text
            font.weight: Theme.weightMedium
        }
        MouseArea {
            id: pbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
        Accessible.role: Accessible.Button
        Accessible.name: pb.label
    }


    Column {
        id: page
        x: SettingsMetrics.settingsRowPadX
        width: Math.min(root.aboutContentMax, root.width - SettingsMetrics.settingsRowPadX * 2)
        spacing: 0

        Item {
            id: hero
            width: page.width
            height: laptop.height

            Item {
                id: laptop
                width: root.aboutLaptopBaseWidth
                height: root.aboutLaptopHeight + root.aboutLaptopBaseHeight

                Item {
                    id: lid
                    x: (laptop.width - width) / 2
                    width: root.aboutLaptopWidth
                    height: root.aboutLaptopHeight

                    readonly property real lidTop: Theme.radiusCard
                    readonly property real lidBottom: Theme.space4
                    readonly property real screenTop: Math.max(0, lidTop - SettingsMetrics.aboutLaptopBezel)
                    readonly property real screenBottom: Theme.space2

                    Rectangle {
                        anchors.fill: parent
                        topLeftRadius: lid.lidTop
                        topRightRadius: lid.lidTop
                        bottomLeftRadius: lid.lidBottom
                        bottomRightRadius: lid.lidBottom
                        color: SettingsMetrics.aboutLaptopBezelFill
                        border.width: Theme.borderThin
                        border.color: Theme.line
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: SettingsMetrics.aboutLaptopBezel
                        topLeftRadius: lid.screenTop
                        topRightRadius: lid.screenTop
                        bottomLeftRadius: lid.screenBottom
                        bottomRightRadius: lid.screenBottom
                        color: Theme.scrim
                        visible: wpImage.status !== Image.Ready
                    }
                    Image {
                        id: wpImage
                        anchors.fill: parent
                        anchors.margins: SettingsMetrics.aboutLaptopBezel
                        visible: false
                        source: Sys.wallpaper !== "" ? "file://" + Sys.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        sourceSize.width: root.aboutLaptopWidth * 2
                        sourceSize.height: root.aboutLaptopHeight * 2
                    }
                    Rectangle {
                        id: wpMask
                        anchors.fill: wpImage
                        topLeftRadius: lid.screenTop
                        topRightRadius: lid.screenTop
                        bottomLeftRadius: lid.screenBottom
                        bottomRightRadius: lid.screenBottom
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: wpImage
                        visible: wpImage.status === Image.Ready
                        source: wpImage
                        saturation: Sys.wallpaperMono ? -1.0 : 0.0
                        maskEnabled: true
                        maskSource: wpMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }

                    Rectangle {
                        x: (parent.width - width) / 2
                        y: SettingsMetrics.aboutLaptopBezel
                        width: root.aboutLaptopCutoutWidth
                        height: root.aboutLaptopCutoutHeight
                        bottomLeftRadius: height / 2
                        bottomRightRadius: height / 2
                        color: SettingsMetrics.aboutLaptopBezelFill
                    }
                }

                Shape {
                    id: base
                    y: lid.height - Theme.borderThin
                    width: laptop.width
                    height: root.aboutLaptopBaseHeight + Theme.borderThin
                    preferredRendererType: Shape.CurveRenderer

                    readonly property real r: Theme.radiusControl - Theme.space2
                    readonly property real cx: width / 2
                    readonly property real nw: root.aboutLaptopNotch
                    readonly property real nd: root.aboutLaptopNotchDepth

                    ShapePath {
                        strokeWidth: -1
                        fillGradient: LinearGradient {
                            x1: 0; y1: 0; x2: 0; y2: base.height
                            GradientStop { position: 0.0; color: SettingsMetrics.aboutLaptopBaseTop }
                            GradientStop { position: 1.0; color: SettingsMetrics.aboutLaptopBaseBottom }
                        }
                        startX: 0; startY: 0
                        PathLine { x: base.cx - base.nw / 2; y: 0 }
                        PathCubic {
                            x: base.cx; y: base.nd
                            control1X: base.cx - base.nw * 0.34; control1Y: 0
                            control2X: base.cx - base.nw * 0.2; control2Y: base.nd
                        }
                        PathCubic {
                            x: base.cx + base.nw / 2; y: 0
                            control1X: base.cx + base.nw * 0.2; control1Y: base.nd
                            control2X: base.cx + base.nw * 0.34; control2Y: 0
                        }
                        PathLine { x: base.width; y: 0 }
                        PathLine { x: base.width; y: base.height - base.r }
                        PathArc { x: base.width - base.r; y: base.height; radiusX: base.r; radiusY: base.r; direction: PathArc.Clockwise }
                        PathLine { x: base.r; y: base.height }
                        PathArc { x: 0; y: base.height - base.r; radiusX: base.r; radiusY: base.r; direction: PathArc.Clockwise }
                        PathLine { x: 0; y: 0 }
                    }
                }
            }

            Column {
                anchors {
                    left: laptop.right; leftMargin: root.aboutHeroGap
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.space8

                SettingsText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.computerName
                    font.pixelSize: root.aboutNameSize
                    font.weight: Theme.weightSemibold
                    font.letterSpacing: root.aboutNameTracking
                    font.variableAxes: ({ "opsz": 32, "wght": Theme.weightSemibold })
                }
                SettingsText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Sys.osName + " · up " + root.uptimeText(root.tick)
                    color: Theme.dim
                    font.pixelSize: Theme.fontMd
                }
                Item { width: 1; height: Theme.space12 }
                Row {
                    spacing: Theme.space4
                    PillButton { label: root.copied ? "Copied" : "Copy system info"; onClicked: root.copyInfo() }
                    PillButton { label: "Open settings folder"; flat: true; onClicked: Sys.spawn(["xdg-open", SettingsStore.dir]) }
                }
            }
        }

        SectionLabel { visible: root.statCells.length > 0; text: "HARDWARE" }

        Grid {
            width: page.width
            columns: 2
            columnSpacing: root.aboutStatGapX
            rowSpacing: root.aboutStatGapY

            Repeater {
                model: root.statCells

                delegate: Item {
                    id: cell
                    required property var modelData
                    width: (page.width - root.aboutStatGapX) / 2
                    height: cellBody.height + root.aboutStatPad

                    Rectangle {
                        width: parent.width
                        height: Theme.borderThin
                        color: Theme.line
                    }

                    Column {
                        id: cellBody
                        y: root.aboutStatPad
                        width: parent.width

                        SettingsText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: cell.modelData.label
                            color: Theme.dim
                        }
                        SettingsText {
                            visible: cell.modelData.value !== ""
                            width: parent.width
                            elide: Text.ElideRight
                            topPadding: Theme.space4
                            text: cell.modelData.value
                            font.pixelSize: root.aboutStatValueSize
                            font.weight: Theme.weightSemibold
                            font.letterSpacing: Theme.trackSnug
                        }
                        SettingsText {
                            visible: cell.modelData.sub !== ""
                            width: parent.width
                            elide: Text.ElideRight
                            topPadding: Theme.space2
                            text: cell.modelData.sub
                            color: Theme.dim
                        }
                        Item {
                            visible: cell.modelData.ratio >= 0
                            width: parent.width
                            height: Theme.space16 + root.aboutStatBar

                            Rectangle {
                                y: Theme.space16
                                width: parent.width
                                height: root.aboutStatBar
                                radius: height / 2
                                color: Theme.tilePress

                                Rectangle {
                                    width: parent.width * Math.max(0, cell.modelData.ratio)
                                    height: parent.height
                                    radius: height / 2
                                    color: Theme.text
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionLabel { text: "SOFTWARE" }

        Item {
            id: swBox
            width: page.width
            height: swColumn.height

            readonly property real pitch: root.aboutLayerHeight + root.aboutLayerGap
            property Item scroller: null
            property real anchorScroll: 0
            readonly property real scrollY: scroller ? scroller.contentY : 0

            readonly property int hoverRow: {
                if (!root.visible || !sbHover.hovered) return -1;
                const y = sbHover.point.position.y + (scrollY - anchorScroll);
                const i = Math.floor(y / pitch);
                return (i >= 0 && i < root.layers.length && y - i * pitch <= root.aboutLayerHeight) ? i : -1;
            }

            Component.onCompleted: {
                let p = swBox.parent;
                while (p && p.contentY === undefined) p = p.parent;
                scroller = p;
            }

            HoverHandler {
                id: sbHover
                cursorShape: swBox.hoverRow >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPointChanged: swBox.anchorScroll = swBox.scrollY
            }
            TapHandler {
                id: swTap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: if (swBox.hoverRow >= 0) root.copyLayer(swBox.hoverRow, root.layers[swBox.hoverRow].copy)
            }

            Column {
                id: swColumn
                width: swBox.width
                spacing: root.aboutLayerGap

                Repeater {
                    model: root.layers

                    delegate: Item {
                        id: layerRow
                        required property var modelData
                        required property int index

                        readonly property int shade: Math.min(index, 3)
                        readonly property bool hot: swBox.hoverRow === index
                        readonly property bool lit: hot || layerRow.activeFocus
                        readonly property bool done: root.copiedLayer === index

                        width: parent.width
                        height: root.aboutLayerHeight
                        z: lit ? 1 : 0
                        activeFocusOnTab: true
                        Keys.onReturnPressed: root.copyLayer(index, modelData.copy)
                        Keys.onEnterPressed: root.copyLayer(index, modelData.copy)
                        Keys.onSpacePressed: root.copyLayer(index, modelData.copy)
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.name + ", " + modelData.value
                        Accessible.description: "Copy version"
                        Accessible.onPressAction: root.copyLayer(index, modelData.copy)

                        Connections {
                            target: swBox
                            function onHoverRowChanged() {
                                if (swBox.hoverRow >= 0 && layerRow.activeFocus) layerRow.focus = false;
                            }
                        }

                        Rectangle {
                            id: face
                            property real lift: (swTap.pressed && layerRow.hot) ? 0.33 : (layerRow.lit ? 1 : 0)
                            x: -lift * root.aboutLayerGrowX
                            y: -lift * root.aboutLayerGrowY / 2
                            width: parent.width + lift * root.aboutLayerGrowX * 2
                            height: parent.height + lift * root.aboutLayerGrowY
                            radius: Theme.radiusControl
                            color: layerRow.lit ? root.aboutLayerHoverFill : [Theme.tilePress, Theme.tileHover, Theme.tile, Theme.tile][layerRow.shade]
                            border.width: Theme.borderThin
                            border.color: layerRow.lit ? root.aboutLayerHoverStroke : Qt.rgba(1, 1, 1, 0)

                            Behavior on lift { Tween {} }
                            Behavior on color { TweenColor { duration: Theme.durFast } }
                            Behavior on border.color { TweenColor { duration: Theme.durFast } }
                        }

                        SettingsText {
                            anchors { left: parent.left; leftMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
                            text: layerRow.modelData.name
                            font.pixelSize: Theme.fontLg
                            font.weight: layerRow.index === 0 ? Theme.weightSemibold : Theme.weightMedium
                        }
                        SettingsText {
                            anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
                            text: layerRow.done ? "Copied" : layerRow.modelData.value
                            color: layerRow.lit || layerRow.done ? Theme.text : Theme.text
                            font.pixelSize: Theme.fontMd
                            Behavior on color { TweenColor { duration: Theme.durFast } }
                        }
                    }
                }
            }
        }
    }
}
