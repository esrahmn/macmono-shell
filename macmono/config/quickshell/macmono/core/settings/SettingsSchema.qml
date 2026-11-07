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
        { id: "appearance", label: "Appearance", icon: "sunhalf", desc: "Panel opacity and theme", groups: [
            { title: "Panel", items: [
                { key: "panelOpacity", label: "Panel opacity", desc: "One value for the top bar, all panels and popups. Raise it if text is hard to read on a bright wallpaper.",
                  type: "slider", min: 0.25, max: 1, step: 0.01, def: 0.60, fmt: "factor" } ] } ] },

        { id: "topbar", label: "Top Bar", icon: "window", desc: "Workspaces in the menu bar", groups: [
            { title: "Workspace", items: [
                { key: "menubarWorkspaceMin", label: "Minimum workspace dots", desc: "Always shown in the top bar.", type: "stepper", min: 1, max: 10, step: 1, def: 5 },
                { key: "menubarWorkspaceMax", label: "Maximum workspace dots", desc: "Workspaces above this number are hidden.", type: "stepper", min: 1, max: 20, step: 1, def: 10 } ] } ] },

        { id: "clock", label: "Clock", icon: "clock", desc: "Time and date in the top bar", groups: [
            { title: "Top bar clock", items: [
                { key: "clock24h", label: "24-hour clock", desc: "Off switches to 3:25 PM.", type: "toggle", def: true },
                { key: "clockSeconds", label: "Show seconds", desc: "The bar gets wider and redraws every second.", type: "toggle", def: false },
                { key: "clockDate", label: "Show date", desc: "Day and date are placed before the time.", type: "toggle", def: false } ] } ] },

        { id: "launcher", label: "Launcher", icon: "grid", desc: "Super key, pinned apps, overview", groups: [
            { title: "Launcher", items: [
                { key: "launcherMaxResults", label: "Max app results", desc: "Windows, Actions and Top Hit are not limited.", type: "stepper", min: 3, max: 20, step: 1, def: 9 },
                { key: "superTapMaxMs", label: "Super key tap threshold", desc: "Released faster than this opens the launcher.", type: "slider", min: 150, max: 1000, step: 10, def: 450, fmt: "ms" },
                { key: "pinnedApps", label: "Pinned apps", desc: ".desktop file names without the extension.", type: "chips", mono: true,
                  def: ["kitty", "google-chrome", "spotify", "org.kde.dolphin", "discord", "steam", "com.microsoft.VSCode", "com.obsproject.Studio"] } ] },
            { title: "Workspace overview", items: [
                { key: "overviewRows", label: "Rows", type: "stepper", min: 1, max: 4, step: 1, def: 2 },
                { key: "overviewColumns", label: "Columns", desc: "2 × 5 = workspaces 1–10.", type: "stepper", min: 1, max: 10, step: 1, def: 5 },
                { key: "overviewScale", label: "Workspace scale", desc: "Relative to the screen size.", type: "slider", min: 0.08, max: 0.3, step: 0.01, def: 0.14, fmt: "x" },
                { key: "overviewLivePreview", label: "Live window previews", desc: "Turn off for icons only (lighter).", type: "toggle", def: true } ] } ] },

        { id: "clipboard", label: "Clipboard", icon: "clipboard", desc: "Copy history", groups: [
            { title: "History", items: [
                { key: "clipboardMaxItems", label: "Max history entries", desc: "Number of entries shown in Super+V.", type: "stepper", min: 20, max: 1000, step: 20, def: 200 } ] } ] },

        { id: "notif", label: "Notifications & OSD", icon: "bell", desc: "Timeouts and history", groups: [
            { title: "Notifications", items: [
                { key: "notifDefaultTimeoutMs", label: "Default display time", desc: "Used when the app does not set one. Urgent notifications never expire on their own.", type: "slider", min: 1000, max: 15000, step: 500, def: 5000, fmt: "ms" },
                { key: "notifHistoryMax", label: "Max history", desc: "Kept in the notification center.", type: "stepper", min: 10, max: 200, step: 10, def: 50 } ] },
            { title: "Volume & brightness OSD", items: [
                { key: "osdHideMs", label: "OSD display time", type: "slider", min: 400, max: 4000, step: 100, def: 1400, fmt: "ms" } ] } ] },

        { id: "display", label: "Display", icon: "sun", desc: "Night Light and brightness", groups: [
            { title: "Night Light", items: [
                { key: "nightLight", label: "Night Light", desc: "Via hyprsunset. Takes effect immediately, without the Apply button.", type: "toggle", live: true, liveAction: "toggleNightLight", def: false },
                { key: "nightLightKelvin", label: "Active color temperature", desc: "Lower is warmer.", type: "slider", min: 2500, max: 6500, step: 100, def: 4200, fmt: "K" },
                { key: "nightLightOffKelvin", label: "Normal color temperature", type: "slider", min: 5000, max: 8000, step: 100, def: 6500, fmt: "K" } ] },
            { title: "Brightness", items: [
                { key: "brightnessStep", label: "Brightness key step", type: "slider", min: 0.01, max: 0.2, step: 0.01, def: 0.05, fmt: "pct" },
                { key: "brightnessDebounceMs", label: "Debounce brightnessctl", desc: "Delay before the value is sent while dragging the slider.", type: "slider", min: 20, max: 400, step: 10, def: 80, fmt: "ms" },
                { key: "brightnessDdcDebounceMs", label: "External monitor debounce", desc: "ddcutil is slower.", type: "slider", min: 100, max: 800, step: 10, def: 250, fmt: "ms" } ] } ] },

        { id: "wallpaper", label: "Wallpaper", icon: "image", desc: "Folders and scanning", groups: [
            { title: "Sources", items: [
                { key: "wallpaperDirs", label: "Wallpaper folders", desc: "Order = priority, duplicates are dropped.", type: "chips", mono: true,
                  def: ["~/Pictures/Wallpapers", "~/Pictures", "~/Wallpapers", "~/.local/share/backgrounds", "/usr/share/backgrounds", "/usr/share/wallpapers"] },
                { key: "wallpaperScanDepth", label: "Subfolder depth", type: "stepper", min: 0, max: 6, step: 1, def: 2 },
                { key: "wallpaperMaxFiles", label: "Max images loaded", type: "stepper", min: 50, max: 2000, step: 50, def: 500 } ] } ] },

        { id: "network", label: "Network", icon: "wifi", desc: "Wi-Fi and Bluetooth", groups: [
            { title: "Wi-Fi", items: [
                { key: "wifiStatusPollMs", label: "Status recheck", desc: "Fallback; changes are already caught by nmcli monitor.", type: "slider", min: 5000, max: 120000, step: 5000, def: 30000, fmt: "ms" },
                { key: "wifiConnectTimeoutMs", label: "Connect timeout", type: "slider", min: 10000, max: 120000, step: 5000, def: 45000, fmt: "ms" },
                { key: "wifiMaxNetworks", label: "Max networks in list", type: "stepper", min: 5, max: 40, step: 1, def: 16 } ] },
            { title: "Bluetooth", items: [
                { key: "btPairTimeoutSec", label: "Pairing timeout", type: "slider", min: 10, max: 120, step: 5, def: 30, fmt: "s" } ] } ] },

        { id: "battery", label: "Battery", icon: "bolt", desc: "Level warnings", groups: [
            { title: "Warnings", items: [
                { key: "batteryWarnLevels", label: "Warning levels (%)", desc: "Sorted from low to high.", type: "chips", num: true, def: [5, 10, 20] },
                { key: "batteryCriticalLevel", label: "Critical level", desc: "Below this, notifications are sent as urgent.", type: "slider", min: 3, max: 30, step: 1, def: 10, fmt: "pctInt" } ] } ] },

        { id: "media", label: "Media & Lyrics", icon: "music", desc: "Lyrics sync and polling", groups: [
            { title: "Lyrics", items: [
                { key: "lyricsLeadSeconds", label: "Lyrics offset", desc: "Positive = lines appear earlier.", type: "slider", min: -1, max: 1, step: 0.05, def: 0.15, fmt: "lead" },
                { key: "lyricsSyncIntervalMs", label: "Sync interval", desc: "Lower is more precise but uses more power.", type: "slider", min: 16, max: 200, step: 2, def: 40, fmt: "ms" },
                { key: "lyricsRequestTimeoutMs", label: "Lyrics fetch timeout", type: "slider", min: 3000, max: 30000, step: 1000, def: 11000, fmt: "ms" },
                { key: "lyricsRetryDelayMs", label: "Retry delay", type: "slider", min: 500, max: 10000, step: 500, def: 3000, fmt: "ms" } ] },
            { title: "Player", items: [
                { key: "mediaPollIntervalMs", label: "Track position polling", desc: "6000 = efficient, 2000 = responsive.", type: "slider", min: 1000, max: 10000, step: 500, def: 3000, fmt: "ms" } ] } ] },

        { id: "capture", label: "Capture & Privacy", icon: "camera", desc: "Screenshot, recording, indicators", groups: [
            { title: "Screenshot & screen recording", items: [
                { key: "panelCloseDelayMs", label: "Delay after panel closes", desc: "Must be ≥ the panel close animation.", type: "slider", min: 100, max: 1000, step: 20, def: 380, fmt: "ms" },
                { key: "recordStartTimeoutMs", label: "Recording start wait (full screen)", type: "slider", min: 3000, max: 30000, step: 1000, def: 15000, fmt: "ms" },
                { key: "recordStartTimeoutAreaMs", label: "Recording start wait (select area)", type: "slider", min: 30000, max: 300000, step: 10000, def: 120000, fmt: "ms" },
                { key: "recordStopGraceMs", label: "wf-recorder stop wait", type: "slider", min: 2000, max: 20000, step: 1000, def: 8000, fmt: "ms" } ] },
            { title: "Privacy indicators", items: [
                { key: "privacyPollActiveMs", label: "Camera & recorder check", desc: "Only while a window that can open the camera exists.", type: "slider", min: 500, max: 10000, step: 500, def: 2000, fmt: "ms" } ] } ] },

        { id: "lock", label: "Lock & Power", icon: "lock", desc: "Lock screen and confirmation", groups: [
            { title: "Lock screen", items: [
                { key: "lockPamTimeoutMs", label: "Verification timeout", type: "slider", min: 3000, max: 30000, step: 1000, def: 10000, fmt: "ms" },
                { key: "lockClearPasswordMs", label: "Auto-clear password", desc: "A password typed and then left alone.", type: "slider", min: 5000, max: 120000, step: 5000, def: 30000, fmt: "ms" } ] },
            { title: "Power menu", items: [
                { key: "powerConfirmMs", label: "Second-click confirmation window", desc: "Log Out / Restart / Shut Down.", type: "slider", min: 1000, max: 8000, step: 500, def: 3000, fmt: "ms" } ] } ] },

        { id: "advanced", label: "Advanced", icon: "sliders", desc: "Rarely needs changing", groups: [
            { title: "Delays & guards", items: [
                { key: "trayReopenGuardMs", label: "Tray reopen guard", type: "slider", min: 0, max: 1000, step: 20, def: 200, fmt: "ms" },
                { key: "panelReopenGuardMs", label: "Panel reopen guard", type: "slider", min: 0, max: 1000, step: 20, def: 300, fmt: "ms" },
                { key: "focusSettleDelayMs", label: "Focus settle delay", type: "slider", min: 0, max: 500, step: 10, def: 120, fmt: "ms" },
                { key: "lockCapsRecheckMs", label: "Caps Lock recheck", type: "slider", min: 20, max: 500, step: 10, def: 60, fmt: "ms" } ] },
            { title: "Startup & storage", items: [
                { key: "osdStartupGraceMs", label: "OSD quiet after startup", type: "slider", min: 0, max: 10000, step: 250, def: 2500, fmt: "ms" },
                { key: "batteryStartupDelayMs", label: "Battery warning delay", type: "slider", min: 0, max: 15000, step: 500, def: 4000, fmt: "ms" },
                { key: "notifSaveDelayMs", label: "Notification history save delay", type: "slider", min: 200, max: 5000, step: 100, def: 1000, fmt: "ms" } ] },
            { title: "Debounce & timeout", items: [
                { key: "clipboardDetailDebounceMs", label: "Clipboard detail debounce", type: "slider", min: 0, max: 500, step: 10, def: 70, fmt: "ms" },
                { key: "wallpaperPreviewDebounceMs", label: "Wallpaper preview debounce", type: "slider", min: 0, max: 500, step: 10, def: 90, fmt: "ms" },
                { key: "wallpaperReadyTimeoutMs", label: "Wallpaper ready timeout", type: "slider", min: 2000, max: 20000, step: 500, def: 8000, fmt: "ms" },
                { key: "overviewPreviewRetryMs", label: "Overview preview retry", type: "slider", min: 100, max: 3000, step: 100, def: 700, fmt: "ms" } ] } ] },

        // Halaman pintasan: tidak punya item, isinya dibaca langsung dari core/shortcuts/KeyList.qml
        // (sumber data yang sama dengan Cheatsheet) supaya dua daftar tidak bisa berbeda.
        { id: "keys", label: "Keyboard Shortcuts", icon: "text", desc: "Every key macmono listens to", keys: true, groups: [] },

        // Halaman About: cuma membaca nilai, tidak pernah masuk `draft`.
        // Halaman About: cuma membaca nilai, tidak pernah masuk `draft`.
        // `about: true` membuat SettingsPanel menggambar header logo + nama OS di atasnya.
        { id: "about", label: "About", icon: "enso", desc: "System information and paths", about: true, groups: [
            { title: "System", items: [
                { key: "aboutOs", label: "Operating system", type: "info", ro: true, info: "os" },
                { key: "aboutKernel", label: "Kernel", type: "info", ro: true, info: "kernel" },
                { key: "aboutArch", label: "Architecture", type: "info", ro: true, info: "arch" },
                { key: "aboutUptime", label: "Uptime", desc: "Since boot.", type: "info", ro: true, info: "uptime" } ] },
            { title: "This shell", items: [
                { key: "aboutSettingsFile", label: "Settings file", type: "info", ro: true, info: "settingsPath" },
                { key: "aboutConfigFolder", label: "Config folder", type: "info", ro: true, info: "configFolder" },
                { key: "aboutCounts", label: "Pages · settings", type: "info", ro: true, info: "counts" } ] },
            { title: "Actions", items: [
                { key: "aboutOpenFolder", label: "Open settings folder", type: "action", ro: true, action: "openFolder" } ] } ] }
    ]
}
