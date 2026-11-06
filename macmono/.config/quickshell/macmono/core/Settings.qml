pragma Singleton

import QtQuick
import Quickshell

// ============================================================================
//  SETTINGS macmono: semua yang bisa lu atur tanpa menyentuh kode panel.
//
//  Cara pakai: ubah nilainya, simpan, lalu reload shell (Ctrl+Super+R).
//  Semua nilai di sini adalah perilaku (jumlah, waktu, daftar, ambang).
//  Untuk TAMPILAN (warna, ukuran, animasi) lihat core/Theme.qml.
//
//  Satuan: Ms = milidetik, Sec = detik, Kelvin = suhu warna. Nilai di bawah adalah
//  nilai bawaan; mengubahnya nggak merusak apa-apa, tapi angka ekstrem bisa bikin
//  panel terasa aneh (mis. timeout 0).
// ============================================================================
Singleton {
    // ======================================================================
    //  Tampilan
    // ======================================================================
    // Keburaman latar top bar + semua panel + popup (0 = bening, 1 = pekat). Satu angka buat semuanya.
    // 0.60 = bawaan. Naikkan (mis. 0.75) kalau teks susah dibaca di atas wallpaper terang.
    // Dibatasi 0.25..1 di Theme.qml: di bawah itu blur Hyprland (ignore_alpha 0.2) bisa hilang.
    readonly property real panelOpacity: 0.60

    // ======================================================================
    //  Top bar
    // ======================================================================
    // Jumlah titik workspace minimum yang selalu tampil di top bar.
    readonly property int menubarWorkspaceMin: 5

    // Jumlah titik workspace maksimum (workspace di atas angka ini tidak ditampilkan).
    readonly property int menubarWorkspaceMax: 10

    // ======================================================================
    //  Launcher (Super)
    // ======================================================================
    // Maks. app di daftar hasil (Windows, Actions, dan Top Hit nggak dibatasi).
    readonly property int launcherMaxResults: 9

    // App di baris "Pinned": nama file .desktop tanpa ".desktop" (atau nama app, ditebak otomatis).
    readonly property var pinnedApps: ["kitty", "google-chrome", "spotify", "org.kde.dolphin", "discord", "steam", "com.microsoft.VSCode", "com.obsproject.Studio"]

    // Super dianggap "tap" (buka launcher) kalau dilepas dalam waktu segini (ms).
    // Ditahan lebih lama = diabaikan.
    readonly property int superTapMaxMs: 450

    // ======================================================================
    //  Overview workspace di launcher
    // ======================================================================
    // Jumlah baris workspace.
    readonly property int overviewRows: 2

    // Jumlah kolom workspace. 2 x 5 = workspace 1-10.
    readonly property int overviewColumns: 5

    // Ukuran workspace relatif ke layar (launcher desain A: overview ringkas).
    readonly property real overviewScale: 0.14

    // false = cuma ikon app, tanpa preview jendela live (lebih ringan).
    readonly property bool overviewLivePreview: true

    // ======================================================================
    //  Clipboard (Super+V)
    // ======================================================================
    // Maks. entri riwayat yang ditampilkan.
    readonly property int clipboardMaxItems: 200

    // ======================================================================
    //  Notifikasi
    // ======================================================================
    // Lama notifikasi tampil (ms) kalau aplikasinya nggak menentukan sendiri.
    // Notifikasi urgent tetap nggak hilang sendiri.
    readonly property int notifDefaultTimeoutMs: 5000

    // Maks. riwayat notifikasi yang disimpan (kalender / notification center).
    readonly property int notifHistoryMax: 50

    // ======================================================================
    //  OSD volume & kecerahan
    // ======================================================================
    // Berapa lama OSD tampil sebelum hilang sendiri (ms).
    readonly property int osdHideMs: 1400

    // ======================================================================
    //  Baterai
    // ======================================================================
    // Level (%) yang memicu peringatan baterai lemah.
    // WAJIB urut dari kecil ke besar.
    readonly property var batteryWarnLevels: [5, 10, 20]

    // Level (%) ke bawah ini dikirim sebagai notifikasi 'critical' (urgent), di atasnya 'normal'.
    readonly property int batteryCriticalLevel: 10

    // ======================================================================
    //  Night Light (hyprsunset)
    // ======================================================================
    // Suhu warna saat Night Light aktif (K).
    // Makin kecil = makin kuning.
    readonly property int nightLightKelvin: 4200

    // Suhu warna normal saat Night Light mati (K).
    readonly property int nightLightOffKelvin: 6500

    // ======================================================================
    //  Kecerahan
    // ======================================================================
    // Langkah tombol kecerahan keyboard (0.05 = 5%).
    readonly property real brightnessStep: 0.05

    // Jeda (ms) sebelum nilai kecerahan dikirim ke brightnessctl saat slider digeser.
    readonly property int brightnessDebounceMs: 80

    // Sama, tapi untuk monitor eksternal (ddcutil lebih lambat).
    readonly property int brightnessDdcDebounceMs: 250

    // ======================================================================
    //  Wi-Fi
    // ======================================================================
    // Cek ulang status & kekuatan sinyal Wi-Fi tiap sekian ms (cadangan; perubahan koneksi sudah ditangkap lewat nmcli monitor).
    readonly property int wifiStatusPollMs: 30000

    // Batas waktu menyambung ke Wi-Fi (ms) sebelum dibatalkan.
    readonly property int wifiConnectTimeoutMs: 45000

    // Maks. jaringan yang ditampilkan di daftar.
    readonly property int wifiMaxNetworks: 16

    // ======================================================================
    //  Bluetooth
    // ======================================================================
    // Batas waktu pairing (detik) sebelum dibatalkan, supaya baris "Pairing…" nggak macet.
    readonly property int btPairTimeoutSec: 30

    // ======================================================================
    //  Indikator privasi
    // ======================================================================
    // Cek kamera & perekam layar eksternal — hanya selama ada window yang bisa membuka
    // kamera, atau selama indikatornya masih menyala. Saat idle tidak ada cek sama sekali
    // (tidak ada proses yang di-spawn). Turunkan angka ini kalau indikator terasa telat muncul.
    // Mic & screencast sudah reaktif lewat Pipewire (tanpa polling).
    readonly property int privacyPollActiveMs: 2000

    // ======================================================================
    //  Wallpaper
    // ======================================================================
    // Folder yang dipindai untuk daftar wallpaper ("~" = home).
    // Urutan = prioritas, duplikat dibuang.
    readonly property var wallpaperDirs: ["~/Pictures/Wallpapers", "~/Pictures", "~/Wallpapers", "~/.local/share/backgrounds", "/usr/share/backgrounds", "/usr/share/wallpapers"]

    // Seberapa dalam subfolder dipindai.
    readonly property int wallpaperScanDepth: 2

    // Maks. jumlah gambar yang dimuat.
    readonly property int wallpaperMaxFiles: 500

    // ======================================================================
    //  Screenshot & rekam layar
    // ======================================================================
    // Jeda (ms) setelah panel ditutup sebelum screenshot / rekaman dimulai, supaya panel nggak ikut terekam.
    // Harus >= lama animasi tutup panel (Theme.revealCloseStiff).
    readonly property int panelCloseDelayMs: 380

    // Batas tunggu (ms) kabar "rekaman mulai" dari record.sh (mode layar penuh).
    readonly property int recordStartTimeoutMs: 15000

    // Sama, tapi mode pilih area (ada waktu untuk memilih area).
    readonly property int recordStartTimeoutAreaMs: 120000

    // Batas tunggu (ms) wf-recorder berhenti setelah tombol Stop.
    readonly property int recordStopGraceMs: 8000

    // ======================================================================
    //  Lirik (popup media)
    // ======================================================================
    // Batas waktu mengambil lirik dari internet (ms).
    readonly property int lyricsRequestTimeoutMs: 11000

    // Jeda sebelum mencoba ulang otomatis (ms), supaya API nggak rate-limit.
    readonly property int lyricsRetryDelayMs: 3000

    // Seberapa sering baris lirik aktif diperbarui (ms).
    // Makin kecil = makin presisi, makin boros.
    readonly property int lyricsSyncIntervalMs: 40

    // Offset lirik (detik). Positif = baris lirik muncul LEBIH AWAL, negatif = lebih lambat.
    // Naikkan (mis. 0.3) kalau lirik terasa telat terus; turunkan atau minus kalau kecepetan.
    readonly property real lyricsLeadSeconds: 0.15

    // Seberapa sering MediaClock baca ulang posisi lagu asli lewat busctl (ms), dipakai progress bar
    // dan lirik. Makin kecil = lirik/progress makin cepat benar setelah seek dari luar (mis. dari
    // Spotify), tapi proses busctl makin sering dipanggil selama popup media atau lirik terbuka.
    // 6000 = hemat, 2000 = lebih responsif.
    readonly property int mediaPollIntervalMs: 3000

    // ======================================================================
    //  Lock screen
    // ======================================================================
    // Batas waktu verifikasi password (ms).
    // Lewat dari ini input dibuka lagi.
    readonly property int lockPamTimeoutMs: 10000

    // Password yang diketik lalu ditinggal dihapus otomatis setelah sekian ms.
    readonly property int lockClearPasswordMs: 30000

    // Jeda (ms) cek ulang Caps Lock setelah tombol ditekan.
    readonly property int lockCapsRecheckMs: 60

    // ======================================================================
    //  Power menu
    // ======================================================================
    // Tombol Log Out / Restart / Shut Down butuh klik kedua; kembali ke awal kalau nggak diklik dalam sekian ms.
    readonly property int powerConfirmMs: 3000

    // ======================================================================
    //  Lanjutan (jarang perlu diubah)
    // ======================================================================
    // Setelah tray menu menutup, klik ikon dalam sekian ms diabaikan (supaya nggak langsung terbuka lagi).
    readonly property int trayReopenGuardMs: 200

    // Sama, untuk Control Center & kalender.
    readonly property int panelReopenGuardMs: 300

    // Jeda (ms) antara menutup launcher dan mengirim perintah workspace/window ke Hyprland, supaya fokus sempat settle.
    readonly property int focusSettleDelayMs: 120

    // OSD diabaikan sekian ms pertama setelah shell start (nilai awal volume / kecerahan bukan perubahan).
    readonly property int osdStartupGraceMs: 2500

    // Peringatan baterai baru aktif sekian ms setelah shell start.
    readonly property int batteryStartupDelayMs: 4000

    // Riwayat notifikasi disimpan ke disk sekian ms setelah perubahan terakhir.
    readonly property int notifSaveDelayMs: 1000

    // Jeda (ms) memuat detail entri clipboard saat pilihan berpindah cepat.
    readonly property int clipboardDetailDebounceMs: 70

    // Jeda (ms) memuat preview wallpaper saat pilihan berpindah cepat.
    readonly property int wallpaperPreviewDebounceMs: 90

    // Batas tunggu (ms) semua layar melapor wallpaper siap.
    readonly property int wallpaperReadyTimeoutMs: 8000

    // Jeda (ms) coba ulang preview jendela di overview kalau masih kosong (maks. 6x per buka).
    readonly property int overviewPreviewRetryMs: 700

    // =====================================================================
    // Ukuran komponen (lebar/tinggi/ukuran ikon yang tadinya angka mentah di file QML).
    // Nilainya sama persis dengan sebelumnya. Ubah angkanya lalu Ctrl+Super+R.
    // sourceSize gambar otomatis ikut 2x ukuran tampilnya.
    // =====================================================================

    // ---- Launcher ----
    readonly property int launcherSectionHeaderHeight: 28       // Tinggi judul grup hasil (mis. Applications, Actions) di daftar hasil

    // ---- LockMedia ----
    readonly property int lockMediaCoverSize: 84                // Cover album di widget media lockscreen
    readonly property int lockMediaProgressHeight: 3            // Tebal garis progress lagu di widget media lockscreen

    // ---- LockSurface ----
    readonly property int lockBoltIconSize: 14                  // Ikon petir (baterai mengisi) di lockscreen
    readonly property int lockAvatarSize: 88                    // Kotak avatar/login di atas form password lockscreen
    readonly property int lockPasswordFieldHeight: 44           // Tinggi kotak input password di lockscreen

    // ---- LyricsView ----
    readonly property int lyricsViewLineHeight: 20              // Tinggi Item pembungkus teks (satu baris kecil) di LyricsView

    // ---- MenuBar ----
    readonly property int menuBarUnreadDotSize: 6               // Titik penanda notifikasi belum dibaca, di samping jam
    readonly property int menuBarRecordDotSize: 8               // Titik di pill rekam layar
    readonly property int menuBarRecordingDotSize: 9            // Titik indikator saat sedang merekam

    // ---- Notifs ----
    readonly property int notifCloseIconSize: 12                // Ukuran tanda silang (X) di tombol tutup kartu notifikasi

    // ---- Wallpaper ----
    readonly property int wallpaperPillTextMaxWidth: 380        // Lebar maksimum teks nama wallpaper di pill atas picker (lebih panjang dipotong "...")

    // ---- WifiList ----
    readonly property int wifiPasswordRowHeight: 46             // Tinggi baris input password di bawah jaringan (0 kalau tertutup)
}
