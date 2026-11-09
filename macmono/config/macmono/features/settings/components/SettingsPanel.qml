import QtQuick
import "../../../core"
import "../../../shared/components"

// Isi panel Pengaturan Sistem. Satu tata letak dua-panel: sidebar halaman (selalu tampak) + isi halaman.
// Tidak ada layar utama dan tombol kembali; halaman terakhir yang dibuka diingat selama shell hidup.
// Pencarian selalu ada di atas dan mencari lintas semua halaman (judul halaman ikut dicocokkan,
// jadi "Advanced" atau "Top Bar" tetap ketemu walau tak ada item yang memuat kata itu).
// Tidak tahu apa-apa soal window; features/settings/SettingsApp.qml yang membungkusnya.
//
// Alur: perubahan masuk ke `draft` dulu. Bar "Apply" muncul melayang di bawah hanya saat ada draft;
// "Apply" menulis ke SettingsStore (langsung berlaku tanpa reload shell, tersimpan di
// ~/.config/macmono/settings.json), "Cancel" membuang draft. Setelah Apply bar berganti jadi
// status "Saved" sebentar, supaya jelas perubahan sudah masuk.
//
// Keyboard: Up/Down (di kolom cari) pindah halaman, Esc mundur satu tingkat
// (cari -> draft -> tutup), Ctrl+S terapkan, Ctrl+F fokus ke kolom cari.
FocusScope {
    id: root
    signal closeRequested()
    signal navMoved()   // halaman pindah lewat keyboard (supaya baris sidebar yang aktif ikut tergulung masuk)

    // Id halaman yang sedang dibuka. Selalu terisi (tidak ada layar utama); awalnya halaman pertama.
    property string pageId: SettingsSchema.pages[0].id
    property var draft: ({})

    // "Saved" kecil setelah Apply. Hilang sendiri; sembunyi lagi begitu ada editan baru.
    property bool savedFlash: false
    Timer { id: savedTimer; interval: Theme.settingsSavedMs; onTriggered: root.savedFlash = false }

    readonly property string query: searchInput.text
    readonly property bool searching: query.trim() !== ""
    readonly property bool atPage: !searching   // isi halaman tampil (bukan hasil cari)
    readonly property int dirtyCount: Object.keys(draft).length
    readonly property bool dirty: dirtyCount > 0
    // Bar bawah dipakai bergantian: bar Apply saat ada draft, status "Saved" sesudahnya, sisanya footer hint.
    readonly property bool barShown: dirty || savedFlash

    // Pengelompokan layar utama. Halaman yang belum disebut di sini otomatis masuk grup "More",
    // jadi setiap halaman baru harus didaftarkan di sini — kalau lupa, grup "More" bermunculan sendiri.
    readonly property var navSections: [
        { title: "Personalization", ids: ["appearance", "display", "wallpaper"] },
        { title: "Devices & Input", ids: ["input", "sound", "eq"] },
        { title: "System", ids: ["weather", "notif", "power", "apps"] },
        { title: "MacMono", ids: ["keys", "backup", "about"] }
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
            if (items.length > 0) out.push({ title: p.label, pageId: p.id, pageRows: false, items: items });
        }
        return out;
    }
    readonly property int resultCount: {
        let n = 0;
        for (const g of searchGroups) n += g.items.length;
        return n;
    }
    readonly property var shownGroups: searching ? searchGroups : (currentPage ? currentPage.groups : [])

    // Kolom isi dibatasi lebarnya dan diletakkan di tengah area kanan. Judul halaman ikut
    // sejajar dengan tepi kiri kolom isi, jadi judul dan isi tetap satu garis.
    readonly property real contentW: Math.min(Theme.settingsContentMax, flick.width - Theme.settingsGutter * 2)
    readonly property real contentX: Math.max(Theme.settingsGutter, (flick.width - contentW) / 2)

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

    // Jumlah opsi di halaman yang nilainya (draft ikut dihitung) beda dari bawaan.
    // Dipakai zona "Reset this page": 0 = tombol mati, tidak ada yang perlu di-reset.
    function pageChangedCount(page) {
        if (!page || !page.groups) return 0;
        let n = 0;
        for (const g of page.groups)
            for (const it of g.items)
                if (!it.ro && !it.live && !same(valueOf(it), it.def)) n++;
        return n;
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
        // Opsi yang harus ikut ditulis ke config sistem (Input -> Hyprland, Power -> hypridle).
        const syncs = ({});
        for (const k in draft) {
            const it = SettingsSchema.find(k);
            if (it && it.sync) syncs[it.sync] = true;
        }
        SettingsStore.apply(sets, removes);
        if (syncs.input) Sys.hyprSync.syncInput();
        if (syncs.idle) Sys.hyprSync.syncIdle();
        draft = ({});
        savedFlash = true;
        savedTimer.restart();
    }

    function openPage(id) {
        searchInput.text = "";
        pageId = id;
    }

    // ---- lompat dari hasil pencarian: buka halamannya, gulir ke barisnya, sorot sebentar ----
    property string flashKey: ""        // key baris yang sedang dituju; kosong = tidak ada
    property var pendingReveal: null    // baris yang menunggu animasi masuk halaman selesai

    function jumpTo(id, key) {
        flashKey = "";          // dikosongkan dulu supaya lompat ke key yang sama dua kali tetap memicu
        openPage(id);
        flashKey = key;
    }

    // Enter di kolom cari: lompat ke baris pertama yang cocok; kalau yang cocok cuma halaman, buka halamannya.
    function jumpToFirstResult() {
        for (const g of searchGroups)
            if (!g.pageRows && g.items.length > 0) { jumpTo(g.pageId, g.items[0].key); return; }
        for (const g of searchGroups)
            if (g.pageRows && g.items.length > 0) { openPage(g.items[0].id); return; }
    }

    // Dipanggil baris yang dituju. Gulir baru jalan setelah animasi masuk selesai, supaya posisi baris sudah final.
    function revealRow(entry) {
        pendingReveal = entry;
        if (!pageIntro.running) Qt.callLater(doReveal);
    }
    function doReveal() {
        const e = pendingReveal;
        if (!e) return;
        pendingReveal = null;
        flashKey = "";
        const top = e.mapToItem(flick.contentItem, 0, 0).y;
        const maxY = Math.max(0, flick.contentHeight - flick.height);
        scrollAnim.to = Math.max(0, Math.min(maxY, top - (flick.height - e.height) / 2));
        scrollAnim.restart();
        e.pulse();
    }

    // Up/Down di kolom cari: pindah ke halaman sebelum/sesudahnya (berhenti di ujung, tidak berputar).
    function stepPage(delta) {
        const i = Math.max(0, navIds.indexOf(pageId));
        pageId = navIds[Math.max(0, Math.min(navIds.length - 1, i + delta))];
        navMoved();
    }

    function focusSearch() { searchInput.forceActiveFocus(); }
    // Fokus keyboard panel TANPA masuk ke kolom cari: Esc, Ctrl+S, Ctrl+F, "/" dan panah tetap jalan,
    // tapi tidak ada kursor berkedip / cincin fokus di kolom cari tiap panel dibuka.
    function focusPanel() { root.forceActiveFocus(); }

    // Ganti halaman / mulai mencari: gulir ke atas lalu jalankan animasi masuk konten.
    // Tanpa ini, konten berganti mendadak sementara panel lain semua memakai pegas (Reveal).
    onPageIdChanged: { flick.contentY = 0; pageIntro.restart(); }
    onQueryChanged: { flick.contentY = 0; pageIntro.restart(); }

    Keys.onEscapePressed: {
        if (searching) searchInput.text = "";
        else if (dirty) revert();
        else closeRequested();
    }
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
            apply();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            focusSearch();
            event.accepted = true;
        } else if (event.text === "/" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && !searchInput.activeFocus) {
            focusSearch();   // "/" membuka pencarian (kalau kolom cari sudah fokus, TextInput yang menangani)
            event.accepted = true;
        }
    }
    // Panah atas/bawah pindah halaman juga saat fokus tidak di kolom cari.
    Keys.onUpPressed: if (atPage) stepPage(-1)
    Keys.onDownPressed: if (atPage) stepPage(1)

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

    // Satu baris halaman, dipakai di sidebar (compact) DAN di hasil pencarian "Pages".
    // Sidebar: tanpa chevron dan tanpa garis pemisah, hanya penanda halaman terpilih.
    // Hasil cari: chevron + garis tipis, karena barisnya membawa pengguna ke halaman lain.
    component NavRow: Item {
        id: navRow
        property var page: null
        property int rowIndex: 0
        property bool current: false
        property bool compact: false

        width: parent ? parent.width : 0
        height: Theme.settingsListRowHeight

        Connections {
            target: root
            function onNavMoved() { if (navRow.current && navRow.compact) sideFlick.reveal(navRow); }
        }

        // Terpilih = tileMid, hover = tile (lebih tipis), jadi keduanya tetap bisa dibedakan.
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusXs
            color: navRow.current ? Theme.tileMid : (navArea.containsMouse ? Theme.tile : Theme.transparent)
            Behavior on color { ColorAnimation { duration: Theme.animHover } }
        }

        // Pemisah digambar DI ATAS sorotan: sebelumnya sorotan menutupinya, jadi garisnya
        // berkedip hilang-muncul tiap kursor lewat.
        Rectangle {
            visible: navRow.rowIndex > 0 && !navRow.compact
            z: 2
            x: Theme.settingsRowPadX + Theme.icon16 + Theme.space12
            width: navRow.width - x - Theme.settingsRowPadX
            height: Theme.borderThin
            color: Theme.line
        }

        // Ikon polos tanpa kotak: yang dibaca orang adalah nama halaman, ikon cuma penanda tenang di tepi kiri.
        Item {
            id: iconBox
            x: Theme.settingsRowPadX
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.icon16
            height: Theme.icon16

            Glyph {
                anchors.centerIn: parent
                name: navRow.page ? navRow.page.icon : ""
                color: navRow.current ? Theme.text : Theme.dim
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
            visible: !navRow.compact
            anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
            name: "chevron"
            rotation: -90
            color: Theme.muted
            width: Theme.icon14
            height: Theme.icon14
        }

        SettingsText {
            anchors {
                left: iconBox.right; leftMargin: Theme.space12
                right: navRow.compact ? parent.right : chevron.left
                rightMargin: Theme.space8
                verticalCenter: parent.verticalCenter
            }
            text: navRow.page ? navRow.page.label : ""
            color: (navRow.current || !navRow.compact) ? Theme.text : Theme.textSoft
            font.pixelSize: navRow.compact ? Theme.fontTitle : Theme.fontHeading
            font.weight: Font.Medium
            font.letterSpacing: Theme.settingsRowTracking
            elide: Text.ElideRight
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (navRow.page) root.openPage(navRow.page.id)
        }

        Accessible.role: Accessible.Button
        Accessible.name: navRow.page ? navRow.page.label : ""
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.lineStrong
        clip: true
        // Klik di mana saja selain kolom cari melepas fokus kolom cari (kolom cari ada di atas MouseArea ini).
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: root.forceActiveFocus() }

        // ---- header: judul ........ [kolom cari] [tutup], hanya di atas kolom isi (sidebar punya judulnya sendiri)
        Item {
            id: header
            anchors { top: parent.top; left: sideNav.right; right: parent.right }
            height: Theme.settingsHeaderHeight

            SettingsText {
                id: titleText
                // Satu tepi kiri dengan label grup dan judul baris di bawahnya.
                x: root.contentX + Theme.settingsRowPadX
                width: parent.width - x - Theme.settingsSearchWidth - Theme.icon22 - Theme.space6 - Theme.settingsGutter - Theme.space10 * 2
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.searching ? "Search" : (root.currentPage ? root.currentPage.label : "Settings")
                font.pixelSize: Theme.settingsTitleSize
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.settingsTitleTracking
                // Judul besar pakai desain "display" Inter (sumbu opsz 14-32) supaya tidak longgar.
                // Kalau fontnya bukan variable font, Qt mengabaikan sumbu ini.
                font.variableAxes: ({ "opsz": 32, "wght": Font.DemiBold })
            }

            RoundBtn {
                anchors { right: parent.right; rightMargin: Theme.settingsGutter; verticalCenter: parent.verticalCenter }
                glyph: "close"
                accessibleName: "Close"
                onClicked: root.closeRequested()
            }
        }

        // ---- sidebar halaman: selalu tampak (tidak ada layar utama / tombol kembali).
        // Tanpa permukaan sendiri ("ghost"): hanya satu garis tipis di tepi kanan. Karena tidak ada
        // latar yang bisa menimpa sudut kartu, hack margin radius yang dulu ada tidak perlu lagi
        // (Flickable di bawah tetap menyisakan radiusXl supaya sorotan baris terakhir tidak keluar dari lengkung sudut).
        Item {
            id: sideNav
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: Theme.settingsSideWidth

            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: Theme.borderThin
                color: Theme.line
            }

            // Judul sidebar sejajar dengan judul halaman di sebelahnya.
            Item {
                id: sideTitleBox
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: Theme.settingsHeaderHeight

                SettingsText {
                    anchors { left: parent.left; leftMargin: Theme.space8 + Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
                    text: "Settings"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.settingsRowTracking
                }
            }

            Flickable {
                id: sideFlick
                anchors {
                    top: sideTitleBox.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                    leftMargin: Theme.space8; rightMargin: Theme.space8; bottomMargin: Theme.radiusXl
                }
                contentWidth: width
                contentHeight: sideSections.height + Theme.space16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // dipanggil hanya dari keyboard (stepPage), sama seperti flick.reveal di bawah
                function reveal(item) {
                    const top = item.mapToItem(contentItem, 0, 0).y - Theme.space12;
                    const bottom = top + item.height + Theme.space12 * 2;
                    if (top < contentY) contentY = Math.max(0, top);
                    else if (bottom > contentY + height) contentY = Math.max(0, Math.min(contentHeight - height, bottom - height));
                }

                Column {
                    id: sideSections
                    width: parent.width
                    spacing: Theme.settingsGroupSpacing

                    Repeater {
                        model: root.navGroups
                        delegate: Column {
                            id: sideSection
                            required property var modelData
                            width: sideSections.width
                            spacing: Theme.space4

                            SettingsText {
                                text: sideSection.modelData.title.toUpperCase()
                                color: Theme.labelCapsText
                                font.pixelSize: Theme.labelCapsSize
                                font.weight: Font.DemiBold
                                font.letterSpacing: Theme.labelCapsTracking
                                leftPadding: Theme.settingsRowPadX
                            }

                            Repeater {
                                model: sideSection.modelData.items
                                delegate: NavRow {
                                    required property var modelData
                                    required property int index
                                    compact: true
                                    page: modelData
                                    rowIndex: index
                                    // Saat mencari, tak ada halaman yang ditandai: isi sedang berupa hasil cari.
                                    current: !root.searching && root.pageId === modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- kolom cari (kapsul) di dalam baris header: kanan judul, kiri tombol tutup.
        // Letaknya tetap di semua halaman, jadi tidak ada lagi lompatan antara layar utama dan halaman.
        Rectangle {
            id: searchBox
            anchors {
                top: parent.top; topMargin: (Theme.settingsHeaderHeight - Theme.settingsSearchHeight) / 2
                right: parent.right; rightMargin: Theme.settingsGutter + Theme.icon22 + Theme.space6 + Theme.space10
            }
            width: Theme.settingsSearchWidth
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
                Keys.onUpPressed: if (root.atPage) root.stepPage(-1)
                Keys.onDownPressed: if (root.atPage) root.stepPage(1)
                onAccepted: root.jumpToFirstResult()
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
            anchors { top: header.bottom; topMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space8; left: sideNav.right; right: parent.right }
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
                x: root.contentX
                y: Theme.settingsPadTop
                // Dibatasi dan di tengah: di panel lebar, baris dan slider tidak membentang sampai tepi kanan.
                width: root.contentW
                spacing: Theme.settingsGroupSpacing
                transform: Translate { id: contentShift }

                // -- halaman About: ringkasan komputer
                SettingsAbout {
                    visible: root.atPage && root.currentPage && root.currentPage.about === true
                    width: content.width
                }

                // -- halaman pintasan keyboard (data: core/shortcuts/KeyList.qml, sama dengan Cheatsheet)
                SettingsKeys {
                    visible: root.atPage && root.currentPage && root.currentPage.keys === true
                    width: content.width
                }

                // -- halaman Display: pengaturan monitor (resolusi, refresh rate, skala, rotasi)
                SettingsDisplay {
                    visible: root.atPage && root.currentPage && root.currentPage.monitors === true
                    width: content.width
                }

                // -- pratinjau cuaca di atas halaman Weather; muncul kalau kota sudah dipilih
                SettingsWeatherPreview {
                    visible: root.atPage && root.currentPage && root.currentPage.weather === true && Sys.weather.hasLocation
                    width: content.width
                }

                // -- halaman Weather: lokasi + unit
                SettingsWeather {
                    visible: root.atPage && root.currentPage && root.currentPage.weather === true
                    width: content.width
                }

                // -- halaman Power: profil daya (langsung berlaku)
                SettingsPower {
                    visible: root.atPage && root.currentPage && root.currentPage.power === true
                    width: content.width
                }

                // -- halaman Sound: output, input, volume per aplikasi (langsung berlaku)
                SettingsSound {
                    visible: root.atPage && root.currentPage && root.currentPage.sound === true
                    width: content.width
                }

                // -- halaman Equalizer: band yang bisa digeser + kurva respons (dikirim ke Easy Effects)
                SettingsEqualizer {
                    visible: root.atPage && root.currentPage && root.currentPage.eq === true
                    width: content.width
                }

                // -- halaman Notifications: jadwal DND + mute per aplikasi
                SettingsNotifications {
                    visible: root.atPage && root.currentPage && root.currentPage.notifications === true
                    width: content.width
                }

                // -- halaman Apps & Startup: autostart XDG (dex)
                SettingsApps {
                    visible: root.atPage && root.currentPage && root.currentPage.apps === true
                    width: content.width
                }

                // -- halaman Backup & Reset: simpan/pulihkan settings + reset ke default
                SettingsBackup {
                    visible: root.atPage && root.currentPage && root.currentPage.backup === true
                    width: content.width
                }

                // -- pratinjau Appearance: membaca draft, jadi perubahan langsung kelihatan sebelum Apply
                SettingsAppearancePreview {
                    visible: root.atPage && root.currentPage && root.currentPage.preview === "appearance"
                    width: content.width
                    panelOpacity: root.valueOf(SettingsSchema.find("panelOpacity"))
                    clock24h: root.valueOf(SettingsSchema.find("clock24h"))
                    seconds: root.valueOf(SettingsSchema.find("clockSeconds"))
                    showDate: root.valueOf(SettingsSchema.find("clockDate"))
                }

                // -- wallpaper sekarang + grid pilihan (langsung berlaku, tanpa Apply)
                SettingsWallpaperPreview {
                    visible: root.atPage && root.currentPage && root.currentPage.preview === "wallpaper"
                    width: content.width
                }

                // -- hasil cari: hanya status kosong. Jumlah hasil tidak digambar (kontrak desain R8).
                SettingsText {
                    visible: root.searching && root.resultCount === 0
                    leftPadding: Theme.settingsRowPadX
                    text: "No results for “" + root.query.trim() + "”"
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

                        // Pratinjau per grup (penanda `preview` di schema); tampil tepat di atas barisnya.
                        SettingsTouchpadPreview {
                            visible: root.atPage && group.modelData.preview === "touchpad"
                            width: parent.width
                            natural: root.valueOf(SettingsSchema.find("inputNaturalScroll"))
                            factor: root.valueOf(SettingsSchema.find("inputScrollFactor"))
                        }
                        SettingsPointerPreview {
                            visible: root.atPage && group.modelData.preview === "pointer"
                            width: parent.width
                            sens: root.valueOf(SettingsSchema.find("inputSensitivity"))
                        }
                        SettingsKeyboardPreview {
                            visible: root.atPage && group.modelData.preview === "keyboard"
                            width: parent.width
                            rate: root.valueOf(SettingsSchema.find("inputRepeatRate"))
                            delayMs: root.valueOf(SettingsSchema.find("inputRepeatDelayMs"))
                        }
                        // Perkiraan warna layar; Kelvin dibaca dari draft.
                        SettingsNightPreview {
                            visible: root.atPage && group.modelData.preview === "night"
                            width: parent.width
                            warmKelvin: root.valueOf(SettingsSchema.find("nightLightKelvin"))
                            normalKelvin: root.valueOf(SettingsSchema.find("nightLightOffKelvin"))
                            active: Sys.nightLight
                        }
                        SettingsSleepPreview {
                            visible: root.atPage && group.modelData.preview === "sleep"
                            width: parent.width
                            lockMin: root.valueOf(SettingsSchema.find("idleLockMin"))
                            offMin: root.valueOf(SettingsSchema.find("idleScreenOffMin"))
                            suspendMin: root.valueOf(SettingsSchema.find("idleSuspendMin"))
                        }
                        SettingsAlertPreview {
                            visible: root.atPage && group.modelData.preview === "alert"
                            width: parent.width
                            warnLevels: root.valueOf(SettingsSchema.find("batteryWarnLevels"))
                            criticalLevel: root.valueOf(SettingsSchema.find("batteryCriticalLevel"))
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
                                        // Di hasil cari, judul baris jadi tautan: lompat ke halaman aslinya dan sorot barisnya.
                                        titleLink: root.searching
                                        onTitleClicked: root.jumpTo(group.modelData.pageId, modelData.key)
                                        readonly property bool wanted: root.flashKey !== "" && modelData.key === root.flashKey
                                        onWantedChanged: if (wanted) root.revealRow(entry)
                                        Component.onCompleted: if (wanted) root.revealRow(entry)
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

                // -- halaman: zona reset di akhir halaman (dua ketukan); deskripsi halaman tidak digambar
                // (teksnya tetap ada di schema karena dipakai pencarian).
                SettingsResetPage {
                    visible: root.atPage && root.pageResettable(root.currentPage)
                    width: content.width
                    pageKey: root.pageId
                    changedCount: root.pageChangedCount(root.currentPage)
                    onConfirmed: root.resetPage()
                }
            }
        }

        // Animasi masuk konten (fade + geser 6 px), dipicu onPageIdChanged / onQueryChanged.
        // Sengaja di luar Flickable: dia bukan Item, jadi tidak ikut ditata Column.
        ParallelAnimation {
            id: pageIntro
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
            NumberAnimation { target: contentShift; property: "y"; from: Theme.space6; to: 0; duration: Theme.animBase; easing.type: Theme.easeOut }
            onFinished: root.doReveal()   // lompat dari hasil cari menunggu posisi baris final
        }
        NumberAnimation { id: scrollAnim; target: flick; property: "contentY"; duration: Theme.animSlow; easing.type: Theme.easeOut }

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

            anchors { left: sideNav.right; right: parent.right; bottom: parent.bottom; leftMargin: Theme.settingsGutter; rightMargin: Theme.settingsGutter; bottomMargin: Theme.settingsGutter }
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
