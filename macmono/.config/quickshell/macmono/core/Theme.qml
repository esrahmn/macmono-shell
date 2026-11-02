pragma Singleton

import QtQuick
import Quickshell

// ============================================================================
// Theme macmono: SATU-SATUNYA tempat definisi tampilan.
// Semua file QML lain cukup pakai Theme.<nama>, jangan bikin warna / radius /
// ukuran font sendiri. Mau ganti tampilan? Edit di sini, lalu Ctrl+Super+R.
//
// Semua warna sengaja abu-abu murni (R=G=B). Nggak ada satu pun warna beraksen.
// ============================================================================
Singleton {
    // ------------------------------------------------------------------ font
    // Inter dari paket Arch/CachyOS terdaftar sebagai "Inter Variable", bukan "Inter".
    // Ambil nama yang benar-benar terpasang supaya Qt nggak diam-diam jatuh ke Noto Sans.
    readonly property string font: {
        const fams = Qt.fontFamilies();
        for (const f of ["Inter", "Inter Variable", "Inter Var", "Inter Display"])
            if (fams.indexOf(f) >= 0) return f;
        return "Inter";
    }
    readonly property string fontMono: "monospace"

    // Skala ukuran font (px)
    readonly property int fontMicro: 9
    readonly property int fontCaption: 10
    readonly property int fontSmall: 11
    readonly property int fontBody: 12
    readonly property int fontBodyLg: 13
    readonly property int fontSubtitle: 14
    readonly property int fontTitle: 15
    readonly property int fontHeading: 16
    readonly property int fontLead: 18
    readonly property int fontDisplay: 30
    // Ukuran khusus untuk jam, angka besar, dan judul di komponen tertentu.
    readonly property int fontHeadingLg: 17
    readonly property int fontDisplaySm: 19
    readonly property int fontDisplayMd: 22
    readonly property int fontHero: 26
    readonly property int fontClock: 84

    // --------------------------------------------------------------- spacing
    // Skala jarak layout (px). Gunakan token ini untuk Row/Column/Layout.spacing.
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

    // ---------------------------------------------------------- permukaan
    readonly property color bar: Qt.rgba(0, 0, 0, 0.50)            // menubar
    readonly property color panel: Qt.rgba(0.08, 0.08, 0.08, 0.85) // kartu/panel utama
    readonly property color popup: Qt.rgba(0.07, 0.07, 0.07, 0.93) // popup kecil: tray menu, OSD
    readonly property color raised: Qt.rgba(0.16, 0.16, 0.16, 0.95) // kartu yang "terangkat" (mis. kartu window di overview)
    readonly property color canvas: "#0b0b0b"                      // dasar wallpaper
    readonly property color black: "#000000"                       // hitam murni (latar jendela screenshot)
    readonly property color transparent: "transparent"             // area tanpa isi visual

    // Lapisan hitam transparan
    readonly property color veil: Qt.rgba(0, 0, 0, 0.01)   // nyaris transparan, cuma buat area klik / area blur
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)  // peredup layar (region selector)
    readonly property color inset: Qt.rgba(0, 0, 0, 0.30)  // kotak "cekung": input, preview
    readonly property color badge: Qt.rgba(0, 0, 0, 0.75)  // label di atas gambar

    // ------------------------------------------------- tile / hover (putih)
    readonly property color tileFaint: Qt.rgba(1, 1, 1, 0.06)  // hover tipis, tile redup
    readonly property color tile: Qt.rgba(1, 1, 1, 0.08)       // tile default
    readonly property color tileMid: Qt.rgba(1, 1, 1, 0.11)    // tile terpilih / hover sedang
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.15)  // hover kuat / state aktif
    readonly property color tileStrong: Qt.rgba(1, 1, 1, 0.22) // hover pada kontrol bulat kecil
    readonly property color selection: Qt.rgba(1, 1, 1, 0.30)  // blok seleksi teks

    // ----------------------------------------------------------------- garis
    readonly property color line: Qt.rgba(1, 1, 1, 0.08)        // border halus
    readonly property color lineStrong: Qt.rgba(1, 1, 1, 0.12) // border menonjol
    readonly property color lineFocus: Qt.rgba(1, 1, 1, 0.35)  // border saat fokus

    // ------------------------------------------------------------------ teks
    readonly property color text: "#ffffff"
    readonly property color textSoft: Qt.rgba(1, 1, 1, 0.80)   // teks sekunder yang masih jelas
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color muted: Qt.rgba(1, 1, 1, 0.30)
    readonly property color ghost: Qt.rgba(1, 1, 1, 0.10)     // teks watermark (angka workspace di overview)
    readonly property color faint: Qt.rgba(1, 1, 1, 0.20)

    // --------------------------------------- state terpilih/aktif (putih solid)
    readonly property color inverse: "#ffffff"
    readonly property color inverseText: "#000000"
    readonly property color inverseHover: Qt.rgba(1, 1, 1, 0.85)  // hover pada tombol putih
    readonly property color inverseDim: Qt.rgba(0, 0, 0, 0.55)    // teks redup di atas putih
    readonly property color inverseTile: Qt.rgba(0, 0, 0, 0.08)   // tile di atas putih

    // --------------------------------------------------------------- animasi
    // Durasi (ms). Pilih berdasarkan PERAN animasinya, jangan angka mentah.
    readonly property int animPress: 90    // feedback sentuh: scale tombol, bar OSD
    readonly property int animHover: 130   // hover & perubahan warna kecil
    readonly property int animFade: 160    // fade opacity
    readonly property int animBase: 200    // buka/tutup panel, expand/collapse, slide, rotasi
    readonly property int animSlow: 300    // transisi lambat (fade wallpaper)
    readonly property int animPulse: 600   // denyut berulang (titik rekam)
    readonly property real buttonPressedScale: 0.97   // tombol mengecil sedikit saat ditekan

    // ------------------------------------------------------------- opasitas
    readonly property real opacityDisabled: 0.4   // kontrol nonaktif
    readonly property real opacityDim: 0.72       // item yang diredupkan sampai di-hover / dipilih
    readonly property real openFromPanel: 0.4     // opasitas awal animasi buka panel kecil (harus > ignore_alpha 0.2)
    readonly property real openFromModal: 0.65    // opasitas awal animasi buka panel modal (harus > ignore_alpha 0.5)

    // Kurva easing
    readonly property int easeOut: Easing.OutCubic   // masuk / buka
    readonly property int easeIn: Easing.InCubic     // keluar / tutup

    // ---------------------------------------------------------------- ukuran
    readonly property int barHeight: 34
    readonly property int barMargin: 5

    // Skala radius (px) untuk kartu, panel, dan tombol bersegi.
    // Elemen BULAT atau PIL (lingkaran, kapsul, bar tipis) jangan pakai token ini:
    // tulis `radius: Math.min(width, height) / 2` supaya tetap bulat walau ukurannya berubah.
    readonly property int radiusXs: 8
    readonly property int radiusSmall: 10
    readonly property int radiusMedium: 12
    readonly property int radiusCard: 14
    readonly property int radius: 16
    readonly property int radiusLarge: 20
    readonly property int radiusPanel: 22
    readonly property int radiusXl: 28
    // Detail kecil
    readonly property int radiusKey: 6         // keycap / badge tombol keyboard
    readonly property int radiusIndicator: 2   // kotak indikator kecil (ikon stop, bingkai seleksi)

    // Ketebalan garis/border yang dipakai lintas komponen.
    readonly property int borderThin: 1
    readonly property int borderStrong: 2
    readonly property int borderNone: 0
}
