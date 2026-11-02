import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Nama shortcut sengaja SAMA dengan yang dipakai keybind & hypridle end4,
// jadi Super, Super+N, Super+L, Ctrl+Super+T, Super+Shift+S, auto-lock idle, dst langsung nyambung ke macmono.
Scope {
    id: root

    // =====================================================================
    //  Super (tap) -> launcher
    // =====================================================================
    // Di Hyprland 0.57, bind dengan { release = true } cuma ngirim event "released".
    // onPressed di searchToggleRelease jadi nggak pernah jalan, makanya waktu tekan
    // juga dicatat dari bind transparan SUPER_L -> quickshell:workspaceNumber (bawaan end4).
    // Default true (sama seperti ii), biar tap pertama langsung jalan.
    property bool superMightTrigger: true
    property real superPressedAt: 0
    property var wsAtPress: null
    property var winAtPress: null

    function armSuper() {
        superPressedAt = Date.now();
        wsAtPress = Hyprland.focusedWorkspace?.id ?? null;
        winAtPress = ToplevelManager.activeToplevel;
    }

    function releaseSuper() {
        const pressedAt = superPressedAt;
        superPressedAt = 0;
        if (!superMightTrigger) { superMightTrigger = true; return; }
        if (pressedAt > 0) {
            if (Date.now() - pressedAt > 450) return;                                 // ditahan lama
            if ((Hyprland.focusedWorkspace?.id ?? null) !== wsAtPress) return;        // habis Super+angka
            if (ToplevelManager.activeToplevel !== winAtPress) return;                // habis Super+panah/Q/dll
        }
        Sys.toggleLauncher();
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "macmono: toggle launcher saat Super dilepas"
        onPressed: root.armSuper()
        onReleased: root.releaseSuper()
    }
    GlobalShortcut {
        name: "workspaceNumber"
        description: "macmono: catat waktu Super ditekan"
        onPressed: root.armSuper()
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "macmono: batalin toggle launcher (Super dipakai buat kombinasi)"
        onPressed: root.superMightTrigger = false
    }
    GlobalShortcut { name: "searchToggle"; description: "macmono: toggle launcher"; onPressed: Sys.toggleLauncher() }

    // =====================================================================
    //  Lock (Super+L lewat loginctl -> hypridle, dan auto-lock idle)
    // =====================================================================
    GlobalShortcut { name: "lock"; description: "macmono: lock screen"; onPressed: Sys.lock() }
    GlobalShortcut { name: "lockFocus"; description: "macmono: fokus ulang lock setelah resume"; onPressed: Sys.lockRefocus() }

    // =====================================================================
    //  Fitur macmono
    // =====================================================================
    // shortcut end4 yang sebelumnya mati, sekarang dipakai fitur macmono
    GlobalShortcut { name: "sidebarLeftToggle";   description: "macmono: kalender & notifikasi"; onPressed: Sys.toggleCalendar(Sys.focusedScreenName()) }
    GlobalShortcut { name: "mediaControlsToggle"; description: "macmono: kontrol media";        onPressed: Sys.toggleMedia() }
    GlobalShortcut { name: "cheatsheetToggle";    description: "macmono: daftar shortcut";      onPressed: Sys.toggleCheat() }
    GlobalShortcut { name: "sidebarRightToggle";  description: "macmono: control center";  onPressed: Sys.toggleCC(Sys.focusedScreenName()) }
    GlobalShortcut { name: "wallpaperSelectorToggle"; description: "macmono: wallpaper picker"; onPressed: Sys.toggleWallpaper() }
    GlobalShortcut { name: "wallpaperSelectorRandom"; description: "macmono: random wallpaper"; onPressed: Sys.randomWallpaper() }
    GlobalShortcut { name: "regionScreenshot";    description: "macmono: screenshot";       onPressed: Sys.screenshot("copy", false) }
    GlobalShortcut { name: "barToggle";           description: "macmono: toggle menubar";    onPressed: Sys.barVisible = !Sys.barVisible }

    // =====================================================================
    //  Pengganti fitur ii yang nggak ada di macmono.
    //  Keybind end4 pakai pola "qs ipc call TEST_ALIVE || fallback": selama qs hidup,
    //  fallback-nya nggak pernah jalan, jadi tombol-tombol ini mati kalau nggak ditangkap di sini.
    // =====================================================================
    function sh(cmd) {
        closeAll();
        Quickshell.execDetached(["bash", "-c", cmd]);
    }
    function closeAll() { Sys.closeCCQuiet(); }

    GlobalShortcut {
        name: "overviewClipboardToggle"   // Super+V
        description: "macmono: riwayat clipboard"
        onPressed: Sys.toggleClipboard()
    }
    GlobalShortcut {
        name: "overviewEmojiToggle"       // Super+.
        description: "macmono: emoji picker (fuzzel)"
        onPressed: root.sh("pkill fuzzel || \"$HOME/.config/hypr/hyprland/scripts/fuzzel-emoji.sh\" copy")
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"  // Super+Tab & gesture 4 jari atas/bawah
        description: "macmono: buka launcher (ala Launchpad)"
        onPressed: Sys.toggleLauncher()
    }
    GlobalShortcut {
        name: "sessionToggle"             // Ctrl+Alt+Del
        description: "macmono: menu power"
        onPressed: Sys.togglePower()
    }
    GlobalShortcut {
        name: "regionSearch"              // Super+Shift+A
        description: "macmono: Google Lens dari area layar"
        onPressed: root.sh("pidof slurp || \"$HOME/.config/hypr/hyprland/scripts/snip_to_search.sh\"")
    }
    GlobalShortcut {
        name: "regionOcr"                 // Super+Shift+X
        description: "macmono: OCR area layar ke clipboard"
        onPressed: Sys.screenshot("ocr", false)   // pakai pemilih area macmono (layar dibekukan)
    }
    // Super+Shift+R (regionRecord) sengaja nggak dipakai: rekam layar cukup dari Control Center (⋯ → Record).

    // =====================================================================
    //  IPC
    // =====================================================================
    // Alternatif lewat CLI: qs -c macmono ipc call launcher toggle
    IpcHandler { target: "launcher";  function toggle(): void { Sys.toggleLauncher(); } }
    IpcHandler {
        target: "control"
        function toggle(): void { Sys.toggleCC(Sys.focusedScreenName()); }
        function recordingStarted(): void { Sys.recordingStarted(); }
        function recordingCancelled(): void { Sys.recordingCancelled(); }
    }
    IpcHandler {
        target: "lock"
        function activate(): void { Sys.lock(); }
        function focus(): void { Sys.lockRefocus(); }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Sys.toggleWallpaper(); }
        function random(): void { Sys.randomWallpaper(); }
    }

    // Tombol brightness end4: "qs ipc call brightness increment || brightnessctl ..."
    // Tanpa target ini, perintahnya tetap exit 0 (instance hidup) dan brightnessctl nggak pernah jalan.
    IpcHandler {
        target: "brightness"
        function increment(): void { Sys.setBrightness(Sys.brightness + 0.05); }
        function decrement(): void { Sys.setBrightness(Sys.brightness - 0.05); }
    }
    // Dipanggil watcher cliphist di execs.lua tiap ada salinan baru -> daftar clipboard di-refresh.
    IpcHandler { target: "cliphistService"; function update(): void { Sys.clipboardUpdated(); } }
}
