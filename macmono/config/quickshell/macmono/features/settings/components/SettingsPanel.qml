import QtQuick
import "../../../core"
import "../../../shared/components"

// Isi Pengaturan Sistem (sidebar kanan). Dua tingkat, seperti Settings di ponsel:
//   layar utama = daftar halaman (dikelompokkan), lalu klik satu halaman = isi halaman + tombol kembali.
// Pencarian selalu ada di atas dan mencari lintas semua halaman (judul halaman ikut dicocokkan,
// jadi "Advanced" atau "Top Bar" tetap ketemu walau tak ada item yang memuat kata itu).
// Tidak tahu apa-apa soal window; features/settings/SettingsApp.qml yang membungkusnya jadi overlay layar.
//
// Alur: perubahan masuk ke `draft` dulu. Bar "Apply" muncul melayang di bawah hanya saat ada draft;
// "Apply" menulis ke SettingsStore (langsung berlaku tanpa reload shell, tersimpan di
// ~/.config/macmono/settings.json), "Cancel" membuang draft. Setelah Apply bar berganti jadi
// status "Saved" sebentar, supaya jelas perubahan sudah masuk.
//
// Keyboard: Up/Down + Enter (di kolom cari) memilih halaman, Esc mundur satu tingkat
// (cari -> draft -> halaman -> tutup), Ctrl+S terapkan, Ctrl+F fokus ke kolom cari.
FocusScope {
    id: root
    signal closeRequested()
    signal navMoved()   // sorotan daftar pindah lewat keyboard (supaya baris yang disorot ikut tergulung masuk)

    // "" = layar utama (daftar halaman); selain itu id halaman yang sedang dibuka.
    property string pageId: ""
    property string navId: SettingsSchema.pages[0].id   // baris yang disorot di layar utama
    property var draft: ({})

    // "Saved" kecil setelah Apply. Hilang sendiri; sembunyi lagi begitu ada editan baru.
    property bool savedFlash: false
    Timer { id: savedTimer; interval: 1700; onTriggered: root.savedFlash = false }

    readonly property string query: searchInput.text
    readonly property bool searching: query.trim() !== ""
    readonly property bool atHome: pageId === "" && !searching
    readonly property bool atPage: pageId !== "" && !searching
    readonly property int dirtyCount: Object.keys(draft).length
    readonly property bool dirty: dirtyCount > 0
    // Bar bawah dipakai bergantian: bar Apply saat ada draft, status "Saved" sesudahnya, sisanya footer hint.
    readonly property bool barShown: dirty || savedFlash

    // Pengelompokan layar utama. Halaman yang belum disebut di sini otomatis masuk grup "More",
    // jadi setiap halaman baru harus didaftarkan di sini — kalau lupa, grup "More" bermunculan sendiri.
    readonly property var navSections: [
        { title: "Shell", ids: ["appearance", "topbar", "clock", "launcher", "clipboard", "notif", "keys"] },
        { title: "System", ids: ["display", "wallpaper", "network", "battery", "media"] },
        { title: "Other", ids: ["capture", "lock", "advanced", "about"] }
    ]

    readonly property var navGroups: {
        const used = ({});
        const out = [];
        for (const s of navSections) {
            const items = [];
            for (const id of s.ids)
                for (const p of SettingsSchema.pages)
                    if (p.id === id) { items.push(p); used[id] = true; }
            if (items.length > 0) out.push({ title: s.title, items: items });
        }
        const rest = [];
        for (const p of SettingsSchema.pages)
            if (!used[p.id]) rest.push(p);
        if (rest.length > 0) out.push({ title: "More", items: rest });
        return out;
    }

    readonly property var navIds: {
        const ids = [];
        for (const g of navGroups)
            for (const p of g.items) ids.push(p.id);
        return ids;
    }

    readonly property var currentPage: {
        for (const p of SettingsSchema.pages)
            if (p.id === pageId) return p;
        return null;
    }

    // Daftar pintasan keyboard: satu sumber data dengan Cheatsheet (core/shortcuts/KeyList.qml).
    readonly property var keyGroups: KeyList.groups

    readonly property var searchGroups: {
        const q = query.trim().toLowerCase();
        if (q === "") return [];
        const hit = (s) => String(s ?? "").toLowerCase().indexOf(q) >= 0;

        // Halaman cocok kalau nama, deskripsi, atau nama salah satu grupnya memuat kata kunci.
        // Ini yang bikin "Advanced"/"Top Bar"/"Display" tidak lagi berakhir di "No results".
        const pageHits = [];
        for (const p of SettingsSchema.pages) {
            let groupHit = false;
            for (const g of p.groups)
                if (hit(g.title)) groupHit = true;
            if (hit(p.label) || hit(p.desc) || groupHit)
                pageHits.push({ id: p.id, label: p.label, desc: p.desc, icon: p.icon });
        }

        const out = [];
        if (pageHits.length > 0)
            out.push({ title: "Pages", pageRows: true, items: pageHits });
        for (const p of SettingsSchema.pages) {
            const items = [];
            for (const g of p.groups)
                for (const it of g.items)
                    if (hit(it.label) || hit(it.desc ?? "") || hit(it.key))
                        items.push(it);
            if (items.length > 0) out.push({ title: p.label, pageRows: false, items: items });
        }
        return out;
    }
    readonly property int resultCount: {
        let n = 0;
        for (const g of searchGroups) n += g.items.length;
        return n;
    }
    readonly property var shownGroups: searching ? searchGroups : (currentPage ? currentPage.groups : [])

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

    function valueOf(item) {
        if (draft.hasOwnProperty(item.key)) return draft[item.key];
        return SettingsStore.v(item.key, item.def);
    }

    function setValue(item, v) {
        savedFlash = false;   // editan baru membatalkan status "Saved"
        const next = Object.assign({}, draft);
        if (same(v, SettingsStore.v(item.key, item.def))) delete next[item.key];
        else next[item.key] = v;
        draft = next;
    }

    // Halaman read-only (Keyboard Shortcuts, About) tak punya draft, jadi "Reset page" disembunyikan.
    function pageResettable(page) {
        if (!page || !page.groups) return false;
        for (const g of page.groups)
            for (const it of g.items)
                if (!it.ro && !it.live) return true;
        return false;
    }

    function pageDirty(page) {
        if (!page || !page.groups) return false;   // baris hasil cari "Pages" cuma bawa id/label/desc/icon
        for (const g of page.groups)
            for (const it of g.items)
                if (draft.hasOwnProperty(it.key)) return true;
        return false;
    }

    function resetPage() {
        if (!currentPage) return;
        savedFlash = false;
        const next = Object.assign({}, draft);
        for (const g of currentPage.groups)
            for (const it of g.items) {
                if (it.ro || it.live) continue;
                if (same(it.def, SettingsStore.v(it.key, it.def))) delete next[it.key];
                else next[it.key] = it.def;
            }
        draft = next;
    }

    function revert() {
        savedFlash = false;
        draft = ({});
    }

    function apply() {
        if (!dirty) return;
        const sets = {};
        const removes = [];
        for (const k in draft) {
            const it = SettingsSchema.find(k);
            if (it && same(draft[k], it.def)) removes.push(k);
            else sets[k] = draft[k];
        }
        SettingsStore.apply(sets, removes);
        draft = ({});
        savedFlash = true;
        savedTimer.restart();
    }

    function openPage(id) {
        searchInput.text = "";
        pageId = id;
    }

    function goHome() {
        if (pageId !== "") navId = pageId;   // sorotan tetap di halaman yang baru ditinggalkan
        searchInput.text = "";
        pageId = "";
    }

    function moveNav(delta) {
        const i = Math.max(0, navIds.indexOf(navId));
        navId = navIds[Math.max(0, Math.min(navIds.length - 1, i + delta))];
        navMoved();
    }

    function focusSearch() { searchInput.forceActiveFocus(); }

    // Ganti halaman / mulai mencari: gulir ke atas lalu jalankan animasi masuk konten.
    // Tanpa ini, konten berganti mendadak sementara panel lain semua memakai pegas (Reveal).
    onPageIdChanged: { flick.contentY = 0; pageIntro.restart(); }
    onQueryChanged: { flick.contentY = 0; pageIntro.restart(); }

    Keys.onEscapePressed: {
        if (searching) searchInput.text = "";
        else if (dirty) revert();
        else if (pageId !== "") goHome();
        else closeRequested();
    }
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
            apply();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            focusSearch();
            event.accepted = true;
        }
    }

    component Btn: Rectangle {
        id: btn
        property string label
        property bool primary: false
        signal clicked()

        implicitWidth: btnLabel.implicitWidth + Theme.settingsButtonPadX * 2
        implicitHeight: Theme.settingsButtonHeight
        radius: Theme.radiusXs + 1
        color: primary ? (btnArea.containsMouse ? Theme.inverseHover : Theme.inverse)
                       : (btnArea.containsMouse ? Theme.tileHover : Theme.tileMid)
        Behavior on color { ColorAnimation { duration: Theme.animHover } }

        SettingsText {
            id: btnLabel
            anchors.centerIn: parent
            text: btn.label
            font.weight: Font.Medium
            color: btn.primary ? Theme.inverseText : Theme.text
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // Tombol bulat kecil di header (kembali / tutup).
    component RoundBtn: Rectangle {
        id: rb
        property string glyph
        property int glyphRotation: 0
        property string accessibleName: ""
        signal clicked()

        width: Theme.icon22 + Theme.space6
        height: width
        radius: height / 2
        color: rbArea.containsMouse ? Theme.tileHover : Theme.tile
        Behavior on color { ColorAnimation { duration: Theme.animHover } }

        Glyph {
            anchors.centerIn: parent
            name: rb.glyph
            rotation: rb.glyphRotation
            color: Theme.textSoft
            width: Theme.icon14
            height: Theme.icon14
        }
        MouseArea {
            id: rbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.clicked()
        }
        Accessible.role: Accessible.Button
        Accessible.name: rb.accessibleName
    }

    // Satu baris halaman (dipakai di layar utama DAN di hasil pencarian "Pages"),
    // supaya keduanya tampil identik dan cuma punya satu sumber tata letak.
    component NavRow: Item {
        id: navRow
        property var page: null
        property int rowIndex: 0
        property bool current: false

        width: parent ? parent.width : 0
        height: Theme.settingsListRowHeight

        Connections {
            target: root
            function onNavMoved() { if (navRow.current) flick.reveal(navRow); }
        }

        // sorotan (hover dan keyboard memakai satu penanda)
        Rectangle {
            anchors.fill: parent
            // Editorial: sorotan selebar baris (tanpa inset), sudut ringan. Baris terasa seperti
            // potongan teks yang disorot, bukan tombol yang mengambang.
            radius: Theme.radiusXs
            color: navRow.current ? Theme.tileMid : Theme.transparent
        }

        // Pemisah digambar DI ATAS sorotan: sebelumnya sorotan menutupinya, jadi garisnya
        // berkedip hilang-muncul tiap kursor lewat.
        Rectangle {
            visible: navRow.rowIndex > 0
            z: 2
            x: Theme.settingsRowPadX + Theme.icon16 + Theme.space12
            width: navRow.width - x - Theme.settingsRowPadX
            height: Theme.borderThin
            color: Theme.line
        }

        // Ikon polos tanpa kotak: kotak cekung 32 px menarik perhatian ke wadahnya, padahal yang
        // dibaca orang adalah nama halaman. Tanpa kotak, ikon jadi penanda tenang di tepi kiri.
        Item {
            id: iconBox
            x: Theme.settingsRowPadX
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.icon16
            height: Theme.icon16

            Glyph {
                anchors.centerIn: parent
                name: navRow.page ? navRow.page.icon : ""
                color: Theme.muted
                width: Theme.icon16
                height: Theme.icon16
            }

            Rectangle {
                visible: navRow.page ? root.pageDirty(navRow.page) : false
                width: Theme.settingsDot
                height: Theme.settingsDot
                radius: height / 2
                color: Theme.inverse
                anchors { right: parent.right; top: parent.top; rightMargin: -Theme.space2; topMargin: -Theme.space2 }
            }
        }

        Glyph {
            id: chevron
            anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
            name: "chevron"
            rotation: -90
            color: Theme.muted
            width: Theme.icon14
            height: Theme.icon14
        }

        Column {
            anchors {
                left: iconBox.right; leftMargin: Theme.space12
                right: chevron.left; rightMargin: Theme.space8
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.space2

            SettingsText {
                width: parent.width
                text: navRow.page ? navRow.page.label : ""
                font.pixelSize: Theme.fontHeading
                font.weight: Font.Medium
                font.letterSpacing: Theme.settingsRowTracking
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: if (navRow.page) root.navId = navRow.page.id
            onClicked: if (navRow.page) root.openPage(navRow.page.id)
        }

        Accessible.role: Accessible.Button
        Accessible.name: navRow.page ? navRow.page.label : ""
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.lineStrong
        clip: true

        // ---- header: [kembali] judul ........ [tutup]
        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Theme.settingsHeaderHeight

            // Tombol kembali punya tempat tetap di gutter, judulnya yang bergeser halus.
            // Dulu judul melompat 38 px begitu masuk halaman, jadi sumbu vertikalnya berubah.
            RoundBtn {
                id: backBtn
                x: Theme.settingsGutter
                anchors.verticalCenter: parent.verticalCenter
                glyph: "chevron"
                glyphRotation: 90
                accessibleName: "Back"
                opacity: root.atPage ? 1 : 0
                visible: root.atPage || opacity > 0
                enabled: root.atPage
                Behavior on opacity { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
                onClicked: root.goHome()
            }

            SettingsText {
                id: titleText
                x: Theme.settingsGutter + (root.atPage ? backBtn.width + Theme.space10 : 0)
                width: parent.width - x - Theme.icon22 - Theme.space6 - Theme.settingsGutter - Theme.space10
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.searching ? "Settings" : (root.currentPage ? root.currentPage.label : "Settings")
                font.pixelSize: Theme.settingsTitleSize
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.settingsTitleTracking
                // Judul besar pakai desain "display" Inter (sumbu opsz 14-32) supaya tidak longgar.
                // Kalau fontnya bukan variable font, Qt mengabaikan sumbu ini.
                font.variableAxes: ({ "opsz": 32, "wght": Font.DemiBold })
                Behavior on x { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
            }

            RoundBtn {
                anchors { right: parent.right; rightMargin: Theme.settingsGutter; verticalCenter: parent.verticalCenter }
                glyph: "close"
                accessibleName: "Close"
                onClicked: root.closeRequested()
            }
        }

        // ---- kolom cari (kapsul, sejajar bentuk kolom cari panel lain)
        Rectangle {
            id: searchBox
            anchors { top: header.bottom; left: parent.left; right: parent.right; leftMargin: Theme.settingsGutter; rightMargin: Theme.settingsGutter }
            height: Theme.settingsSearchHeight
            radius: height / 2
            color: Theme.inset
            border.width: Theme.borderThin
            border.color: searchInput.activeFocus ? Theme.lineFocus : Theme.line

            Glyph {
                id: searchIcon
                name: "search"
                color: Theme.dim
                width: Theme.icon15
                height: Theme.icon15
                anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
            }

            TextInput {
                id: searchInput
                anchors { left: searchIcon.right; leftMargin: Theme.space8; right: clearBtn.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                color: Theme.text
                selectionColor: Theme.selection
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.hintingPreference: Font.PreferVerticalHinting
                renderType: TextInput.NativeRendering
                clip: true
                selectByMouse: true
                Accessible.name: "Search settings"
                Keys.onUpPressed: if (root.atHome) root.moveNav(-1)
                Keys.onDownPressed: if (root.atHome) root.moveNav(1)
                Keys.onReturnPressed: if (root.atHome) root.openPage(root.navId)
                Keys.onEnterPressed: if (root.atHome) root.openPage(root.navId)
                Keys.onEscapePressed: event => {
                    if (text !== "") { text = ""; event.accepted = true; }
                    else { event.accepted = false; }
                }

                SettingsText {
                    visible: searchInput.text === ""
                    text: "Search settings"
                    color: Theme.muted
                    font.pixelSize: Theme.fontTitle
                }
            }

            Item {
                id: clearBtn
                visible: searchInput.text !== ""
                width: Theme.icon22
                height: Theme.icon22
                anchors { right: parent.right; rightMargin: Theme.space6; verticalCenter: parent.verticalCenter }

                Glyph {
                    anchors.centerIn: parent
                    name: "close"
                    color: Theme.dim
                    width: Theme.icon13
                    height: Theme.icon13
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { searchInput.text = ""; searchInput.forceActiveFocus(); }
                }
            }
        }

        // ---- isi (layar utama / halaman / hasil cari)
        Flickable {
            id: flick
            anchors { top: searchBox.bottom; topMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space8; left: parent.left; right: parent.right }
            contentWidth: width
            // Bar bawah cuma dipesan setinggi yang benar-benar dipakai: bar Apply (44) saat ada
            // draft/status, footer hint (26) saat tidak. Dulu bar 44 selalu dipesan, jadi ada
            // ruang mati permanen di dasar panel dan isi gampang tenggelam ke bawah lipatan.
            contentHeight: content.height + Theme.settingsPadTop + Theme.settingsGutter * 2
                           + (root.barShown ? Theme.settingsBarHeight + Theme.space8 : Theme.space8)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // dipanggil hanya dari keyboard (bukan hover), supaya konten tidak bergeser di bawah kursor
            function reveal(item) {
                const top = item.mapToItem(contentItem, 0, 0).y - Theme.space12;
                const bottom = top + item.height + Theme.space12 * 2;
                if (top < contentY) contentY = Math.max(0, top);
                else if (bottom > contentY + height) contentY = Math.max(0, Math.min(contentHeight - height, bottom - height));
            }

            // PENTING: semua blok di bawah ini HARUS jadi anak Column `content`.
            // Repeater hanya membuat delegate, dia tidak menatanya. Kalau Repeater jadi anak
            // Flickable langsung, semua delegate menumpuk di y = 0 dan teksnya saling tindih.
            Column {
                id: content
                x: Theme.settingsGutter
                y: Theme.settingsPadTop
                width: flick.width - Theme.settingsGutter * 2
                spacing: Theme.settingsGroupSpacing
                transform: Translate { id: contentShift }

                // -- layar utama: daftar halaman per kelompok
                Repeater {
                    model: root.atHome ? root.navGroups : []

                    delegate: Column {
                        id: navGroup
                        required property var modelData
                        width: content.width
                        spacing: Theme.space8

                        SettingsText {
                            text: navGroup.modelData.title.toUpperCase()
                            color: Theme.labelCapsText
                            font.pixelSize: Theme.labelCapsSize
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.labelCapsTracking
                            leftPadding: Theme.settingsRowPadX
                        }

                        Rectangle {
                            width: parent.width
                            height: navRows.height
                            // Arah editorial: grup tidak lagi blok abu berbingkai. Baris dipisahkan garis
                            // rambut 1 px (lihat NavRow), jadi daftar terbaca sebagai satu kolom teks.
                            color: Theme.transparent

                            Column {
                                id: navRows
                                width: parent.width

                                Repeater {
                                    model: navGroup.modelData.items

                                    delegate: NavRow {
                                        required property var modelData
                                        required property int index
                                        page: modelData
                                        rowIndex: index
                                        current: root.navId === modelData.id
                                    }
                                }
                            }
                        }
                    }
                }

                // -- header halaman About: logo besar + nama OS (pola "About This Mac")
                Item {
                    visible: root.currentPage && root.currentPage.about === true
                    width: content.width
                    height: aboutHead.height + Theme.space8

                    Column {
                        id: aboutHead
                        width: parent.width
                        y: Theme.space8
                        spacing: Theme.space8

                        // Logo placeholder (logo shell). Monokrom, ikut warna teks.
                        Glyph {
                            x: (aboutHead.width - width) / 2
                            name: "enso"
                            color: Theme.text
                            width: Theme.settingsAboutLogo
                            height: Theme.settingsAboutLogo
                        }

                        SettingsText {
                            width: aboutHead.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: Sys.osName
                            font.pixelSize: Theme.fontHero
                            font.weight: Font.DemiBold
                            // Sumbu opsz Inter: nama OS tampil sebagai "display", bukan teks isi.
                            font.variableAxes: ({ "opsz": 32, "wght": Font.DemiBold })
                        }

                    }
                }

                // -- halaman: hanya tautan reset; deskripsi halaman tidak digambar
                // (teksnya tetap ada di schema karena dipakai pencarian).
                Item {
                    visible: root.atPage && root.pageResettable(root.currentPage)
                    width: content.width
                    height: visible ? resetLink.implicitHeight : 0

                    SettingsText {
                        id: resetLink
                        anchors { right: parent.right; rightMargin: Theme.settingsRowPadX }
                        // Halaman read-only (Keyboard Shortcuts, About) tak punya draft, jadi tak ada yang bisa di-reset.
                        visible: root.pageResettable(root.currentPage)
                        text: "Reset page"
                        color: resetArea.containsMouse ? Theme.text : Theme.dim
                        font.pixelSize: Theme.fontBodyLg
                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            anchors.margins: -Theme.space6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetPage()
                        }
                    }
                }

                // -- halaman pintasan keyboard (sumber data sama dengan Cheatsheet)
                Column {
                    visible: root.atPage && root.currentPage && root.currentPage.keys === true
                    width: content.width
                    spacing: Theme.settingsGroupSpacing

                    Repeater {
                        model: (root.atPage && root.currentPage && root.currentPage.keys === true) ? root.keyGroups : []

                        delegate: Column {
                            id: keyGroup
                            required property var modelData
                            width: content.width
                            spacing: Theme.space8

                            SettingsText {
                                text: keyGroup.modelData.title.toUpperCase()
                                color: Theme.labelCapsText
                                font.pixelSize: Theme.labelCapsSize
                                font.weight: Font.DemiBold
                                font.letterSpacing: Theme.labelCapsTracking
                                leftPadding: Theme.settingsRowPadX
                            }

                            Rectangle {
                                width: parent.width
                                height: keyCardBody.height
                                radius: Theme.radiusCard
                                color: Theme.tile
                                border.width: Theme.borderThin
                                border.color: Theme.cardStroke

                                // Kiri-kanan menentukan lebar; jangan pasang `width` juga.
                                SettingsKeys {
                                    id: keyCardBody
                                    anchors {
                                        left: parent.left; right: parent.right; top: parent.top
                                        leftMargin: Theme.space8; rightMargin: Theme.space8
                                        topMargin: Theme.space8
                                    }
                                    rows: keyGroup.modelData.items
                                }
                            }
                        }
                    }
                }

                // -- hasil cari: jumlah hasil
                SettingsText {
                    visible: root.searching
                    leftPadding: Theme.settingsRowPadX
                    text: root.resultCount === 0
                        ? "No results for “" + root.query.trim() + "”"
                        : root.resultCount + (root.resultCount === 1 ? " result for “" : " results for “") + root.query.trim() + "”"
                    color: Theme.dim
                }

                // -- grup pengaturan (halaman atau hasil cari)
                Repeater {
                    model: root.shownGroups

                    delegate: Column {
                        id: group
                        required property var modelData
                        width: content.width
                        spacing: Theme.space8

                        SettingsText {
                            text: group.modelData.title.toUpperCase()
                            color: Theme.labelCapsText
                            font.pixelSize: Theme.labelCapsSize
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.labelCapsTracking
                            leftPadding: Theme.settingsRowPadX
                        }

                        Rectangle {
                            width: parent.width
                            height: rows.height
                            color: Theme.transparent

                            Column {
                                id: rows
                                width: parent.width

                                // Hasil pencarian "Pages": baris navigasi, bukan baris pengaturan.
                                Repeater {
                                    model: group.modelData.pageRows ? group.modelData.items : []

                                    delegate: NavRow {
                                        required property var modelData
                                        required property int index
                                        page: modelData
                                        rowIndex: index
                                        current: root.navId === modelData.id
                                    }
                                }

                                Repeater {
                                    model: group.modelData.pageRows ? [] : group.modelData.items

                                    delegate: SettingsItem {
                                        id: entry
                                        required property var modelData
                                        required property int index

                                        width: rows.width
                                        item: modelData
                                        separator: index > 0
                                        modified: !modelData.ro && root.draft.hasOwnProperty(modelData.key)
                                        value: modelData.ro
                                            ? ""
                                            : (modelData.live ? Sys[modelData.key] : root.valueOf(modelData))
                                        onEdit: v => {
                                            if (modelData.live) Sys[modelData.liveAction]();
                                            else root.setValue(modelData, v);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Animasi masuk konten (fade + geser 6 px), dipicu onPageIdChanged / onQueryChanged.
        // Sengaja di luar Flickable: dia bukan Item, jadi tidak ikut ditata Column.
        ParallelAnimation {
            id: pageIntro
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
            NumberAnimation { target: contentShift; property: "y"; from: Theme.space6; to: 0; duration: Theme.animBase; easing.type: Theme.easeOut }
        }

        Rectangle {
            visible: flick.contentHeight > flick.height
            x: flick.x + flick.width - Theme.settingsScrollbarInset
            y: flick.y + flick.visibleArea.yPosition * flick.height
            width: Theme.settingsScrollbarWidth
            height: Math.max(Theme.settingsScrollbarMin, flick.visibleArea.heightRatio * flick.height)
            radius: Theme.radiusIndicator
            color: Theme.tileStrong
        }

        // ---- bar bawah: draft (Apply/Cancel), lalu status "Saved" sebentar
        Rectangle {
            id: statusBar
            property real slide: root.barShown ? 0 : 1
            Behavior on slide { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }

            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.settingsGutter }
            height: Theme.settingsBarHeight
            radius: Theme.radiusCard
            color: Theme.settingsBarFill
            border.width: Theme.borderThin
            border.color: Theme.lineStrong
            opacity: 1 - slide
            visible: opacity > 0
            transform: Translate { y: statusBar.slide * Theme.space12 }

            MouseArea { anchors.fill: parent }   // klik di bar jangan tembus ke konten

            Item {
                anchors { left: parent.left; leftMargin: Theme.settingsRowPadX; right: barButtons.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                height: statusText.implicitHeight

                // Dua anak ini di-anchor, bukan ditaruh di Row: Row menata x sendiri dan
                // Qt memperingatkan anchor vertikal di dalam Row/Column.
                Glyph {
                    id: savedCheck
                    visible: !root.dirty
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    name: "check"
                    color: Theme.text
                    width: Theme.icon14
                    height: Theme.icon14
                }

                SettingsText {
                    id: statusText
                    anchors {
                        left: savedCheck.visible ? savedCheck.right : parent.left
                        leftMargin: savedCheck.visible ? Theme.space6 : 0
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Medium
                    text: root.dirty
                        ? root.dirtyCount + (root.dirtyCount === 1 ? " unsaved change" : " unsaved changes")
                        : "Saved"
                }
            }

            Row {
                id: barButtons
                visible: root.dirty
                anchors { right: parent.right; rightMargin: Theme.space6; verticalCenter: parent.verticalCenter }
                spacing: Theme.space6

                Btn { label: "Cancel"; onClicked: root.revert() }
                Btn { label: "Apply"; primary: true; onClicked: root.apply() }
            }
        }
    }
}
