import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../../../core"

// Halaman About: ringkasan komputer untuk pengguna (bukan info developer).
//   Hero     : laptop (bezel, kamera, alas dengan lekukan jari) dengan wallpaper aktif di layarnya + nama komputer + aksi
//   Hardware : kartu 2x2, strukturnya sama: label / nilai / keterangan (penyimpanan ditambah bar pemakaian)
//   Software : tumpukan lapisan, dari MacMono (paling terang) turun ke sistem dasar; tiap baris melebar saat
//              di-hover dan bisa diklik untuk menyalin versinya
// Path file dan angka internal sengaja tidak ditampilkan. Detail dibaca sekali dari
// Sys.systemDetails (scripts/session/system-info.sh) saat halaman ini pertama dibuka.
// Semua ukuran khusus halaman ini ada di Theme.qml bagian "Halaman About" (token about*).
Column {
    id: root
    spacing: 0

    readonly property var d: Sys.systemDetails
    property int tick: 0          // alasan teks uptime dihitung ulang; naik tiap 30 dtk selama halaman terbuka
    property bool copied: false

    onVisibleChanged: if (visible) Sys.loadSystemDetails()
    Timer { interval: 30000; repeat: true; running: root.visible && Sys.settingsOpen; onTriggered: root.tick++ }
    Timer { id: copiedTimer; interval: 1600; onTriggered: root.copied = false }

    // ---- teks turunan ----

    function clean(s) { return String(s ?? "").trim(); }
    // Vendor/produk bawaan pabrik yang tidak berguna ("To be filled by O.E.M." dsb) dianggap kosong.
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

    // Keterangan kartu prosesor: "6 cores · 12 threads" (atau hanya thread kalau jumlah core tidak terbaca).
    readonly property string cpuSub: cpuCores > 0 && cpuThreads > 0 ? cpuCores + " cores · " + cpuThreads + " threads"
                                   : cpuThreads > 0 ? cpuThreads + " threads" : ""

    // Satu baris untuk laporan "Copy system info"; kartu di layar memisahkan nama dan keterangan.
    readonly property string processor: cpuName === "" ? "" : (cpuSub !== "" ? cpuName + " · " + cpuSub : cpuName)

    // ---- grafis ----
    // lspci memberi nama kode ("AMD Barcelo"), bukan nama yang dikenal pengguna. Urutannya:
    //   1) ada nama dagang di dalam [...] -> pakai itu ("NVIDIA GeForce RTX 4060 Max-Q / Mobile")
    //   2) hanya nama kode               -> "AMD Radeon Graphics" / "Intel Graphics"
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

    // Perkiraan iGPU vs diskrit (tidak ada flag resmi di sysfs untuk ini):
    //   NVIDIA = diskrit; Intel = iGPU kecuali Arc/DG; AMD = iGPU kalau CPU-nya APU ("with Radeon Graphics") dan GPU-nya bukan RX/Pro.
    readonly property bool gpuIntegrated: {
        if (gpuVendor === "NVIDIA") return false;
        if (gpuVendor === "Intel") return !/\barc\b|\bDG[12]\b|alchemist|battlemage/i.test(gpuRaw);
        if (gpuVendor === "AMD") return /radeon/i.test(clean(d.cpu)) && !/\bRX\b|\bpro\b/i.test(gpuRaw);
        return false;
    }

    // iGPU memakai RAM sistem, jadi tidak ada angka VRAM yang jujur untuk ditampilkan; diskrit menampilkan VRAM-nya.
    readonly property string graphicsSub: {
        if (graphics === "") return "";
        if (gpuIntegrated) return "Integrated · shares system memory";
        const gb = Math.round((Number(d.gpuvram) || 0) / 1073741824);
        return gb > 0 ? "Discrete · " + gb + " GB" : "Discrete";
    }

    // ---- memori ----
    // MemTotal selalu lebih kecil dari RAM terpasang (sebagian dipakai kernel/firmware). Ukuran terpasang
    // diperkirakan dari ukuran standar terdekat di atasnya: 15 GB terbaca -> 16 GB terpasang.
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

    // ---- penyimpanan ----
    readonly property var diskParts: clean(d.disk).split(" ")
    readonly property real diskTotalKb: parseInt(diskParts[0]) || 0
    readonly property real diskUsedKb: parseInt(diskParts[1]) || 0
    function diskGb(kb) { return Math.round(kb * 1024 / 1e9); }

    // Bagian terpakai 0..1 untuk bar penyimpanan; -1 kalau datanya tidak ada (bar disembunyikan).
    readonly property real storageRatio: diskTotalKb > 0 ? Math.min(1, diskUsedKb / diskTotalKb) : -1
    readonly property string storageTotal: diskTotalKb > 0 ? diskGb(diskTotalKb) + " GB" : ""
    readonly property string storageSub: diskTotalKb > 0 ? diskGb(diskUsedKb) + " GB used · " + Math.round(storageRatio * 100) + "%" : ""
    // Untuk laporan "Copy system info".
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

    // Kartu hardware. Semua kartu punya struktur yang sama (label, nilai besar, keterangan kecil);
    // penyimpanan menambah bar pemakaian di bawahnya.
    readonly property var statCells: [
        { label: "Processor", value: cpuName, sub: cpuSub, ratio: -1 },
        { label: "Graphics", value: graphics, sub: graphicsSub, ratio: -1 },
        { label: "Memory", value: memory, sub: memorySub, ratio: -1 },
        { label: "Storage", value: storageTotal, sub: storageSub, ratio: storageRatio }
    ].filter(c => c.value !== "")

    // Lapisan software, dari yang paling dekat dengan pengguna (atas) ke dasar (bawah).
    readonly property var layers: [
        { name: "MacMono", value: "Shell", copy: shell },
        { name: "Quickshell", value: qsVersion, copy: "Quickshell " + qsVersion },
        { name: "Hyprland", value: hyprVersion, copy: "Hyprland " + hyprVersion },
        { name: String(Sys.osName ?? ""), value: clean(Sys.kernelVersion) !== "" ? "Linux " + clean(Sys.kernelVersion) : "",
          copy: String(Sys.osName ?? "") + ", Linux " + clean(Sys.kernelVersion) }
    ].filter(l => l.name !== "" && (l.name === "MacMono" || l.value !== ""))

    // Dipakai laporan "Copy system info" (apa yang tampil di halaman ini, tanpa path).
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

    // Salin versi dari satu baris Software (klik / Enter). copiedLayer = indeks baris yang sedang menampilkan "Copied".
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

    // ---- komponen lokal ----

    component SectionLabel: SettingsText {
        topPadding: Theme.aboutSectionGap
        bottomPadding: Theme.space12
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
    }

    // flat = tombol tanpa latar (aksi sekunder), supaya hanya satu tombol yang "berbentuk".
    component PillButton: Rectangle {
        id: pb
        property string label: ""
        property bool flat: false
        signal clicked()
        implicitWidth: pbText.implicitWidth + Theme.settingsButtonPadX * 2
        implicitHeight: Theme.settingsButtonHeight
        radius: Theme.radiusXs
        color: flat ? (pbArea.containsMouse ? Theme.tile : Theme.transparent)
                    : (pbArea.containsMouse ? Theme.tileHover : Theme.tileMid)
        Behavior on color { ColorAnimation { duration: Theme.animHover } }
        SettingsText {
            id: pbText
            anchors.centerIn: parent
            text: pb.label
            color: pb.flat ? Theme.textSoft : Theme.text
            font.weight: Font.Medium
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

    // ---- halaman: rata kiri, dibatasi lebarnya, satu tepi kiri dengan judul halaman ----

    Column {
        id: page
        x: Theme.settingsRowPadX
        width: Math.min(Theme.aboutContentMax, root.width - Theme.settingsRowPadX * 2)
        spacing: 0

        // -- hero: laptop bergaris + nama komputer
        Item {
            id: hero
            width: page.width
            height: laptop.height

            // laptop = layar (lid) + alas, rata kiri dengan kolom halaman. Alas lebih lebar dari layar.
            Item {
                id: laptop
                width: Theme.aboutLaptopBaseWidth
                height: Theme.aboutLaptopHeight + Theme.aboutLaptopBaseHeight

                Item {
                    id: lid
                    x: (laptop.width - width) / 2
                    width: Theme.aboutLaptopWidth
                    height: Theme.aboutLaptopHeight

                    // Sudut: atas bulat (tutup laptop), bawah hampir siku (engsel). Layar di dalamnya mengikuti, dikurangi tebal bezel.
                    readonly property real lidTop: Theme.radiusCard
                    readonly property real lidBottom: Theme.space4
                    readonly property real screenTop: Math.max(0, lidTop - Theme.aboutLaptopBezel)
                    readonly property real screenBottom: Theme.space2

                    // tutup laptop: bezel tipis gelap + garis tepi tipis
                    Rectangle {
                        anchors.fill: parent
                        topLeftRadius: lid.lidTop
                        topRightRadius: lid.lidTop
                        bottomLeftRadius: lid.lidBottom
                        bottomRightRadius: lid.lidBottom
                        color: Theme.aboutLaptopBezelFill
                        border.width: Theme.borderThin
                        border.color: Theme.lineStrong
                    }

                    // layar: wallpaper aktif (sama dengan yang ada di desktop, ikut mode monokrom)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.aboutLaptopBezel
                        topLeftRadius: lid.screenTop
                        topRightRadius: lid.screenTop
                        bottomLeftRadius: lid.screenBottom
                        bottomRightRadius: lid.screenBottom
                        color: Theme.inset
                        visible: wpImage.status !== Image.Ready
                    }
                    Image {
                        id: wpImage
                        anchors.fill: parent
                        anchors.margins: Theme.aboutLaptopBezel
                        visible: false
                        source: Sys.wallpaper !== "" ? "file://" + Sys.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        // Decode kecil saja: layar ini cuma 260 px, wallpaper aslinya bisa 4K.
                        sourceSize.width: Theme.aboutLaptopWidth * 2
                        sourceSize.height: Theme.aboutLaptopHeight * 2
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

                    // poni kamera: kapsul gelap menempel di tepi atas layar, menggigit sedikit ke dalam gambar
                    Rectangle {
                        x: (parent.width - width) / 2
                        y: Theme.aboutLaptopBezel
                        width: Theme.aboutLaptopCutoutWidth
                        height: Theme.aboutLaptopCutoutHeight
                        bottomLeftRadius: height / 2
                        bottomRightRadius: height / 2
                        color: Theme.aboutLaptopBezelFill
                    }
                }

                // alas: gradasi terang -> redup supaya terbaca sebagai permukaan, lekukan jari di tengah.
                // Mulai 1 px di atas tepi bawah layar supaya engselnya tidak bercelah.
                Shape {
                    id: base
                    y: lid.height - Theme.borderThin
                    width: laptop.width
                    height: Theme.aboutLaptopBaseHeight + Theme.borderThin
                    preferredRendererType: Shape.CurveRenderer

                    readonly property real r: Theme.radiusXs - Theme.space2      // sudut bawah
                    readonly property real cx: width / 2
                    readonly property real nw: Theme.aboutLaptopNotch
                    readonly property real nd: Theme.aboutLaptopNotchDepth

                    ShapePath {
                        strokeWidth: -1
                        fillGradient: LinearGradient {
                            x1: 0; y1: 0; x2: 0; y2: base.height
                            GradientStop { position: 0.0; color: Theme.aboutLaptopBaseTop }
                            GradientStop { position: 1.0; color: Theme.aboutLaptopBaseBottom }
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
                    left: laptop.right; leftMargin: Theme.aboutHeroGap
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.space6

                SettingsText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.computerName
                    font.pixelSize: Theme.aboutNameSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.aboutNameTracking
                    font.variableAxes: ({ "opsz": 32, "wght": Font.DemiBold })
                }
                SettingsText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Sys.osName + " · up " + root.uptimeText(root.tick)
                    color: Theme.dim
                    font.pixelSize: Theme.fontSubtitle
                }
                Item { width: 1; height: Theme.space10 }
                Row {
                    spacing: Theme.space4
                    PillButton { label: root.copied ? "Copied" : "Copy system info"; onClicked: root.copyInfo() }
                    PillButton { label: "Open settings folder"; flat: true; onClicked: Sys.spawn(["xdg-open", SettingsStore.dir]) }
                }
            }
        }

        // -- hardware: kartu 2x2, hanya garis tipis di atas tiap kartu
        SectionLabel { visible: root.statCells.length > 0; text: "HARDWARE" }

        Grid {
            width: page.width
            columns: 2
            columnSpacing: Theme.aboutStatGapX
            rowSpacing: Theme.aboutStatGapY

            Repeater {
                model: root.statCells

                delegate: Item {
                    id: cell
                    required property var modelData
                    width: (page.width - Theme.aboutStatGapX) / 2
                    height: cellBody.height + Theme.aboutStatPad

                    Rectangle {
                        width: parent.width
                        height: Theme.borderThin
                        color: Theme.line
                    }

                    Column {
                        id: cellBody
                        y: Theme.aboutStatPad
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
                            font.pixelSize: Theme.aboutStatValueSize
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.settingsRowTracking
                        }
                        SettingsText {
                            visible: cell.modelData.sub !== ""
                            width: parent.width
                            elide: Text.ElideRight
                            topPadding: Theme.space2
                            text: cell.modelData.sub
                            color: Theme.dim
                        }
                        // bar pemakaian: panjang = terpakai, tanpa warna (kontrak R1)
                        Item {
                            visible: cell.modelData.ratio >= 0
                            width: parent.width
                            height: Theme.space14 + Theme.aboutStatBar

                            Rectangle {
                                y: Theme.space14
                                width: parent.width
                                height: Theme.aboutStatBar
                                radius: height / 2
                                color: Theme.tileStrong

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

        // -- software: tumpukan lapisan; makin ke atas makin terang
        SectionLabel { text: "SOFTWARE" }

        // Hover dipegang SATU pemilik (sbHover) untuk semua baris. Baris yang menyala dihitung dari posisi
        // kursor, bukan dari status hover tiap baris. Dengan satu sumber kebenaran, dua baris tidak bisa
        // sama-sama menyala dan satu baris tidak bisa "nyangkut" kalau satu event keluar terlewat.
        // hoverRow kembali -1 (semua baris normal) kalau: kursor keluar dari kolom / panel, panel ditutup,
        // atau halaman digulir sampai baris pindah dari bawah kursor (posisi kursor ikut dikoreksi dengan
        // selisih gulir). Baris lalu kembali lewat pegas `lift` yang sama: tidak ada animasi kedua.
        Item {
            id: swBox
            width: page.width
            height: swColumn.height

            readonly property real pitch: Theme.aboutLayerHeight + Theme.aboutLayerGap
            property Item scroller: null            // Flickable pembungkus halaman, dicari sekali di bawah
            property real anchorScroll: 0           // contentY saat posisi kursor terakhir diperbarui
            readonly property real scrollY: scroller ? scroller.contentY : 0

            readonly property int hoverRow: {
                if (!root.visible || !sbHover.hovered) return -1;
                const y = sbHover.point.position.y + (scrollY - anchorScroll);
                const i = Math.floor(y / pitch);
                return (i >= 0 && i < root.layers.length && y - i * pitch <= Theme.aboutLayerHeight) ? i : -1;
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
                spacing: Theme.aboutLayerGap

                Repeater {
                    model: root.layers

                    // Penampung tidak ikut membesar (area hover tetap stabil, tidak berkedip di tepi);
                    // yang melebar hanya latarnya. Teks tidak di-scale supaya tetap tajam.
                    delegate: Item {
                        id: layerRow
                        required property var modelData
                        required property int index

                        readonly property int shade: Math.min(index, 3)
                        readonly property bool hot: swBox.hoverRow === index
                        readonly property bool lit: hot || layerRow.activeFocus
                        readonly property bool done: root.copiedLayer === index

                        width: parent.width
                        height: Theme.aboutLayerHeight
                        z: lit ? 1 : 0
                        activeFocusOnTab: true
                        Keys.onReturnPressed: root.copyLayer(index, modelData.copy)
                        Keys.onEnterPressed: root.copyLayer(index, modelData.copy)
                        Keys.onSpacePressed: root.copyLayer(index, modelData.copy)
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.name + ", " + modelData.value
                        Accessible.description: "Copy version"
                        Accessible.onPressAction: root.copyLayer(index, modelData.copy)

                        // Kursor mulai dipakai: sorotan fokus keyboard (Tab) dilepas, supaya tidak ada baris
                        // yang tetap menyala karena fokus lama.
                        Connections {
                            target: swBox
                            function onHoverRowChanged() {
                                if (swBox.hoverRow >= 0 && layerRow.activeFocus) layerRow.focus = false;
                            }
                        }

                        Rectangle {
                            id: face
                            // lift 0..1: 0 diam, 1 penuh saat hover/fokus, sepertiganya saat ditekan. Diikuti pegas, jadi
                            // naiknya sedikit "mental" lalu menetap, dan turunnya mengalir (bukan potong lurus).
                            // Ini SATU-SATUNYA animasi gerak baris; x/y/width/height hanya turunan lift.
                            property real lift: (swTap.pressed && layerRow.hot) ? 0.33 : (layerRow.lit ? 1 : 0)
                            x: -lift * Theme.aboutLayerGrowX
                            y: -lift * Theme.aboutLayerGrowY / 2
                            width: parent.width + lift * Theme.aboutLayerGrowX * 2
                            height: parent.height + lift * Theme.aboutLayerGrowY
                            radius: Theme.radiusXs
                            color: layerRow.lit ? Theme.aboutLayerHoverFill : [Theme.tileStrong, Theme.tileHover, Theme.tileMid, Theme.tile][layerRow.shade]
                            border.width: Theme.borderThin
                            border.color: layerRow.lit ? Theme.aboutLayerHoverStroke : Qt.rgba(1, 1, 1, 0)

                            Behavior on lift { SpringAnimation { spring: Theme.aboutLayerSpring; damping: Theme.aboutLayerDamp; epsilon: 0.002 } }
                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animHover } }
                        }

                        SettingsText {
                            anchors { left: parent.left; leftMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
                            text: layerRow.modelData.name
                            font.pixelSize: Theme.fontTitle
                            font.weight: layerRow.index === 0 ? Font.DemiBold : Font.Medium
                        }
                        SettingsText {
                            anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
                            text: layerRow.done ? "Copied" : layerRow.modelData.value
                            color: layerRow.lit || layerRow.done ? Theme.text : Theme.textSoft
                            font.pixelSize: Theme.fontSubtitle
                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                        }
                    }
                }
            }
        }
    }
}
