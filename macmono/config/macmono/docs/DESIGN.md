# macmono — Arah Desain (pengganti DESIGN-CONTRACT.md)

Dokumen ini **menggantikan seluruh `DESIGN-CONTRACT.md`** (R1–R9 tidak berlaku lagi, termasuk "monokrom tanpa aksen",
"tanpa hint", dan "Reveal dikunci"). Arah baru, ditetapkan 10 Nov 2026 oleh pemilik shell:

> **Monokrom + satu aksen, satu fisika gerak, satu skala untuk semuanya.**

**STATUS: SELESAI (P0–P5).** Semua fase sudah dikerjakan dan diuji pemilik shell di mesinnya, lolos (10 Nov 2026).
Dokumen ini sekarang jadi **acuan final** untuk kode baru. Kalau angka di dokumen ini beda dengan `core/theme/Theme.qml`,
yang benar adalah `Theme.qml`. Rencana lama dan catatan pelaksanaan masih ada di bagian 7 sebagai riwayat. Cek cepat untuk kode baru ada di bagian 9.

Cara baca dokumen ini: setiap aturan punya **alasan** dan **cara cek** (biasanya satu `grep`). Aturan yang tidak
bisa dicek atau dijelaskan alasannya tidak boleh masuk sini. Itu pelajaran dari kontrak lama, yang banyak berisi
larangan tanpa alasan dan akhirnya saling bertabrakan (lihat catatan di `settings-design.md`).

Catatan: agent tidak bisa menjalankan `qs`, jadi ✅ dari agent berarti *kode patuh* (grep dan qmllint statis). Pemilik shell
sudah menjalankan dan menguji semuanya di mesinnya dan menyatakan lolos (10 Nov 2026). Penilaian visual berikutnya tetap di mata pemilik.

---

## 1. Identitas

macmono dikenali dari tiga hal. Tiga-tiganya harus muncul di **setiap** permukaan, kalau tidak, itu bug desain.

1. **Kaca hitam + tipografi editorial.** Latar hitam transparan (blur diatur Hyprland, bukan Quickshell). Judul besar
   dan rapat, label KAPITAL renggang, teks isi tenang. Bentuk dan warna sengaja diam supaya huruf yang bicara.
2. **Satu aksen untuk "sesuatu sedang hidup".** Semua yang aktif, fokus, terpilih, atau sedang berjalan memakai
   satu warna aksen yang sama. Selain itu semuanya abu-abu netral. Aksen bukan dekorasi.
3. **Satu fisika gerak: laci pegas.** Apa pun yang muncul atau hilang bergerak lewat `Reveal` (pegas, tanpa
   durasi tetap). Gerak kecil (hover, tekan, warna) memakai satu easing yang sama.

Pembeda dari Material: Material identik dengan dynamic color dan state layer. macmono identik dengan
*hampir tanpa warna, lalu satu warna yang selalu berarti "aktif"*.

**Di luar dokumen ini (dikunci pemilik):** animasi window Hyprland (`windows`, `windowsIn`, `windowsOut`,
`windowsMove`, `workspaces`, kurva `wind`/`winIn`/`winOut`). Jangan diubah, jangan dijadikan acuan untuk shell.

---

## 2. Arsitektur token: tiga lapis

Masalah awal: `Theme.qml` berisi **408 properti**, sekitar 281 di antaranya ukuran komponen, 35 tidak dipakai, dan hanya sekitar 70
yang benar-benar token desain. Hasil akhir (P3–P4): `Theme.qml` **81 properti**, plus `SettingsMetrics.qml` 28 properti
(ukuran yang dipakai bersama banyak file Settings), dan sisanya hidup di file komponen masing-masing.

| Lapis | Isi | Tempat |
|---|---|---|
| 1. Skala | angka mentah yang boleh ada (ukuran font, spasi, radius, durasi) | `Theme.qml` |
| 2. Peran | arti dari skala (warna `text`, `dim`, `accent`; `radiusCard`) | `Theme.qml` |
| 3. Komponen | ukuran khusus satu komponen (tinggi baris, lebar kolom, bezel laptop) | **di file komponen itu sendiri**, sebagai `readonly property` di root-nya |

Aturan:
- **A1.** Angka yang hanya dipakai satu komponen tinggal di komponen itu, bukan di Theme.
- **A2.** Komponen boleh memakai lapis 3 miliknya dan lapis 1–2 dari Theme. Dilarang punya angka mentah baru
  untuk warna, font, spasi, radius, atau durasi.
- **A3.** `Theme.qml` hanya berisi skala dan peran, tanpa token tak terpakai (akhir: 81 properti; sisanya di atas 70 adalah token gerak `reveal*`/`wall*` dan `list*`/`cheatsheetKeycap*` yang dipakai lintas fitur).
- **A4.** Ukuran yang dipakai beberapa file dalam satu fitur Settings boleh ditaruh di `SettingsMetrics` (singleton, terdaftar di `core/qmldir`). Fitur lain: satu file satu konstanta, tidak ada singleton baru.

Cek: `grep -rnE "(pixelSize|radius|duration|spacing|margins?) *: *[0-9]" features shared` hanya boleh mengembalikan
angka `0`, `1` (hairline), atau konstanta lapis 3 milik file itu.

---

## 3. Warna

### 3.1 Permukaan dan garis
| Token | Nilai | Dipakai untuk |
|---|---|---|
| `panel` | hitam, opasitas dari `Settings.panelOpacity` | latar semua panel mengambang |
| `tile` | putih 8% | kartu dan tombol diam |
| `tileHover` | putih 15% | hover, baris terpilih |
| `tilePress` | putih 22% (dulu `tileStrong`) | ditekan |
| `line` | putih 8% | hairline pemisah, border panel |
| `lineFocus` | aksen 45% | cincin fokus keyboard |
| `scrim` | hitam 45% | peredup modal (Power Menu pakai ini juga) |

Dibuang atau digabung: `tileFaint`→`tile`, `tileMid`→`tile`, `tileStrong`→`tilePress`, `lineStrong`→`line`,
`cardStroke`→`line`, `selection`→`tileHover`, `well`/`inset`/`badge`/`raised`/`canvas`/`black`/`veil`→`scrim`, `popup`/`bar`→`panel`. Semua sudah dikerjakan; yang tadinya solid
(`canvas`, `black`, `raised`) kini transparan 45% dan sudah diuji pemilik.

### 3.2 Teks: tiga tingkat, bukan enam
| Token | Opasitas | Untuk |
|---|---|---|
| `text` | 100% | isi dan judul |
| `dim` | 60% | keterangan, label sekunder |
| `faint` | 40% | placeholder dan nonaktif saja |

Pemetaan: `textSoft`(22 pemakaian)→`text`, `muted`(11)→`faint`, `faint` lama (14)→`faint`, `ghost`→`line`.
`dim` naik dari 55% ke 60% karena teks redup di latar transparan memang sering sulit dibaca.

### 3.3 Aksen
- Token: `accent` (isi), `accentHover` (aksen 85%) dan `textOnAccent` (teks di atas isi aksen, hitam).
  (`textOnAccentDim` dihapus 10 Nov 2026: satu-satunya pemakainya, tile Power di Control Center, pindah ke gaya gelap, lihat bagian 11.) Catatan nama: **bukan `onAccent`**, karena properti QML berawalan `on` + huruf besar
  adalah sintaks signal handler dan gagal dimuat begitu `accent` juga ada.
- **Diputuskan 10 Nov 2026: aksen putih keabuan `#E8E8E6`** (putih yang tidak terlalu putih, supaya tidak mencolok). Isi terang + teks hitam,
  jadi logika state "menyala" yang dulu pakai putih murni tetap sama; bedanya sekarang satu pintu. Mau ganti warna nanti cukup satu baris di Theme.
- Opsi masa depan (tidak dikerjakan sekarang): `Settings.accentSource` = tetap | ikut wallpaper. **Tidak dikerjakan sekarang**; token sudah
  dibuat satu pintu supaya nanti tinggal diisi.

**Kapan aksen boleh muncul** (hanya ini):
1. State aktif: toggle menyala, tile Wi-Fi/Bluetooth aktif, tombol DND, hari terpilih di kalender.
2. Fokus keyboard dan baris terpilih (cincin `lineFocus`, atau indikator tipis).
3. Progres dan nilai: isi slider, progress media, bar baterai saat mengisi.
4. Penanda "sedang berjalan": indikator rekam, workspace aktif.

Selain itu **dilarang**: aksen untuk dekorasi, ikon biasa, judul, atau border panel.

Migrasi: `Theme.inverse` (20 pemakaian) → `accent`, `inverseText` (21) → `textOnAccent`, `inverseHover` → `accentHover`,
`inverseDim` → `textOnAccentDim`. Pengecualian putih yang disengaja (misal tombol utama Lock) diputuskan per kasus saat menyentuh file itu.

### 3.4 State komponen (satu tabel untuk semua)
| State | Tampilan |
|---|---|
| normal | `tile` atau tanpa latar |
| hover | `tileHover` (transisi `durFast`) |
| ditekan | `tilePress` + skala `Theme.pressScale` 0.97 |
| aktif / menyala | isi `accent`, teks `textOnAccent` |
| fokus keyboard | cincin 1 px `lineFocus` |
| nonaktif | opasitas 0.4 |

Keputusan lama yang tetap dipegang karena diminta langsung oleh pemilik: **bar tanpa efek hover**, dan **blur hanya
dari Hyprland**.

---

## 4. Tipografi

Satu keluarga (`Inter`, lewat `Theme.font`). Monospace hanya untuk kode, path, dan keycap.

### 4.1 Skala ukuran: enam langkah
| Token | px | Menggantikan |
|---|---|---|
| `fontXs` | 11 | `fontMicro`(10), `fontCaption`, `fontSmall`, label KAPITAL |
| `fontSm` | 12 | `fontBody` (94 pemakaian, teks isi utama) |
| `fontMd` | 14 | `fontBodyLg`(13), `fontSubtitle`(14) |
| `fontLg` | 16 | `fontTitle`(15), `fontHeading`(16), `fontHeadingLg`(17), `fontLead`(18) |
| `fontXl` | 22 | `fontDisplaySm`(19), `fontDisplayMd`(22) |
| `font2xl` | 28 | `panelTitleSize`(28), `fontHero`(26), `fontDisplay`(30) |

`fontClock` (84) dan `fontEmoji` (24) pindah ke komponen masing-masing (Lock, Emoji) karena hanya dipakai di sana.
Catatan: 13→14 dan 18→16 mengubah teks 1–2 px. Itu sengaja, dan perlu dicek mata.

### 4.2 Weight dan tracking
- Weight: `Regular`, `Medium`, `DemiBold`. Tiga saja. Hitungan kode saat ini: `DemiBold` 75, `Medium` 21, `Bold` 1, sisanya
  sekitar 13 berupa ekspresi kondisi (aktif/terpilih), dan Regular adalah default yang tidak ditulis. Jadi tiga weight ini
  memang sudah hampir cocok: yang perlu dibereskan hanya satu `Font.Bold` (jadi `DemiBold`) dan memastikan ekspresi kondisi
  hanya memilih di antara tiga itu (periksa satu-satu saat P4, jangan diganti buta). Token: `weightRegular`, `weightMedium`, `weightSemibold`.
- Tracking: `trackTight` (-0.9, untuk `font2xl`), `trackSnug` (-0.2, untuk `fontLg`/`fontXl`), `trackCaps` (+2.2, label KAPITAL
  di `fontXs` DemiBold, teks `dim`).
- Kontras ukuran adalah ciri editorial: judul panel `font2xl`+`trackTight`, label grup `fontXs`+`trackCaps`, isi `fontSm`.
  Jangan menaruh dua tingkat yang selisihnya kurang dari satu langkah di samping satu sama lain.

Cek: tidak ada `Theme.font(Micro|Caption|Small|Body|BodyLg|Subtitle|Title|Heading|HeadingLg|Lead|Display|Hero)` tersisa.

---

## 5. Spasi, bentuk, ikon

### 5.1 Spasi: grid 4
`space2` (hairline), `space4`, `space8`, `space12`, `space16`, `space24`, `space32` (plus `0`).

| Lama | Baru |
|---|---|
| 1, 2, 3 | `space2` |
| 4 | `space4` |
| 6, 7, 8 | `space8` |
| 10, 12 | `space12` |
| 14, 16, 18 | `space16` |
| 22 | `space24` |
| 30 | `space32` |

Yang paling banyak bergeser: `space6` (66 pemakaian) dan `space10` (59). Tata letak bisa berubah 1–2 px, dan itu sudah diuji pemilik.

### 5.2 Bentuk: tiga sudut + pill
| Token | px | Untuk |
|---|---|---|
| `radiusPanel` | 22 | panel mengambang |
| `radiusCard` | 12 | kartu, tile, thumbnail dalam panel |
| `radiusControl` | 8 | baris, tombol kecil, chip, keycap |
| pill | `height / 2` | toggle, slider, avatar, indikator, titik status |

Pemetaan: `radiusXl`/`radiusPanel`→Panel; `radiusMedium`/`radiusCard`/`radius`(16, 11 pemakaian, dicek satu-satu)→Card;
`radiusSmall`/`radiusXs`/`radiusKey`→Control; `radiusIndicator`→pill; `radiusLarge` dibuang (0 pemakaian).
Aturan konsentris: sudut dalam = sudut luar − padding. 22 = 12 + 10 sudah pas, pertahankan.

Rounding jendela Hyprland (11) tidak disentuh dokumen ini.

### 5.3 Ikon: empat langkah
`iconSm` 14 (11, 13, 14), `iconMd` 16 (15, 16, 17), `iconLg` 20 (18, 20), `iconXl` 24 (22). Ukuran 30 pindah ke komponen pemakainya.

---

## 6. Gerak

Kata kunci: **tiga kelas, masing-masing satu mekanisme.**

| Kelas | Mekanisme | Contoh |
|---|---|---|
| A. Muncul/hilang | `Reveal` (pegas) | panel, tray menu, notifikasi, OSD, picker wallpaper |
| B. Mikro | `Tween` / `TweenColor` (durasi + `easeOut`) | hover, tekan, warna, fade kecil, perpindahan baris |
| C. Berulang/umpan balik | durasi khusus, tetap di komponen | denyut indikator rekam, goyang salah password |

### 6.1 Kelas A: `Reveal`
- `Reveal.qml` adalah satu-satunya sumber gerak masuk/keluar. Nilainya (`revealOpenStiff`, `revealCloseStiff`, `revealDamp`)
  hidup di satu tempat dan **boleh diubah** kalau gerak mau disetel, selama semua pemakai ikut.
- Panel gaya laci: `translate y = -(tinggi + drawerGap) × (1 − progress)`. Itu rumus yang sudah dipakai ControlCenter, dan itu
  standar untuk panel yang menempel di bar.
- Permukaan kecil (notifikasi, OSD) memakai `Reveal` yang sama; yang berbeda hanya **jarak tempuh** (`notifSlideFrom`,
  `osdSlideFrom`) dan boleh ikut menggeser opasitas dengan progres yang sama. Karena jendela layer-nya pas dengan isi, keduanya memakai
  `progress` (di-clamp), bukan `travel`, supaya pantulan tidak terpotong tepi jendela. Tidak ada `NumberAnimation` terpisah
  untuk masuk dan keluar.
- **Pantulan dibatasi dalam px.** Geser panel lewat `Theme.drawerOffset(jarak, travel)`, bukan rumus manual `-(jarak) * (1 - travel)`. Saat `travel > 1`
  pantulan dipotong di `revealOvershootMax` (8 px), supaya panel tinggi dan pendek memantul sama besar.
- Dilarang `SpringAnimation` atau `NumberAnimation` baru untuk buka/tutup. Perubahan feel dilakukan di token `reveal*`.
- **Rasa lebih hidup (diputuskan 10 Nov 2026): pantulan halus saat buka, bersih saat tutup.** `revealOpenDamp` = 0.78
  (pantulan sekitar 2%), `revealCloseDamp` = 1.0. Rumus: overshoot = exp(-πζ/√(1-ζ²)); ζ 0.8 ≈ 1.5%, 0.7 ≈ 4.6%, 0.6 ≈ 9.5%.
  Nilai akhir disetel pakai mata.
- **Syarat teknis: pantulan tidak akan terlihat sebelum `progress` dibuka.** Sekarang `Reveal.progress` di-clamp 0..1, dan 7 panel
  (ControlCenter, Calendar, MediaPopup, Cheatsheet, LauncherMenu, SettingsApp, TrayMenu) membungkusnya lagi dengan
  `Math.min(1, anim)`. Hasilnya menurunkan damping saja cuma mengubah kurva mendekat, bukan memantul. Yang harus dilakukan:
  `Reveal` mengekspos `travel` (= `value` tanpa clamp), panel memakai `travel` untuk translate dan **menghapus** `Math.min(1, ...)`;
  `progress` (clamp) tetap dipakai untuk opasitas.

### 6.2 Kelas B: `Tween`
Temuan dari kode saat ini: **minimal 59 dari 112 animasi satu-baris tidak menyebut `easing`**, padahal default
animasi properti di Qt adalah `Linear`. Linear di samping `OutCubic` di elemen sebelahnya adalah sumber paling mungkin dari
rasa "animasi beda-beda". Solusinya struktural, bukan menambal satu per satu:

```qml
// shared/components/Tween.qml
import QtQuick
import "../../core"
NumberAnimation { duration: Theme.durBase; easing.type: Theme.easeOut }

// shared/components/TweenColor.qml
import QtQuick
import "../../core"
ColorAnimation { duration: Theme.durBase; easing.type: Theme.easeOut }
```
Pemakaian: `Behavior on opacity { Tween {} }`, `Behavior on scale { Tween { duration: Theme.durFast } }`.
Aturan: **`NumberAnimation`/`ColorAnimation` mentah dilarang di `features/` dan `shared/`**; selalu `Tween`/`TweenColor`.
Satu pengecualian, kelas C: denyut, goyang, loop demo di Settings, dan crossfade wallpaper boleh memakai `NumberAnimation` mentah,
**asal `easing.type` ditulis eksplisit** (mereka memang butuh kurva khusus, misalnya linear atau InOut).

| Token | ms | Menggantikan |
|---|---|---|
| `durFast` | 110 | `animPress`(90), `animHover`(130) |
| `durBase` | 180 | `animBase`(200), `animFade`(160) |
| `durSlow` | 300 | `animSlow`(300), `animScroll`(360), `animOpen`(280) |
| `durPulse` | 600 | `animPulse` (kelas C) |

Easing: satu, `easeOut` (OutCubic). `easeIn` hanya untuk fade keluar yang bukan `Reveal`. `InOutQuad`/`easeInOut` hanya tersisa di kelas C
(crossfade wallpaper dan demo Settings). Token mati yang dibuang: `springStiff`, `springDamp`, `openOvershoot`, `openScaleFrom*`,
`openFrom*`, `easeOpen`, `openDrop`.

### 6.3 Rencana migrasi per file
| File | Sekarang | Jadi |
|---|---|---|
| `Notifs.qml` | slide `y` + opasitas, masuk 280 ms OutCubic, keluar 200 ms InCubic | `Reveal` |
| `Osd.qml` | dua `NumberAnimation` dengan durasi berbeda masuk/keluar | `Reveal` |
| `Wallpaper.qml` (picker) | `NumberAnimation` pada `anim` (buka) dan `uiOut` (keluar saat Keep) | buka lewat `Reveal`; fade keluar saat Keep jadi `Tween`; tutup lewat Esc tetap instan seperti sebelumnya. Crossfade wallpaper latar tetap kelas C |
| `PowerMenu.qml`, `LockSurface.qml` | fade opasitas | `Reveal` (diputuskan 10 Nov 2026). Goyang salah password di Lock tetap kelas C |
| `SettingsAbout.qml` | satu-satunya `SpringAnimation` tersisa | samakan ke parameter `Reveal` atau `Tween`, lihat dulu efeknya |
| `Overview.qml` | `x`/`y` kartu window 200 ms, `scale` tanpa easing | `Tween` |
| `CcQuickToggles`, `CcNetworkTiles`, `PowerMenu` (hover), `MenuBar`, `Settings*` | `Behavior` campur: ada easing, ada yang tidak | `Tween`/`TweenColor` |
| Goyang salah password (Lock), denyut indikator rekam (MenuBar) | durasi khusus | tetap (kelas C) |

### 6.4 Adegan layar penuh dan pergantian wallpaper (ditambahkan 10 Nov 2026)

Tetap satu fisika: semuanya digerakkan satu `Reveal`; bedanya cuma **stagger**.
- `Reveal.span(from, to)` (di-clamp, untuk opasitas) dan `Reveal.spanTravel(from, to)` (ikut memantul, untuk posisi dan skala) memotong
  satu pegas menjadi jendela per elemen. Saat tutup, urutan terbalik dengan sendirinya (elemen yang muncul terakhir hilang duluan).
  Dilarang membuat animasi per elemen dengan durasi sendiri.
- Adegan layar penuh (Power, Lock) memakai `revealSceneOpenStiff`/`revealSceneCloseStiff` (lebih pelan dari panel) supaya stagger terbaca.
- **Power Menu:** scrim fade; jam naik dan membesar 0.94→1; lima tombol muncul berurutan (naik, skala 0.8→1).
- **Lock:** frame pertama = wallpaper desktop yang sama (tajam, terang). Blur dan redup naik mengikuti `progress`; jam, tanggal, kartu media, dan
  kartu login naik berurutan. Saat password benar, `LockScreen` tidak langsung membuka sesi: `unlocking = true` memutar adegan terbalik
  (kartu turun, blur memudar kembali ke wallpaper desktop), lalu `finishUnlock()` membuka sesi. Pengaman 1.5 s kalau adegan macet.
- **Pergantian wallpaper:** `WallMotion` (satu rumus, dipakai `WallLayer` dan preview picker). Layer masuk: zoom 1.08→1, geser 4% lebar dari sisi
  arah navigasi (maju/mundur menurut urutan daftar), opasitas cepat; layer keluar: zoom-in 3% dan geser 1.2%; layar meredup `wallDip` di tengah.
  Progres linear 0..1 (kelas C, `wallpaperFadeMs`), kurva `OutCubic` dibentuk di `WallMotion.e`. Saat picker terbuka, pergantian latar tetap instan
  karena yang terlihat adalah preview picker, yang memakai `WallMotion` yang sama.


---

## 7. Tata kerja

- Setiap fase = **satu zip + `sha256`**, supaya salah arah bisa dibatalkan tanpa kehilangan fase lain.
- **Aditif dulu, hapus belakangan.** Fase awal menambah token baru; token lama dihapus hanya di fase terakhir, setelah `grep`
  menunjukkan nol pemakai.
- Rujukan ke R1–R9 sudah tidak ada (P0): `docs/audits` kosong dan `settings-design.md` sudah tidak ada.

### Urutan fase (rencana awal, riwayat)
| Fase | Isi | Cek (otomatis) | Cek (mata) |
|---|---|---|---|
| P0 | Dokumen ini masuk; `DESIGN-CONTRACT.md` dan `.bak-kbnav` dihapus; rujukan di `settings-design.md` dirapikan | `grep -rn DESIGN-CONTRACT` kosong | — |
| P1 | Gerak: `Tween`, `TweenColor`, token `dur*`; semua animasi ke `Tween`; Notifs/OSD/Wallpaper ke `Reveal` | animasi tanpa easing = 0; tidak ada `NumberAnimation` mentah | semua panel terasa satu irama |
| P2 | Aksen: token `accent*`; `inverse*` diganti; state sesuai tabel 3.4 | `Theme.inverse` tersisa hanya pengecualian yang tercatat | aksen cuma muncul di tempat yang boleh |
| P3 | Token: Theme dirampingkan, ukuran komponen pindah ke file komponen, token mati dihapus | `Theme.qml` ≈ 70 properti; nol token tak terpakai | tidak ada yang berubah (murni refactor) |
| P4 | Skala visual: tipografi, spasi, radius, ikon | `grep` angka mentah bersih | **kerja paling banyak butuh mata** (±1–2 px bergeser) |
| P5 | Audit akhir, tabel status baru di dokumen ini | — | pemilik menandai tiap permukaan |

### Status akhir (10 Nov 2026) — semua fase ✅, kode patuh dan lolos uji pemilik

| Fase | Status | Catatan |
|---|---|---|
| P0 | ✅ | 3 file `.bak-20261110*` dihapus. `DESIGN-CONTRACT.md` dan `settings-design.md` sudah tidak ada di zip; `grep -rn DESIGN-CONTRACT` kosong kecuali dokumen ini. `docs/audits` kosong. |
| P1 | ✅ | `Tween`/`TweenColor` + token `dur*` + `revealOpenDamp`/`revealCloseDamp`. `Reveal` mengekspos `travel` dan sinyal `settled`. 9 panel memakai `travel` tanpa `Math.min`. Notifs, OSD, picker Wallpaper, PowerMenu, LockSurface pindah ke `Reveal`. `SpringAnimation` di SettingsAbout diganti `Tween` (lihat dulu efeknya). |
| P2 | ✅ | Token `accent`, `accentHover`, `textOnAccent`, `textOnAccentDim`, `tilePress`; `lineFocus` kini aksen 45%. `Theme.inverse*` diganti. Aksen juga dipasang di isi progres (OSD, media, Lock media), baterai saat mengisi, workspace aktif, seleksi teks Clipboard/Emoji. State ditekan (`tilePress`) dipasang di tile Control Center dan `ActionTile`. |
| P3 | ✅ | `Theme.qml` 426 → 88 properti (target ≈70 belum tercapai, lihat catatan). 51 token mati dibuang. 218 token ukuran komponen pindah ke file pemakainya sebagai `readonly property` di root (`root.xxx`); di dalam `component X:` (inline) disalin ke root inline-nya karena inline component tidak bisa lihat id luar. 29 token (kini 28 setelah `settingsRowTracking` jadi `trackSnug` di P4) yang dipakai bersama beberapa file Settings pindah ke singleton baru `core/theme/SettingsMetrics.qml` (terdaftar di `core/qmldir`). 3 file `.bak-20261110*` dihapus. |
| P4 | ✅ | Tipografi 6 langkah, spasi grid 4, radius 3 + pill, ikon 4 langkah, weight 3 token (`Font.Bold` → semibold), tracking 3 token. Warna digabung sesuai 3.1/3.2 kecuali yang "cek satu-satu" (lihat catatan). `grep` token font/angka mentah bersih. |
| P5 | ✅ | Audit akhir 10 Nov 2026 (kode). Hasil per permukaan di bagian "Audit P5" di bawah. |

Tambahan 10 Nov: animasi Power Menu, Lock (masuk dan keluar), dan pergantian wallpaper dirombak, lihat 6.4.

Pengecualian `Theme.inverse` yang tercatat: `LockMedia.qml` baris 56 dan 64 (tombol utama Lock tetap putih murni). `inverse` dan `inverseText` tetap ada di `Theme.qml` untuk itu.


Catatan pelaksanaan P3 dan P4 (riwayat, 10 Nov 2026):
- **Bug lama ketemu dan diperbaiki di P5:** `LockMedia.qml` memakai `Theme.lockMediaButton` dan `Theme.lockMediaButtonPrimary` yang tidak pernah didefinisikan (dikonfirmasi lewat `grep` di mesin pemilik). Sekarang `CtlButton` pakai konstanta lokal 32 dan 40 px.
- Enam warna gelap (`raised`, `canvas`, `black`, `inset`, `badge`, `well`) digabung ke `scrim` atas keputusan pemilik (10 Nov). Efek: `badge` 75%→45%, `well` 14%→45%, `inset` 30%→45%; `canvas`/`black`/`raised` yang tadinya solid kini transparan 45%, sudah diuji pemilik.
- `Theme.qml` berakhir di 81 properti, bukan ≈70. Sisa penyebab: `wall*`/`reveal*` (gerak), `list*`/`cheatsheetKeycap*` (dipakai lintas fitur).
- Warna yang berubah tampilan karena digabung: `dim` 55→60%, `faint` 30→40% (dan `muted` 40% ikut `faint`), `textSoft` 80%→100%, `tileFaint`/`tileMid`→`tile`, `selection` 30%→`tileHover` 15%, `lineStrong` 12%→`line` 8%, `ghost` 10%→`line`, `powerScrim` 55%→`scrim` 45%, `labelCapsText` 50%→`dim`.
- Bentuk: `radius` 16→`radiusCard` 12 (11 tempat), `radiusKey` 6→8. `radiusIndicator` dibuang: scrollbar dan bar preview pakai pill (`height/2`), bingkai seleksi dan titik rekam pakai konstanta lokal.
- Ikon 30 (Calendar) jadi konstanta lokal `weatherIconSize`. Font lapis 3 yang tidak ada di skala (24, 18, 44 dst. di Media, About, Weather) dibiarkan.
- Semua `Font.DemiBold/Medium/Normal` kini `Theme.weightSemibold/Medium/Regular`. 13 ekspresi kondisi dicek: semuanya memilih di antara tiga weight itu.

## Audit P5 (10 Nov 2026) — kode patuh dan lolos uji pemilik

Cek otomatis (semuanya dari `grep` di `features/` dan `shared/`, kecuali dicatat lain):

| Aturan | Hasil |
|---|---|
| `pixelSize: <angka>` mentah | 0 |
| `radius: <angka 2-9>` mentah | 0 |
| `duration: <angka>` mentah | 0 |
| `SpringAnimation` | 0 |
| `ColorAnimation` mentah (bukan `TweenColor`) | 0 |
| `Behavior on ...` tanpa `Tween`/`TweenColor` | 0 (2 hasil grep itu `Tween` di baris berikutnya) |
| `Math.min(1, anim/reveal...)` sisa di panel | 0 |
| `Font.DemiBold/Medium/Normal/Bold` mentah | 0 |
| Token font lama (`fontBody`, `fontTitle`, dst.) | 0 |
| Referensi `Theme.*` tanpa definisi | 0 (`LockMedia` pakai konstanta lokal 32/40 px, sudah dilihat pemilik) |
| Token `Theme` tak terpakai | 0 (`accentSoft` dihapus 10 Nov atas keputusan pemilik) |
| `Theme.inverse*` dipakai | 2, keduanya pengecualian tercatat (`LockMedia.qml`) |
| `DESIGN-CONTRACT` dan file `.bak` | 0 selain dokumen ini |
| `Theme.qml` | 81 properti (target awal ≈70, lihat A3) |
| `qmllint` (statis, tanpa modul Quickshell) | 0 error sintaks; warning sama dengan sebelum P3 |

Pengecualian warna di luar Theme (disengaja): `SettingsNightPreview.qml` (warna dihitung dari suhu night light) dan `SettingsAbout.qml` (border putih transparan supaya transisi tidak lewat hitam).

| Permukaan | Gerak (P1) | Aksen (P2) | Token dan skala (P3, P4) | Uji pemilik |
|---|---|---|---|---|
| MenuBar | ✅ | ✅ | ✅ | ✅ lolos |
| ControlCenter (+ Cc*, WifiList, BtList, DetailList, SliderBar) | ✅ | ✅ | ✅ | ✅ lolos |
| Calendar | ✅ | ✅ | ✅ | ✅ lolos |
| MediaPopup, MediaCard, LyricsView, MediaPlayerView | ✅ | ✅ | ✅ | ✅ lolos |
| TrayMenu | ✅ | ✅ | ✅ | ✅ lolos |
| Launcher | ✅ | ✅ | ✅ | ✅ lolos |
| Clipboard, EmojiPicker | ✅ | ✅ | ✅ | ✅ lolos |
| Notifs, NotificationHistory | ✅ | ✅ | ✅ | ✅ lolos |
| Osd | ✅ | ✅ | ✅ | ✅ lolos |
| PowerMenu | ✅ | ✅ | ✅ | ✅ lolos |
| Cheatsheet | ✅ | ✅ | ✅ | ✅ lolos |
| Wallpaper (picker, WallLayer) | ✅ | ✅ | ✅ | ✅ lolos |
| Overview, RegionSelector | ✅ | ✅ | ✅ | ✅ lolos |
| Lock (LockScreen, LockSurface, LockMedia) | ✅ | ✅ (kecuali tombol utama, lihat 7) | ✅ | ✅ lolos |
| Settings (SettingsApp + components) | ✅ | ✅ | ✅ | ✅ lolos |

Kolom "Uji pemilik": pemilik menjalankan semua permukaan di mesinnya dan menyatakan lolos (10 Nov 2026).

### Catatan akhir
1. `LockMedia` dulu memakai token yang tidak pernah ada. Sudah beres: `CtlButton` punya `sizeNormal` 32 dan `sizePrimary` 40.
3. `Theme.qml` 81 properti, bukan ≈70 (alasan di A3). Kalau mau lebih kecil: pindahkan `list*` ke komponen lokal dan `cheatsheetKeycap*` ke komponen keycap bersama.
4. Font lapis 3 di luar skala (24, 18, 44 di Media, About, Weather) dibiarkan sebagai konstanta lokal.
5. `SettingsMetrics` (singleton baru, 28 token) adalah penyimpangan dari "ukuran komponen di file komponen" karena dipakai banyak file Settings.
6. Agent tidak bisa menjalankan `qs`; pengujian jalan dilakukan pemilik di mesinnya dan lolos.

---

## 8. Keputusan dan sisa

Diputuskan pemilik shell (10 Nov 2026):
- Power Menu dan Lock ikut `Reveal`.
- Rasa `Reveal` dibuat lebih hidup (lihat 6.1, termasuk syarat membuka clamp `progress`).
- Rounding jendela Hyprland **ikut Hyprland** (sekarang 11): tidak diubah dan tidak jadi bagian skala shell.
- Weight teks dihitung (lihat 4.2): tiga weight, satu `Font.Bold` diganti.

- Warna aksen: putih keabuan `#E8E8E6` (lihat 3.3).
- Enam warna gelap digabung ke `scrim` (hitam 45%), bukan jadi putih, supaya teks putih di atasnya tetap terbaca.
- `accentSoft` dihapus karena tidak ada pemakainya. Kalau nanti perlu latar aksen halus, tambahkan lagi satu baris di `Theme.qml`.
- Tombol kontrol media di Lock: 32 px biasa, 40 px utama.

Masih terbuka: tidak ada.

---

## 9. Cek cepat untuk kode baru

Jalankan dari folder `macmono/`. Semuanya harus kosong (kecuali dicatat):
```
grep -rnE "pixelSize: *[0-9]|[^a-zA-Z]radius: *[2-9]|duration: *[0-9]" features shared      # angka mentah
grep -rnE "SpringAnimation|Font\.(DemiBold|Medium|Normal|Bold)" features shared            # gerak dan weight mentah
grep -rn "ColorAnimation" features shared | grep -v TweenColor                              # animasi warna mentah
grep -rnE "Qt\.rgba\(|\"#[0-9a-fA-F]{3,8}\"" features shared | grep -v "readonly property" # warna di luar Theme (2 pengecualian di Audit P5)
```
Aturan singkat: skala dan warna dari `Theme`, ukuran khusus satu komponen sebagai `readonly property` di root file itu,
buka/tutup lewat `Reveal`, gerak kecil lewat `Tween`/`TweenColor`, aksen hanya untuk yang sedang aktif.

---

## 10. Komponen bersama (P6, ditambahkan 10 Nov 2026)

Alasan: token sudah satu pintu, tapi tiap panel masih merakit rangka dan kontrolnya sendiri (rangka panel 4 baris yang sama
disalin di 12 file, 4 versi kolom cari, 5 gaya keadaan kosong, fokus keyboard tidak seragam). Mengubah satu hal visual berarti
mengulangnya di banyak tempat, dan itu yang membuat permukaan terasa berdiri sendiri-sendiri.

- **B1. Rangka panel mengambang = `Panel`** (`shared/components/Panel.qml`): kaca, garis, penahan klik, gerak laci lewat `travel`,
  fade isi lewat `progress`, `slideDistance` kalau panel tidak menempel di tepi atas. Dilarang menulis `radius: Theme.radiusPanel`
  bersama `color: Theme.panel` manual di file baru.
- **B2. Kolom cari = `UiSearchField`**: Esc menghapus teks dulu, baru memancarkan `escaped`; cincin fokus `lineFocus`; seleksi teks aksen;
  tombol navigasi ditangani pemakai lewat `keyPressed`.
- **B3. Keycap = `UiKeycap`, keadaan kosong = `UiEmptyState`.** Ukuran keycap masih dari token `cheatsheetKeycap*` di Theme
  (kandidat dipindah ke `UiKeycap` setelah `SettingsKeys` ikut).
- **Ratchet:** `scripts/development/check-design.sh` menjalankan cek bagian 9 plus B1 dan B3. Daftar file legacy di dalamnya hanya boleh
  menyusut; setiap file yang selesai dimigrasi dihapus dari daftar.

Status migrasi: pilot Calendar (Panel), EmojiPicker (UiSearchField), Cheatsheet (UiKeycap), Clipboard dan DetailList (UiEmptyState).
Sisanya ada di daftar legacy skrip (`--legacy`). **Belum diuji di mesin pemilik** (agent tidak bisa menjalankan `qs`).


---

## 11. Pengecualian: Control Center mengikuti mockup A (10 Nov 2026)

Diputuskan pemilik shell lewat mockup (dua adegan: tanpa notifikasi = panel menciut; ada notifikasi = panel melebar ke bawah).
Ini **pengecualian tercatat** dari bagian 3.3 dan 3.4, jangan "dibetulkan" balik ke aksen terang:

- **State aktif di Control Center = abu gelap, bukan `accent`.** Tile aktif memakai `tilePress` (putih 22%) dengan teks `text` (putih).
  Berlaku untuk tile Wi-Fi/Bluetooth, empat tile kecil (DND, Awake, Mic, Power), dan tombol rekam. Satu pintu: `CcTile.qml`.
  Tile Mic: state aktif = mic **muted** (mic selalu live, jadi "On" tidak informatif); sub-teks hanya "Muted".
- Isi slider = putih 32% di atas trek `tile` (konstanta `sliderFillAlpha` di `SliderBar.qml`); isi progres media = `text` pada `opacityDim`.
- Kartu dalam (tile, slider, media, baris notifikasi) tanpa border; hanya panel luarnya yang punya `line`.
- Ritme: jarak antar bagian `space16`, jarak antar tile `space8`, padding panel 20 (`ccPadding`), lebar panel 480.
- Judul bagian "NOTIFICATION HISTORY" dan teks kosong "No notifications" sengaja dihapus; riwayat kosong = tidak ada area sama sekali.
  Revisi 10 Nov 2026 (pemilik): tombol **Clear all** kembali, tapi hanya muncul saat ada notifikasi (rata kanan di atas baris riwayat).
  Hapus semua: tombol itu (bagian HISTORY di Settings > Notifications sudah dihapus 10 Nov 2026). Hapus satu: klik barisnya.
- Mockup tidak punya tile DND dan chevron output suara. Revisi 10 Nov 2026 (pemilik): **DND masuk Control Center** menggantikan tile Night;
  Night Light cukup di Settings > Display & Monitors karena jarang dipakai. Pilih output: klik angka volume.
- Tile Wi-Fi/Bluetooth: ikon di kiri = nyala/mati, badan tile = buka daftar.
- Warna `accent` global tidak diubah (masih `#E8E8E6`, dipakai surface lain). Kalau mau seluruh shell ikut gelap: ubah `accent` dan `textOnAccent` di `Theme.qml`.

---

## Lampiran A: token tak terpakai (35) — sudah dihapus di P3, disimpan sebagai arsip

`borderNone`, `calendarSmallButton`, `cheatsheetSectionLetterSpacing`, `clipFooterHeight`, `clipKeyHeight`, `easeOpen`, `emojiKeyHeight`,
`fontDisplaySm`, `inverseTile`, `launcherHintHeight`, `launcherPinHeight`, `launcherPinIcon`, `launcherPinIconBox`,
`launcherPreviewGlyph`, `launcherPreviewIcon`, `launcherPreviewPadding`, `launcherPreviewRow`, `launcherPreviewWidth`,
`launcherSearchHeight`, `launcherSectionHeight`, `launcherTagHeight`, `lineBody`, `lineTight`, `menubarPrivHeight`,
`openFromModal`, `openOvershoot`, `openScaleFrom`, `openScaleFromModal`, `osdBottomMargin`, `radiusLarge`, `springDamp`,
`springStiff`, `toolsRecordHeight`, `toolsSegmentHeight`, `veil`.

(Hitungan berasal dari `grep -ow "Theme\.<nama>"` di `features/`, `shared/`, `core/` pada zip 10 Nov 2026.)
