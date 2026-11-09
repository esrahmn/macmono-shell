pragma Singleton

import QtQuick
import Quickshell
import "../settings"

// ============================================================================
//  THEME macmono: SATU-SATUNYA tempat definisi TAMPILAN (warna, ukuran, animasi).
//
//  Aturan:
//   - File QML lain cukup pakai Theme.<nama>. Jangan tulis warna / radius / ukuran
//     font / durasi animasi mentah di sana.
//   - Butuh nilai baru? Tambah token di file ini (lengkap dengan komentar), baru dipakai.
//   - Mau ganti tampilan? Edit di sini, lalu reload shell (Ctrl+Super+R).
//   - Perilaku yang bisa lu atur (timeout, jumlah item, daftar app, dst.) ada di
//     core/settings/Settings.qml, BUKAN di sini.
//
//  Semua warna sengaja abu-abu murni (R=G=B). Nggak ada satu pun warna beraksen.
//
//  Daftar isi:  1 Font   2 Spacing   3 Warna   4 Animasi   5 Opasitas
//               6 Ukuran umum   7 Radius & border   8 Ukuran ikon & ukuran per komponen
// ============================================================================
Singleton {
    // ====================================================================
    //  1. FONT
    // ====================================================================
    // Inter dari paket Arch/CachyOS terdaftar sebagai "Inter Variable", bukan "Inter".
    // Ambil nama yang benar-benar terpasang supaya Qt nggak diam-diam jatuh ke Noto Sans.
    readonly property string font: {
        const fams = Qt.fontFamilies();
        for (const f of ["Inter", "Inter Variable", "Inter Var", "Inter Display"])
            if (fams.indexOf(f) >= 0) return f;
        return "Inter";
    }
    readonly property string fontMono: "monospace"   // font untuk teks monospasi (kode, angka sejajar)

    // Skala ukuran font (px). Pilih berdasarkan peran teksnya.
    readonly property int fontMicro: 10       // label super kecil (9 px terlalu kecil di layar 1080p)
    readonly property int fontCaption: 11     // keterangan kecil (dulu 10: selisih 1 px dari fontSmall tak terbaca)
    readonly property int fontSmall: 11       // teks sekunder
    readonly property int fontBody: 12        // teks isi standar
    readonly property int fontBodyLg: 13      // teks isi agak besar
    readonly property int fontSubtitle: 14    // sub-judul
    readonly property int fontTitle: 15       // judul kecil
    readonly property int fontHeading: 16     // judul bagian
    readonly property int fontLead: 18        // teks pembuka / sorotan
    readonly property int fontDisplay: 30     // angka / judul besar
    // Ukuran khusus untuk jam, angka besar, dan judul di komponen tertentu.
    readonly property int fontHeadingLg: 17
    readonly property int fontDisplaySm: 19
    readonly property int fontDisplayMd: 22
    readonly property int fontHero: 26
    readonly property int fontClock: 84       // jam raksasa di lock screen
    readonly property int fontEmoji: 24       // glyph emoji di picker (bukan teks UI)

    // Jarak antar-baris untuk teks yang dibaca sebagai kalimat, bukan label satu baris.
    // Dua jebakan yang sudah ketemu di proyek ini:
    //  1. TextEdit TIDAK punya properti lineHeight — memasangnya bikin shell gagal load.
    //  2. Bawaan Text.lineHeightMode itu ProportionalHeight, jadi lineHeight berisi PENGALI.
    // Pakai selalu: lineHeightMode: Text.FixedHeight; lineHeight: Math.round(fontX * lineY)
    // Kalau lupa mode-nya, angka 22 dibaca sebagai 22x tinggi font dan kartu melar ratusan px.
    readonly property real lineTight: 1.15    // judul / label rapat
    readonly property real lineBody: 1.32     // teks isi
    readonly property real lineProse: 1.45    // paragraf panjang (preview clipboard, body notifikasi)

    // ====================================================================
    //  2. SPACING
    // ====================================================================
    // Skala jarak layout (px). Pakai untuk Row/Column/Layout.spacing, margins, padding.
    // Angka di nama = nilainya (space16 = 16 px).
    readonly property int space0: 0
    readonly property int space1: 1
    readonly property int space2: 2
    readonly property int space3: 3
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space7: 7
    readonly property int space8: 8
    readonly property int space10: 10
    readonly property int space12: 12
    readonly property int space14: 14
    readonly property int space16: 16
    readonly property int space18: 18
    readonly property int space22: 22
    readonly property int space30: 30

    // ====================================================================
    //  3. WARNA
    // ====================================================================
    // ---- permukaan
    // Bar, panel, dan popup SATU warna; keburamannya dari Settings.panelOpacity
    // (biar nyatu dengan top bar). Dibatasi 0.25..1 supaya blur Hyprland tetap hidup.
    readonly property color bar: Qt.rgba(0, 0, 0, Math.max(0.25, Math.min(1, Settings.panelOpacity)))   // menubar
    readonly property color panel: bar                             // kartu/panel utama (CC, launcher, clipboard, kalender, dll.)
    readonly property color popup: bar                             // popup kecil: tray menu, OSD
    readonly property color raised: Qt.rgba(0.16, 0.16, 0.16, 0.95) // kartu yang "terangkat" (mis. kartu window di overview)
    readonly property color canvas: "#0b0b0b"                      // dasar wallpaper
    readonly property color black: "#000000"                       // hitam murni (latar jendela screenshot)
    readonly property color transparent: "transparent"             // area tanpa isi visual

    // ---- lapisan hitam transparan
    readonly property color powerScrim: Qt.rgba(0, 0, 0, 0.55)  // peredup layar Power Menu (di atas blur compositor), supaya terbaca di wallpaper terang
    readonly property color veil: Qt.rgba(0, 0, 0, 0.01)   // nyaris transparan, cuma buat area klik / area blur
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)  // peredup layar (region selector)
    readonly property color inset: Qt.rgba(0, 0, 0, 0.30)  // kotak "cekung": input, preview
    readonly property color badge: Qt.rgba(0, 0, 0, 0.75)  // label di atas gambar

    // ---- tile / hover (putih transparan, makin besar = makin terang)
    readonly property color tileFaint: Qt.rgba(1, 1, 1, 0.06)  // hover tipis, tile redup
    readonly property color tile: Qt.rgba(1, 1, 1, 0.08)       // tile default
    readonly property color tileMid: Qt.rgba(1, 1, 1, 0.11)    // tile terpilih / hover sedang
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.15)  // hover kuat / state aktif
    readonly property color tileStrong: Qt.rgba(1, 1, 1, 0.22) // hover pada kontrol bulat kecil
    readonly property color selection: Qt.rgba(1, 1, 1, 0.30)  // blok seleksi teks

    // ---- garis
    readonly property color line: Qt.rgba(1, 1, 1, 0.08)        // border halus
    readonly property color lineStrong: Qt.rgba(1, 1, 1, 0.12)  // border menonjol
    readonly property color lineFocus: Qt.rgba(1, 1, 1, 0.35)   // border saat fokus

    // ---- teks
    readonly property color text: "#ffffff"                   // teks utama
    readonly property color textSoft: Qt.rgba(1, 1, 1, 0.80)   // teks sekunder yang masih jelas
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)        // teks redup / ikon nonaktif
    readonly property color muted: Qt.rgba(1, 1, 1, 0.40)      // teks sangat redup (placeholder); 0.30 tak terbaca di wallpaper terang
    readonly property color ghost: Qt.rgba(1, 1, 1, 0.10)      // teks watermark (angka workspace di overview)
    readonly property color faint: Qt.rgba(1, 1, 1, 0.30)      // teks tersier / garis halus; 0.20 hilang di panel terang

    // ---- state terpilih/aktif (putih solid, teks hitam di atasnya)
    readonly property color inverse: "#ffffff"                     // latar tombol aktif
    readonly property color inverseText: "#000000"                 // teks di atas latar putih
    readonly property color inverseHover: Qt.rgba(1, 1, 1, 0.85)   // hover pada tombol putih
    readonly property color inverseDim: Qt.rgba(0, 0, 0, 0.55)     // teks redup di atas putih
    readonly property color inverseTile: Qt.rgba(0, 0, 0, 0.08)    // tile di atas putih

    // ---- peran permukaan: pakai dua token ini di UI, jangan pilih warna mentah.
    // Hierarki tiga lapis: panel (Theme.panel) -> kartu terangkat (Theme.tile) -> kotak cekung.
    // well = kotak cekung berisi konten panjang (daftar Wi-Fi/BT) supaya terasa masuk ke panel.
    // Sengaja BUKAN alias inset: hitam 14% cuma menggelapkan sedikit, jadi tingkat transparansi
    // panel (Settings.panelOpacity) masih terasa sama dengan top bar. inset (30%) tetap dipakai
    // untuk preview / kotak input yang memang harus jauh lebih gelap.
    readonly property color well: Qt.rgba(0, 0, 0, 0.14)
    // cardStroke = garis tipis di kartu yang menempel di panel, supaya kartu terangkat jelas.
    readonly property color cardStroke: line

    // ====================================================================
    //  4. ANIMASI
    // ====================================================================
    // Durasi (ms). Pilih berdasarkan PERAN animasinya, jangan angka mentah.
    readonly property int animPress: 90    // feedback sentuh: scale tombol, bar OSD
    readonly property int animHover: 130   // hover & perubahan warna kecil
    readonly property int animFade: 160    // fade opacity
    readonly property int animBase: 200    // buka/tutup panel, expand/collapse, slide, rotasi
    readonly property int animSlow: 300    // transisi lambat (fade wallpaper)
    readonly property int animPulse: 600   // denyut berulang (titik rekam)
    readonly property int animScroll: 360  // scroll programatik (lirik, daftar panjang)
    readonly property real buttonPressedScale: 0.97   // tombol mengecil sedikit saat ditekan

    // Kurva easing
    readonly property int easeOut: Easing.OutCubic   // masuk / buka
    readonly property int easeIn: Easing.InCubic     // keluar / tutup

    // Animasi pegas modal lama (Power menu, Cheatsheet, OSD). Diambil dari token spatialDefault Iridium.
    readonly property real springStiff: 4.8          // makin besar makin cepat/kaku
    readonly property real springDamp: 0.4           // makin kecil makin memantul (1 = tanpa pantulan)

    // Panel "laci" yang keluar dari bar (control center, kalender, media, tray menu, launcher,
    // clipboard, emoji) dianimasikan oleh shared/components/Reveal.qml: pegas fisik redaman kritis (tanpa pantulan).
    // Kekakuan = kecepatan (naikkan = lebih cepat, turunkan = lebih santai). Perkiraan waktu sampai 90% jalan:
    //   stiff 240 -> ~255 ms,   stiff 420 -> ~200 ms
    // Saat ini buka dan tutup sama-sama 420. Mau buka lebih santai? Coba revealOpenStiff 240.
    readonly property real revealOpenStiff: 420      // kecepatan BUKA laci
    readonly property real revealCloseStiff: 420     // kecepatan TUTUP laci
    // 1.0 = mulus tanpa pantulan; di bawah 1 mulai memantul (0.8 = sedikit mental).
    readonly property real revealDamp: 1.0
    readonly property real drawerGap: 2              // jarak akhir kartu dari bar (px)

    // Animasi buka panel kecil/modal: turun dari bar + sedikit memantul di akhir
    readonly property int animOpen: 280              // durasi buka panel
    readonly property int easeOpen: Easing.OutBack   // kurva buka (memantul)
    readonly property real openOvershoot: 1.2        // kuat pantulan (1.0 halus, 1.7 default Qt)
    readonly property real openDrop: 24              // px panel turun dari atas
    readonly property real openScaleFrom: 0.9        // skala awal panel kecil
    readonly property real openScaleFromModal: 0.94  // skala awal panel modal

    // ====================================================================
    //  5. OPASITAS
    // ====================================================================
    readonly property real opacityDisabled: 0.4   // kontrol nonaktif
    readonly property real opacityDim: 0.72       // item yang diredupkan sampai di-hover / dipilih
    readonly property real openFromPanel: 0.4     // opasitas awal animasi buka panel kecil (harus > ignore_alpha 0.2 di rules.lua)
    readonly property real openFromModal: 0.65    // opasitas awal animasi buka panel modal (harus > ignore_alpha 0.5 di rules.lua)

    // ====================================================================
    //  6. UKURAN UMUM
    // ====================================================================
    readonly property int barHeight: 39    // tinggi top bar (px)
    readonly property int barMargin: 6     // jarak top bar dari tepi layar

    // ====================================================================
    //  7. RADIUS & BORDER
    // ====================================================================
    // Skala radius (px) untuk kartu, panel, dan tombol bersegi.
    // Elemen BULAT atau PIL (lingkaran, kapsul, bar tipis) jangan pakai token ini:
    // tulis `radius: Math.min(width, height) / 2` supaya tetap bulat walau ukurannya berubah.
    readonly property int radiusXs: 8       // tombol kecil, chip
    readonly property int radiusSmall: 8    // baris daftar (dulu 10: 2 px dari radiusXs tak terlihat)
    readonly property int radiusMedium: 12  // tombol sedang
    readonly property int radiusCard: 12    // kartu kecil (dulu 14: disejajarkan dengan radiusMedium)
    readonly property int radius: 16        // kartu standar
    readonly property int radiusLarge: 20   // kartu besar, kolom search
    readonly property int radiusPanel: 22   // panel utama
    readonly property int radiusXl: 22      // dulu 28: semua panel utama (CC, launcher, wallpaper
                                            // picker, lock) kini ikut radiusPanel supaya sudut seragam
    // Detail kecil
    readonly property int radiusKey: 6         // keycap / badge tombol keyboard
    readonly property int radiusIndicator: 2   // kotak indikator kecil (ikon stop, bingkai seleksi)

    // Ketebalan garis/border yang dipakai lintas komponen.
    readonly property int borderThin: 1     // garis halus & pemisah
    readonly property int borderStrong: 2   // garis tebal
    readonly property int borderNone: 0

    // ====================================================================
    //  8. UKURAN IKON & UKURAN PER KOMPONEN
    //  Dimensi layout tiap panel. Ubah di sini kalau mau panel lebih lebar / baris lebih tinggi.
    //  Urutan blok: ikon -> notifikasi -> Control Center -> daftar -> media -> kalender ->
    //  clipboard -> emoji -> launcher -> menubar -> OSD -> power -> screenshot -> tray -> wallpaper -> lock.
    // ====================================================================

    // ---- Command Palette (Super+K)
    readonly property int commandPaletteWidth: 680
    readonly property int commandPaletteMaxHeight: 620
    readonly property int commandPaletteSearchHeight: 64
    readonly property int commandPaletteCategoryHeight: 42
    readonly property int commandPaletteRowHeight: 46
    readonly property int commandPalettePadding: 20

    // ---- cheatsheet (Super+/), sidebar kiri
    readonly property int cheatsheetWidth: 440         // lebar sidebar
    readonly property int cheatsheetPadding: 20        // padding dalam kartu
    readonly property int cheatsheetGroupSpacing: 22   // jarak antar grup
    readonly property int cheatsheetRowHeight: 26      // tinggi satu baris shortcut
    readonly property int cheatsheetKeycapHeight: 22   // tinggi keycap
    readonly property int cheatsheetKeycapMinWidth: 22 // lebar minimum keycap
    readonly property int cheatsheetKeycapPadding: 12  // padding kiri-kanan keycap
    readonly property real cheatsheetSectionLetterSpacing: 1.2  // renggang huruf judul grup

    readonly property int icon11: 11  // ikon kecil di pil menubar
    readonly property int icon13: 13  // chevron, ikon kecil di tombol / baris daftar
    readonly property int icon14: 14  // centang & ikon sampah di daftar
    readonly property int icon15: 15  // ikon pencarian kecil, tombol navigasi kalender, ikon tombol media kecil
    readonly property int icon16: 16  // ikon standar di baris / tombol
    readonly property int icon17: 17  // ikon baris hasil launcher
    readonly property int icon18: 18  // ikon menubar (wifi, volume, baterai), ikon tile Control Center
    readonly property int icon20: 20  // ikon logo menubar, OSD, tile toggle; ukuran bawaan Glyph
    readonly property int icon22: 22  // ikon besar: kolom search launcher, ActionTile, tombol media lock
    readonly property int icon30: 30  // ikon cuaca besar di kartu kalender

    // ---- Notifikasi pop-up (features/notifications/Notifs.qml)
    // Tinggi & lebar kartu notifikasi dihitung dari token di bawah ini, bukan dari angka
    // yang ditulis di layout. Mau kartu lebih lebar/pendek/lega? Ubah di sini saja.
    readonly property int notifWidth: 420         // lebar kolom notifikasi di pojok kanan atas
    readonly property int notifPadX: 16           // padding kiri/kanan di dalam kartu
    readonly property int notifPadTop: 20         // padding atas di dalam kartu
    readonly property int notifPadBottom: 18      // padding bawah di dalam kartu
    readonly property int notifMinHeight: 0       // tinggi minimum kartu (0 = ikut isi saja)
    readonly property int notifMaxHeight: 320     // batas atas tinggi kartu; body dibatasi 3 baris
    readonly property int notifImageSize: 56      // ukuran gambar / ikon aplikasi di kartu
    readonly property int notifImageGap: 14       // jarak gambar ke kolom teks
    readonly property int notifCloseSize: 28      // area klik tombol tutup (X)
    readonly property int notifActionHeight: 40   // tinggi tombol aksi notifikasi
    readonly property int notifTextInset: 46      // jarak teks dari tepi kanan kartu (ruang untuk tombol tutup)
    readonly property int notifSlideFrom: 56      // jarak geser vertikal masuk/keluar (px dari atas bar)
    readonly property int notifDismissDelay: 280  // jeda (ms) sebelum notifikasi dibuang setelah aksi, selaras animasi keluar

    // ---- Control Center (features/controlCenter/ControlCenter.qml + components/Cc*.qml)
    readonly property int ccWidth: 500             // lebar kartu Control Center
    readonly property int ccCardPadding: 32        // total padding vertikal kartu (dipakai untuk menghitung tinggi maksimum)
    readonly property int ccAvatarSize: 40         // foto profil di header
    readonly property int ccHeaderButtonSize: 38   // tombol bulat di header (lock, power, dst.)
    readonly property int ccProfileTileWidth: 72   // lebar tile samping di baris toggle
    readonly property int ccToggleTileHeight: 92   // tinggi tile toggle (Focus, Keep Awake, Night Light, dst.)
    readonly property int ccNetworkTileHeight: 56  // tinggi tile Wi-Fi / Bluetooth
    readonly property int ccNetworkIconCircle: 36  // lingkaran ikon di tile Wi-Fi / Bluetooth
    readonly property int ccSliderLabelWidth: 38   // lebar label persen di sebelah slider
    readonly property int ccSliderButtonSize: 26   // tombol kecil di ujung slider (pilih output audio)
    readonly property int sliderHeight: 38         // tinggi SliderBar
    readonly property int actionTileHeight: 78     // tinggi ActionTile (tombol aksi di Tools panel)
    readonly property int toolsSegmentHeight: 32   // tinggi segmen pilihan (mode rekam / audio)
    readonly property int toolsRecordHeight: 38    // tinggi tombol Start Recording

    // ---- Daftar di dalam Control Center (components/WifiList, BtList, DetailList)
    readonly property int listHeaderHeight: 34     // tinggi judul bagian (Wi-Fi, DetailList)
    readonly property int listSubheaderHeight: 26  // tinggi sub-judul bagian (Known, Available, dst.)
    readonly property int listRowHeight: 46        // tinggi satu baris jaringan / perangkat
    readonly property int listFooterHeight: 40     // tinggi baris tombol di bawah daftar
    readonly property int listActionHeight: 28     // tinggi tombol kecil di daftar (Settings…, Connect)
    readonly property int detailRowHeight: 44      // tinggi baris di DetailList
    readonly property int wifiPasswordHeight: 32   // tinggi kolom password Wi-Fi
    readonly property int wifiShowPwWidth: 28      // lebar tombol show/hide password
    readonly property int wifiShowPwHeight: 24     // tinggi tombol show/hide password
    readonly property int wifiJoinWidth: 64        // lebar tombol Join
    readonly property int wifiJoinHeight: 32       // tinggi tombol Join
    readonly property int btHeaderHeight: 36       // tinggi judul bagian Bluetooth
    readonly property int btHintHeight: 64         // tinggi blok pesan kosong / petunjuk Bluetooth
    readonly property int btToggleHeight: 30       // tinggi tombol On/Off Bluetooth

    // ---- Media (components/MediaPlayerView, modules/MediaPopup)
    readonly property int mediaPopupWidth: 500         // lebar popup media (Super+M)
    readonly property int mediaPopupLyricsHeight: 240  // tinggi area lirik di popup media
    readonly property int mediaPosterTitleSize: 24     // judul lagu gaya poster (popup media)
    readonly property int mediaPosterTitleSizeCompact: 20  // judul poster di kartu media Control Center
    readonly property int mediaArtSizeSmall: 44        // sampul kecil di pojok (popup media)
    readonly property int mediaProgressHairline: 2     // garis progress tipis (popup media)
    readonly property int mediaProgressRow: 10         // tinggi baris progress (area sentuh)

    // ---- Kalender & notifikasi (modules/Calendar.qml)
    readonly property int calendarWidth: 420         // lebar kartu kalender
    readonly property int calendarNavSize: 32        // tombol bulan sebelumnya / berikutnya
    readonly property int calendarWeekdayHeight: 30  // tinggi baris nama hari
    readonly property int calendarDayHeight: 46      // tinggi satu sel tanggal
    readonly property int calendarDayCircle: 40      // diameter lingkaran penanda hari ini / terpilih
    readonly property int calendarSmallButton: 28    // tombol Do Not Disturb
    readonly property int calendarClearHeight: 26    // tinggi tombol Clear

    // ---- Clipboard (modules/Clipboard.qml)
    readonly property int clipHeaderHeight: 62    // tinggi header
    readonly property int clipClearHeight: 34     // tinggi tombol Clear all
    readonly property int clipSearchWidth: 270    // lebar kolom cari
    readonly property int clipSearchHeight: 36    // tinggi kolom cari
    readonly property int clipFooterHeight: 40    // tinggi footer petunjuk tombol
    readonly property int clipKeyHeight: 20       // tinggi keycap di footer
    readonly property int clipListWidth: 330      // lebar daftar riwayat (kiri)
    readonly property int clipRowHeight: 54       // tinggi satu baris riwayat
    readonly property int clipTypeIconSize: 32    // kotak ikon tipe (teks / gambar)
    readonly property int clipTrashSize: 26       // area klik tombol hapus
    readonly property int clipPaneHeadHeight: 30  // tinggi judul panel detail (kanan)
    readonly property int clipPaneChipHeight: 28  // tinggi chip di panel detail

    // ---- Emoji picker (modules/EmojiPicker.qml)
    readonly property int emojiTitleHeight: 28     // tinggi baris judul
    readonly property int emojiSearchHeight: 40    // tinggi kolom cari
    readonly property int emojiCategoryHeight: 28  // tinggi bar kategori
    readonly property int emojiCellSize: 40        // ukuran satu sel emoji
    readonly property int emojiScrollbarWidth: 3   // lebar scrollbar tipis
    readonly property int emojiFooterHeight: 34    // tinggi footer
    readonly property int emojiKeyHeight: 22       // tinggi keycap di footer

    // ---- Launcher (modules/Launcher.qml)
    readonly property int launcherSearchHeight: 62    // tinggi kolom search
    readonly property int launcherHintHeight: 24      // tinggi chip petunjuk di kolom search
    readonly property int launcherPinHeight: 108      // tinggi satu sel app Pinned
    readonly property int launcherPinIconBox: 64      // kotak latar ikon app Pinned
    readonly property int launcherPinIcon: 42         // ikon app di dalam kotak Pinned
    readonly property int launcherSectionHeight: 16   // tinggi label bagian (WORKSPACES, dst.)
    readonly property int launcherTagHeight: 22       // tinggi tag kecil di ujung baris hasil
    readonly property int launcherPreviewWidth: 500   // lebar panel preview hasil terpilih
    readonly property int launcherPreviewPadding: 32  // total padding vertikal panel preview
    readonly property int launcherPreviewIcon: 64     // ikon besar di preview
    readonly property int launcherPreviewGlyph: 40    // glyph besar di preview (aksi / kalkulator)
    readonly property int launcherPreviewRow: 40      // tinggi tombol aksi di preview

    // ---- Menubar (modules/MenuBar.qml)
    readonly property int menubarCellHeight: 16      // tinggi area workspace dots
    readonly property int menubarTrayItem: 23        // area klik satu ikon tray
    readonly property int menubarRecHeight: 22       // tinggi pil indikator rekam
    readonly property int menubarPrivHeight: 20      // tinggi pil indikator privasi (kamera / mic)
    readonly property int menubarTitleMaxWidth: 300  // lebar maksimum judul window aktif (lebih dari ini dipotong …)
    readonly property int wsDotWide: 20              // lebar titik workspace AKTIF saat deretan terbuka (hover)
    readonly property int wsDotNarrow: 7             // lebar titik workspace biasa saat deretan terbuka
    readonly property int wsDotCompact: 8            // lebar titik workspace aktif saat deretan menutup
    readonly property real opacityHover: 0.7         // opasitas ikon logo saat di-hover

    // ---- OSD volume / kecerahan (modules/Osd.qml)
    readonly property int osdWidth: 240        // lebar pil OSD
    readonly property int osdHeight: 56        // tinggi pil OSD
    readonly property int osdSlideFrom: 48     // jarak geser vertikal dari atas bar (px)
    readonly property int osdBottomMargin: 90  // legacy (OSD sekarang di atas, di bawah bar)
    readonly property int osdLabelWidth: 34    // lebar label persen
    readonly property int osdTrackHeight: 6    // tebal bar level

    // ---- Power menu (modules/PowerMenu.qml)
    readonly property int powerButtonSize: 84  // diameter tombol bulat (Lock, Sleep, dst.)
    readonly property int powerGlyphSize: 30   // ikon di dalam tombol

    // ---- Pemilih area screenshot (modules/RegionSelector.qml)
    readonly property int selectorBadgeHeight: 24  // tinggi label ukuran area
    readonly property int selectorHintHeight: 34   // tinggi pil petunjuk di bawah layar

    // ---- Tray menu (modules/TrayMenu.qml)
    readonly property int trayBackHeight: 30  // tinggi tombol Back di submenu
    readonly property int trayCheckWidth: 14  // lebar kolom centang / radio

    // ---- Wallpaper picker (modules/Wallpaper.qml)
    readonly property int wpPillTop: 52            // posisi pil judul dari atas layar
    readonly property int wpPillHeight: 40         // tinggi pil judul
    readonly property int wpTrayHeight: 200        // tinggi tray filmstrip di bawah
    readonly property int wpTrayMargin: 24         // jarak tray dari tepi layar (kiri, kanan, bawah)
    readonly property int wpBadgeHeight: 18        // tinggi badge 'Current' di thumbnail
    readonly property int wpChipHeight: 28         // tinggi chip Cancel / Apply di pil judul
    readonly property int wpChipDefaultHeight: 30  // tinggi bawaan komponen Chip filter
    readonly property int wpCloseDelay: 170        // jeda (ms) sebelum picker benar-benar ditutup, supaya animasi keluar selesai

    // ---- Lock screen (lock/*.qml)
    readonly property int lockPasswordWidth: 260      // lebar garis kolom password lock
    readonly property int lockDateSize: 14            // tanggal KAPITAL di atas jam lock
    readonly property real lockDateTracking: 3.1      // 0.22em dari 14 px
    readonly property real lockClockTracking: -6      // huruf rapat jam lock (0.05em dari 120 px)
    readonly property real lockClockTopRatio: 0.09    // jarak jam dari atas layar (rasio tinggi layar)
    readonly property real lockInputBottomRatio: 0.1  // jarak kolom password dari bawah layar (rasio tinggi layar)
    readonly property real lockWallpaperDim: -0.3     // peredup wallpaper di lock (negatif = lebih gelap)
    readonly property int lockShakeAmplitude: 12      // jarak getar kolom password saat salah (px)
    readonly property int lockShakeAmplitudeSoft: 8   // jarak getar ketiga (peredaman)
    readonly property int animShakeFast: 50           // durasi ayunan getar pertama & terakhir
    readonly property int animShakeMid: 60            // durasi ayunan getar ketiga
    readonly property int animShakeSlow: 70           // durasi ayunan getar kedua

    // ---- Pengaturan Sistem (features/settings/SettingsApp.qml + components/Settings*.qml)
    readonly property int settingsWidth: 1100        // lebar drawer Settings; responsif mengikuti lebar monitor
    readonly property int settingsHeight: 900       // tinggi maksimum drawer; tetap di bawah top bar
    // Tata letak Pengaturan cuma punya DUA tepi vertikal. Tepi luar = judul, kolom cari, kartu (settingsGutter).
    // Tepi dalam = judul baris dan label grup (settingsGutter + settingsRowPadX). Jangan taruh elemen di jarak lain.
    readonly property int settingsGutter: 16           // tepi luar kiri/kanan
    readonly property int settingsHeaderHeight: 64     // tinggi header; 64 memberi ruang judul 28 px tanpa menempel ke kolom cari
    readonly property int settingsListRowHeight: 44    // tinggi baris daftar halaman; satu baris judul 16 px, tanpa kotak ikon
    readonly property int settingsContentMax: 720      // lebar maksimum kolom isi: slider dan baris tidak lagi melebar ke seluruh panel (mockup memakai 560)
    readonly property int settingsSideWidth: 264       // lebar sidebar halaman; cukup untuk "Keyboard Shortcuts" tanpa terpotong (dulu 232)
    // Arah "editorial": label grup kecil dan renggang, judul halaman besar dan rapat. Kontras skala ini
    // yang jadi ciri panel — bukan bentuk kartu. Angka tracking dalam px (Qt memakai px, bukan em).
    // Label KAPITAL di semua permukaan (grup pengaturan, "PINNED"/"WORKSPACES" di launcher,
    // judul bagian cheatsheet). Satu token supaya tidak ada lagi 10/13 px bercampur.
    readonly property int labelCapsSize: 10
    readonly property real labelCapsTracking: 2.2      // 0.22em dari 10 px
    readonly property int settingsTitleSize: 28        // judul header halaman
    readonly property int panelTitleSize: settingsTitleSize             // judul semua panel (kontrak R4)
    readonly property real panelTitleTracking: settingsTitleTracking
    readonly property real settingsTitleTracking: -0.9 // -0.03em: Inter 28 px terasa longgar tanpa ini
    readonly property real settingsRowTracking: -0.2   // judul baris sedikit dirapatkan supaya sebaris dengan ikon
    readonly property int settingsBarHeight: 44        // tinggi bar perubahan yang melayang di bawah
    readonly property color settingsBarFill: Qt.rgba(0.11, 0.11, 0.11, 0.96)   // bar melayang: hampir solid supaya isi di bawahnya tidak tembus
    readonly property color settingsDescText: Qt.rgba(1, 1, 1, 0.62)           // deskripsi baris (dim 0.55 terlalu tipis di wallpaper terang)
    readonly property color labelCapsText: Qt.rgba(1, 1, 1, 0.50)             // label KAPITAL; direnggangkan, jadi boleh lebih pudar tanpa hilang
    // ---- Halaman About (features/settings/components/SettingsAbout.qml) ----
    // Semua ukuran khusus halaman About ada di sini, supaya tampilannya bisa disetel tanpa menyentuh QML.
    readonly property int aboutContentMax: 640         // lebar maksimum kolom About; kartu 2x2 butuh ±300 px per kolom
    readonly property int aboutHeroGap: 36             // jarak layar laptop ke nama komputer
    readonly property int aboutLaptopWidth: 260        // lebar layar laptop bergaris di hero
    readonly property int aboutLaptopHeight: 162       // tinggi layar (rasio 16:10)
    readonly property int aboutLaptopBaseWidth: 288    // lebar alas; lebih lebar dari layar (14 px tiap sisi) seperti keyboard deck. Tepi kiri alas = tepi kiri kolom halaman
    readonly property int aboutLaptopBaseHeight: 11    // tinggi alas
    readonly property int aboutLaptopBezel: 3          // tebal bezel; tipis, supaya tidak terbaca sebagai TV
    readonly property int aboutLaptopCutoutWidth: 44   // poni kamera di tengah tepi atas layar (bentuk MacBook)
    readonly property int aboutLaptopCutoutHeight: 7
    readonly property int aboutLaptopNotch: 60         // lebar lekukan jari di tengah alas
    readonly property int aboutLaptopNotchDepth: 3     // kedalaman lekukan itu
    readonly property color aboutLaptopBezelFill: Qt.rgba(0.04, 0.04, 0.04, 0.92)   // bezel + poni hampir hitam: wallpaper di layar jadi menonjol
    readonly property color aboutLaptopBaseTop: Qt.rgba(1, 1, 1, 0.30)              // alas: terang di tepi atas (kena cahaya) ...
    readonly property color aboutLaptopBaseBottom: Qt.rgba(1, 1, 1, 0.13)           // ... redup di tepi bawah
    readonly property int aboutNameSize: 24            // nama komputer; sengaja di bawah judul halaman (settingsTitleSize 28)
    readonly property real aboutNameTracking: -0.5     // rapat, sama prinsipnya dengan judul halaman
    readonly property int aboutSectionGap: 32          // jarak ke label HARDWARE / SOFTWARE
    readonly property int aboutStatValueSize: 18       // nilai di kartu spesifikasi
    readonly property int aboutStatGapX: 40            // jarak antar kolom kartu
    readonly property int aboutStatGapY: 20            // jarak antar baris kartu
    readonly property int aboutStatPad: 12             // jarak garis atas kartu ke isinya
    readonly property int aboutLayerHeight: 40         // tinggi satu lapisan software
    readonly property int aboutLayerGap: 6             // jarak antar lapisan; cukup lega supaya baris yang melebar tidak menempel ke tetangganya
    readonly property int aboutLayerGrowX: 10          // latar baris software melebar sejauh ini ke KIRI dan ke KANAN saat hover (masuk ke margin halaman, 16 px)
    readonly property int aboutLayerGrowY: 4           // dan tinggi total bertambah segini (2 px atas + 2 px bawah, di bawah jarak antar baris)
    readonly property real aboutLayerSpring: 5.5       // kekakuan pegas hover; naikkan = lebih cepat
    readonly property real aboutLayerDamp: 0.5         // 1 = tanpa pantulan; makin kecil makin memantul
    readonly property color aboutLayerHoverFill: Qt.rgba(1, 1, 1, 0.30)     // isi baris saat hover: lebih terang dari semua tingkat tile, jadi jelas beda dari baris MacMono yang memang terang
    readonly property color aboutLayerHoverStroke: Qt.rgba(1, 1, 1, 0.34)   // garis tepi baris saat hover
    readonly property int aboutStatBar: 6              // tebal bar pemakaian penyimpanan
    readonly property int settingsPadTop: 16           // jarak atas konten; harus lebih besar dari space8 supaya label grup menempel ke kartunya, bukan ke kolom cari
    readonly property int settingsGroupSpacing: 18     // jarak antar grup; ikut naik karena baris jadi lebih tinggi
    readonly property int settingsSearchHeight: 40     // tinggi kolom cari; teks di dalamnya 15 px
    readonly property int settingsSearchWidth: 240     // lebar kolom cari di header (kapsul, kanan judul halaman)
    readonly property int settingsButtonHeight: 32     // tinggi tombol di bar perubahan
    readonly property int settingsButtonPadX: 14       // padding kiri/kanan tombol
    readonly property int settingsRowPadX: 16          // padding kiri/kanan satu baris pengaturan
    readonly property int settingsRowPadY: 14          // padding atas/bawah satu baris pengaturan
    readonly property int settingsDot: 6               // titik penanda "berubah"
    readonly property int settingsToggleWidth: 40      // lebar saklar
    readonly property int settingsToggleHeight: 24     // tinggi saklar
    readonly property int settingsToggleKnob: 18       // diameter bulatan saklar
    readonly property int settingsToggleInset: 3       // jarak bulatan dari tepi saklar
    readonly property int settingsSliderWidth: 260     // lebar bawaan slider (di baris dia selalu melebar penuh)
    readonly property int settingsSliderHeight: 28     // tinggi area slider
    readonly property int settingsSliderTrack: 4       // tebal rel slider
    readonly property int settingsSliderKnob: 14       // diameter pegangan slider
    readonly property int settingsSliderLabel: 60      // lebar label nilai slider
    readonly property int settingsMeterHeight: 6       // tebal rel meter level mikrofon (halaman Sound)
    readonly property int settingsPreviewHeight: 190         // tinggi pratinjau desktop mini (Appearance)
    readonly property int settingsPreviewBarHeight: 24       // tinggi top bar mini
    readonly property int settingsPreviewPanelHeight: 84     // tinggi panel mini
    readonly property int settingsPreviewPanelMax: 260       // lebar maksimum panel mini
    readonly property int settingsPreviewSourceWidth: 960    // lebar decode gambar pratinjau besar
    readonly property int settingsHeroHeight: 220            // tinggi kartu wallpaper sekarang
    readonly property int settingsHeroScrimHeight: 84        // tinggi bayangan di dasar kartu itu
    readonly property color settingsScrim: Qt.rgba(0, 0, 0, 0.65)   // ujung gelap bayangan (memudar ke transparan)
    readonly property int settingsThumbMin: 150              // lebar minimum thumbnail di grid
    readonly property int settingsThumbSourceWidth: 380      // lebar decode thumbnail
    readonly property real settingsThumbRatio: 0.5625        // tinggi/lebar thumbnail (16:9)
    readonly property int settingsThumbMax: 12               // jumlah thumbnail di halaman Settings
    readonly property int settingsMonitorHeight: 110         // tinggi layar monitor mini (Display)
    readonly property int settingsMonitorMaxW: 200           // lebar maksimum layar monitor mini
    readonly property int settingsMonitorNeckW: 10
    readonly property int settingsMonitorNeckH: 8
    readonly property int settingsMonitorStandW: 56
    readonly property int settingsMonitorStandH: 5
    readonly property int settingsNightHeight: 120           // tinggi tiap potongan pratinjau Night Light
    readonly property int settingsWeatherHeight: 96          // tinggi kartu pratinjau cuaca (Location & Weather)
    readonly property int settingsWeatherIcon: 40            // ikon kondisi di kartu itu
    readonly property int settingsWeatherTempSize: 44        // angka suhu sekarang
    readonly property real settingsWeatherTempTracking: -1.4 // angka besar dirapatkan, sejalan dengan judul panel
    readonly property int settingsEqAxisW: 34                // kolom sumbu dB di kiri grafik Equalizer
    readonly property int settingsEqPlotHeight: 112          // tinggi grafik kurva respons
    readonly property int settingsEqBandHeight: 150          // tinggi slider vertikal satu band
    readonly property int settingsEqBandPad: 10              // jarak rel slider band dari tepi atas/bawah
    readonly property int settingsEqKnob: 16                 // diameter pegangan band
    readonly property int settingsEqTick: 14                 // lebar garis penanda 0 dB di rel band
    readonly property real settingsEqOffOpacity: 0.55        // kartu band diredupkan saat Equalizer mati (tetap bisa digeser)
    readonly property int settingsBackupShown: 5             // backup terbaru yang langsung tampil di Backup & Reset; sisanya lewat "Show all"
    readonly property int settingsPickMax: 8                 // jumlah baris maksimum di daftar pilih aplikasi (Apps & Startup)
    readonly property int settingsBatBar: 10                 // tebal bar baterai (Power)
    readonly property int settingsSegHeight: 38              // tinggi tombol segmen (power profile)
    readonly property int settingsMarkSize: 10               // diameter titik di timeline
    readonly property int settingsDemoHeight: 90             // tinggi kotak demo (touchpad, layar, halaman mini)
    readonly property int settingsDemoPadW: 130              // lebar touchpad mini
    readonly property int settingsDemoPageW: 200             // lebar halaman / layar mini
    readonly property int settingsDemoTravel: 40             // jarak halaman mini bergeser
    readonly property int settingsDemoMs: 1600               // durasi satu gerakan demo
    readonly property int settingsDemoPauseMs: 700           // jeda antar pengulangan demo
    readonly property int settingsKeycap: 40                 // ukuran keycap demo (Keyboard)
    readonly property int settingsNotifPreviewW: 300         // lebar maksimum notifikasi mini (Notifications)
    readonly property int settingsConfirmMs: 3000            // lama tombol "tap again" menunggu konfirmasi
    readonly property int settingsSavedMs: 1700              // lama status "Saved" tampil setelah Apply
    readonly property real settingsSliderKnobPressed: 1.15  // pegangan membesar saat ditekan
    readonly property int settingsSliderTickH: 10            // tinggi garis tanda nilai bawaan di rel slider
    readonly property int settingsSliderTickW: 2             // tebal garis itu
    readonly property real settingsSliderTickOpacity: 0.55   // dibuat redup supaya tidak bersaing dengan pegangan
    readonly property int settingsSliderSnapPx: 6            // jarak (px) dari garis bawaan tempat pegangan "menempel" saat digeser
    readonly property int settingsHoverPreviewMs: 140        // jeda sebelum pratinjau hover wallpaper berganti (tidak kedip saat kursor lewat)
    readonly property int settingsFlashHoldMs: 450           // sorotan baris tetap menyala setelah lompat dari hasil cari
    readonly property int settingsFlashFadeMs: 700           // lama sorotan itu memudar
    readonly property int settingsStepperWidth: 120    // lebar stepper
    readonly property int settingsStepperHeight: 30    // tinggi stepper
    readonly property int settingsStepperButton: 32    // lebar tombol +/-
    readonly property int settingsRepeatDelay: 380     // jeda sebelum tombol stepper menahan-ulang (ms)
    readonly property int settingsRepeatInterval: 70   // interval ulang saat ditahan (ms)
    readonly property int settingsChipHeight: 26       // tinggi chip daftar
    readonly property int settingsChipRemove: 18       // area klik tombol hapus chip
    readonly property int settingsChipInputWidth: 150  // lebar kolom "+ tambah"
    readonly property int settingsChipsMinWidth: 320   // lebar minimum daftar chip
    readonly property int settingsScrollbarWidth: 3    // lebar scrollbar tipis
    readonly property int settingsScrollbarInset: 7    // jarak scrollbar dari tepi kanan
    readonly property int settingsScrollbarMin: 24     // tinggi minimum pegangan scrollbar
}
