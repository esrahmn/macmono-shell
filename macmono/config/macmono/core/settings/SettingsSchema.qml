pragma Singleton

import QtQuick
import Quickshell

// ============================================================================
//  SETTINGSSCHEMA macmono: daftar halaman dan kontrol di aplikasi Pengaturan Sistem.
//
//  Tiap item: { key, label, desc?, type, def, ... }
//    type "slider"  : min, max, step, fmt
//    type "stepper" : min, max, step
//    type "toggle"  : boolean
//    type "chips"   : daftar; mono (font monospasi), num (hanya angka)
//    live: true     : bukan nilai Settings; membaca Sys[key] dan memanggil Sys[liveAction]()
//    preview (di grup)      : nama pratinjau yang digambar tepat di atas baris grup itu (lihat SettingsPanel):
//                             touchpad | pointer | keyboard | night | sleep | alert
//    sync: "input" | "idle" : setelah Apply, SettingsPanel memanggil Sys.hyprSync untuk menulis
//                             config Hyprland (input) atau hypridle (idle).
//  Opsi timing/guard/debounce sengaja TIDAK ditampilkan di sini (user nggak butuh); nilainya tetap
//  ada di Settings.qml dan bisa diubah lewat ~/.config/macmono/settings.json.
//
//  `def` HARUS sama dengan nilai bawaan di core/settings/Settings.qml (dipakai tombol "Bawaan").
//  Cek kecocokannya: python3 scripts/check-settings-defaults.py
//  Menambah opsi baru: tambah properti di Settings.qml (dibungkus SettingsStore.v),
//  lalu tambah satu baris item di sini.
// ============================================================================
Singleton {
    id: root

    function find(key) {
        for (const p of pages)
            for (const g of p.groups)
                for (const it of g.items)
                    if (it.key === key) return it;
        return null;
    }

    function format(item, v) {
        switch (item.fmt) {
        case "factor": return Number(v).toFixed(2);   // nilai 0..1 sebagai angka (0.60), supaya langkah 1% kelihatan
        case "pct":    return Math.round(v * 100) + "%";
        case "pctInt": return Math.round(v) + "%";
        case "x":      return Number(v).toFixed(2) + "×";
        case "K":      return Math.round(v) + " K";
        case "s":      return Math.round(v) + " s";
        case "min":    return Number(v) === 0 ? "Never" : Math.round(v) + " min";
        case "signed": return (v > 0 ? "+" : "") + Number(v).toFixed(2);
        case "lead":   return (v > 0 ? "+" : "") + Number(v).toFixed(2) + " s";
        case "ms":
            if (v < 1000) return Math.round(v) + " ms";
            return String(Number((v / 1000).toFixed(2))) + " s";
        default:       return String(v);
        }
    }

    // Jumlah item yang benar-benar bisa diubah; dipakai halaman About supaya angkanya tidak dihitung manual di QML.
    // Baris read-only (info/action) tidak ikut dihitung.
    readonly property int settingCount: {
        let n = 0;
        for (const p of pages)
            for (const g of p.groups)
                for (const it of g.items)
                    if (!it.ro) n++;
        return n;
    }

    readonly property var pages: [
        { id: "appearance", label: "Appearance", icon: "sunhalf", preview: "appearance", desc: "Panel readability and desktop clock", groups: [
            { title: "Interface", items: [
                { key: "panelOpacity", label: "Panel opacity", desc: "Higher is more solid and easier to read. Lower is more see-through.", type: "slider", min: 0.25, max: 1, step: 0.01, def: 0.60, fmt: "pct" } ] },
            { title: "Top bar clock", items: [
                { key: "clock24h", label: "24-hour clock", desc: "Use 14:30 instead of 2:30 PM.", type: "toggle", def: true },
                { key: "clockSeconds", label: "Show seconds", desc: "Display seconds alongside the time.", type: "toggle", def: false },
                { key: "clockDate", label: "Show date", desc: "Display the date in the top bar.", type: "toggle", def: false } ] } ] },

        { id: "display", label: "Display & Monitors", icon: "monitor", desc: "Resolution, refresh rate, scale and Night Light", monitors: true, groups: [
            { title: "Night Light", preview: "night", items: [
                { key: "nightLight", label: "Night Light", desc: "Reduce blue light using a warmer display tone.", type: "toggle", live: true, liveAction: "toggleNightLight", def: false },
                { key: "nightLightKelvin", label: "Night Light warmth", desc: "Screen color when Night Light is on. Lower number = warmer, more orange.", type: "slider", min: 2500, max: 6500, step: 100, def: 4200, fmt: "K" },
                { key: "nightLightOffKelvin", label: "Normal screen color", desc: "Screen color when Night Light is off. 6500 K is the standard.", type: "slider", min: 5000, max: 8000, step: 100, def: 6500, fmt: "K" } ] },
            { title: "Brightness keys", items: [
                { key: "brightnessStep", label: "Brightness key step", desc: "How much brightness changes each time you press a brightness key.", type: "slider", min: 0.01, max: 0.2, step: 0.01, def: 0.05, fmt: "pct" } ] } ] },

        { id: "input", label: "Keyboard & Mouse", icon: "keyboard", desc: "Touchpad, pointer speed and keyboard behavior", groups: [
            { title: "Touchpad", preview: "touchpad", items: [
                { key: "inputNaturalScroll", label: "Natural scrolling", desc: "Content follows the direction of your fingers.", type: "toggle", def: true, sync: "input" },
                { key: "inputTapToClick", label: "Tap to click", desc: "Tap the touchpad instead of pressing it.", type: "toggle", def: true, sync: "input" },
                { key: "inputDisableWhileTyping", label: "Disable while typing", desc: "Prevent accidental touchpad input while typing.", type: "toggle", def: true, sync: "input" },
                { key: "inputClickfinger", label: "Click by finger count", desc: "Click with one, two or three fingers for left, right or middle click, instead of using the pad corners.", type: "toggle", def: false, sync: "input" },
                { key: "inputScrollFactor", label: "Scroll speed", desc: "How fast pages scroll. 1.00× is normal.", type: "slider", min: 0.2, max: 3, step: 0.05, def: 1, fmt: "x", sync: "input" } ] },
            { title: "Pointer", preview: "pointer", items: [
                { key: "inputSensitivity", label: "Pointer speed", desc: "How fast the pointer moves. Negative is slower, positive is faster, 0 is normal.", type: "slider", min: -1, max: 1, step: 0.05, def: 0, fmt: "signed", sync: "input" } ] },
            { title: "Keyboard", preview: "keyboard", items: [
                { key: "inputRepeatRate", label: "Key repeat speed", desc: "Characters per second while you hold a key.", type: "stepper", min: 5, max: 60, step: 5, def: 25, sync: "input" },
                { key: "inputRepeatDelayMs", label: "Key repeat delay", desc: "How long to hold a key before it repeats.", type: "slider", min: 150, max: 1000, step: 10, def: 600, fmt: "ms", sync: "input" } ] },
            { title: "Layout", items: [
                { key: "inputKbLayouts", label: "Keyboard layouts", desc: "Short codes like us or id. Type one and press Enter. The first one is the default. Empty = use the Hyprland config.", type: "chips", mono: true, def: [], sync: "input" },
                { key: "inputKbVariants", label: "Layout variants", desc: "Optional. One variant per layout, same order. Leave empty for the standard layout.", type: "chips", mono: true, def: [], sync: "input" },
                { key: "inputKbOptions", label: "Layout options", desc: "Optional extras. For example grp:alt_shift_toggle lets you switch layouts with Alt+Shift.", type: "chips", mono: true, def: [], sync: "input" } ] } ] },

        // Halaman tanpa item schema: `sound: true` dirender SettingsSound (output, input, volume per aplikasi).
        { id: "sound", label: "Sound", icon: "volume", desc: "Output, input, per-app volume and music visualizer", sound: true, groups: [] },

        // Halaman tanpa item schema: `eq: true` dirender SettingsEqualizer (10 band + kurva respons, via Easy Effects).
        { id: "eq", label: "Equalizer", icon: "eq", desc: "Adjust bass, voice and treble for all system sound", eq: true, groups: [] },

        { id: "weather", label: "Location & Weather", icon: "pin", desc: "Choose the city and temperature units used by weather", weather: true, groups: [] },

        { id: "wallpaper", label: "Wallpaper", icon: "image", preview: "wallpaper", desc: "Choose folders used to find desktop wallpapers", groups: [
            { title: "Wallpaper library", items: [
                { key: "wallpaperDirs", label: "Wallpaper folders", desc: "Folders searched for wallpapers. Type a path and press Enter. Folders higher in the list come first.", type: "chips", mono: true,
                  def: ["~/Pictures/Wallpapers", "~/Pictures", "~/Wallpapers", "~/.local/share/backgrounds", "/usr/share/backgrounds", "/usr/share/wallpapers"] } ] } ] },

        // Halaman tanpa item schema: `notifications: true` dirender SettingsNotifications
        // (jadwal DND + mute per aplikasi). notifDefaultTimeoutMs tetap ada di Settings.qml
        // sebagai knob developer dan sengaja tidak tampil lagi di UI.
        { id: "notif", label: "Notifications", icon: "bell", desc: "Do Not Disturb schedule and per-application mute", notifications: true, groups: [] },

        // Halaman tanpa item schema: `backup: true` dirender SettingsBackup.
        { id: "backup", label: "Backup & Reset", icon: "archive", desc: "Save or restore your settings", backup: true, groups: [] },

        // Halaman tanpa item schema: `apps: true` dirender SettingsApps (autostart XDG).
        { id: "apps", label: "Apps & Startup", icon: "apps", desc: "Applications that start with your session", apps: true, groups: [] },

        { id: "power", label: "Power & Battery", icon: "bolt", desc: "Screen lock, sleep and battery warnings", power: true, groups: [
            { title: "Screen & sleep", preview: "sleep", items: [
                { key: "idleLockMin", label: "Lock screen after", desc: "Time without keyboard or mouse activity. 0 = never.", type: "slider", min: 0, max: 60, step: 1, def: 5, fmt: "min", sync: "idle" },
                { key: "idleScreenOffMin", label: "Turn screen off after", desc: "Automatically turn off the display after inactivity. 0 = never.", type: "slider", min: 0, max: 120, step: 1, def: 10, fmt: "min", sync: "idle" },
                { key: "idleSuspendMin", label: "Suspend after", desc: "Put the computer to sleep after inactivity. 0 = never.", type: "slider", min: 0, max: 180, step: 1, def: 15, fmt: "min", sync: "idle" } ] },
            { title: "Battery alerts", preview: "alert", items: [
                { key: "batteryWarnLevels", label: "Low battery alert levels", desc: "Show a warning when the battery drops to each of these percentages.", type: "chips", num: true, def: [5, 10, 20] },
                { key: "batteryCriticalLevel", label: "Critical battery level", desc: "At or below this level, battery warnings become urgent.", type: "slider", min: 3, max: 30, step: 1, def: 10, fmt: "pctInt" } ] } ] },

        // Pintasan memakai sumber data yang sama dengan Cheatsheet.
        { id: "keys", label: "Keyboard Shortcuts", icon: "command", desc: "View MacMono keyboard shortcuts", keys: true, groups: [] },

        // Halaman tanpa item schema: `about: true` dirender SettingsAbout (ringkasan komputer, tanpa path).
        { id: "about", label: "About MacMono", icon: "enso", desc: "Computer model, processor, memory, system and software versions", about: true, groups: [] }
    ]
}
