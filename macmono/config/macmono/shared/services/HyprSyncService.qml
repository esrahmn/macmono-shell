import QtQuick
import Quickshell
import Quickshell.Io

// Menerjemahkan pilihan Pengaturan ke config sistem:
//   Input -> blok "input" di ~/.config/hypr/custom/macmono-generated.lua (hl.config { input = ... }),
//            lewat scripts/hypr/apply-generated.sh --section input (backup, reload, cek error, balik kalau error).
//   Semua setelan generated macmono memakai SATU file (blok bertanda); jangan bikin file generated kedua.
//   Power -> ~/.config/hypr/hypridle.conf lewat scripts/hypr/apply-idle.sh (lalu hypridle dimulai ulang).
// Nilai datang dari Settings lewat Sys (inputValues, idleMinutes). Dipanggil SettingsPanel setelah Apply.
// Kalau gagal: notifikasi lewat notify-send; config lama sudah dikembalikan oleh script.
// Opsi input dicek ke wiki.hypr.land (Config options: input, input.touchpad), sintaks hl.config({ ... }).
Scope {
    id: root

    property var inputValues: ({})    // sensitivity, repeatRate, repeatDelay, naturalScroll, tapToClick, disableWhileTyping, clickfinger, scrollFactor, kbLayouts, kbVariants, kbOptions
    property var idleMinutes: ({})    // lock, screenOff, suspend (0 = mati)

    readonly property string genScript: Quickshell.shellDir + "/scripts/hypr/apply-generated.sh"
    readonly property string idleScript: Quickshell.shellDir + "/scripts/hypr/apply-idle.sh"

    function syncInput() { inputDebounce.restart(); }
    function syncIdle() { idleDebounce.restart(); }

    // Tunggu sebentar supaya binding Settings sudah memuat nilai yang baru disimpan.
    Timer { id: inputDebounce; interval: 150; onTriggered: root.runInput() }
    Timer { id: idleDebounce; interval: 150; onTriggered: root.runIdle() }

    function bool(b) { return b ? "true" : "false"; }
    // XKB memakai daftar dipisah koma; elemen kosong dibuang supaya nggak jadi ",,".
    function csv(list) {
        if (!list || list.length === 0) return "";
        return list.map(x => String(x).trim()).filter(x => x !== "").join(",");
    }
    function buildInputLua() {
        const v = inputValues;
        const lines = [
            "hl.config({",
            "    input = {",
            "        sensitivity = " + Number(v.sensitivity).toFixed(2) + ",",
            "        repeat_rate = " + Math.round(v.repeatRate) + ",",
            "        repeat_delay = " + Math.round(v.repeatDelay) + ",",
            "        touchpad = {",
            "            natural_scroll = " + bool(v.naturalScroll) + ",",
            "            tap_to_click = " + bool(v.tapToClick) + ",",
            "            disable_while_typing = " + bool(v.disableWhileTyping) + ",",
            "            clickfinger_behavior = " + bool(v.clickfinger) + ",",
            "            scroll_factor = " + Number(v.scrollFactor).toFixed(2) + ",",
            "        }"
        ];
        // Layout cuma ditulis kalau user mengisinya. Kalau kosong, layout dari config lain
        // (mis. hyprland-gui.lua) tetap dipakai; menulis kb_layout = "" justru merusaknya.
        const kb = [["kb_layout", csv(v.kbLayouts)], ["kb_variant", csv(v.kbVariants)], ["kb_options", csv(v.kbOptions)]];
        for (let i = 0; i < kb.length; i++)
            if (kb[i][1] !== "") lines.push("        " + kb[i][0] + " = " + JSON.stringify(kb[i][1]) + ",");
        lines.push("    },", "})", "");
        return lines.join("\n");
    }

    function notify(msg) {
        Quickshell.execDetached(["notify-send", "-a", "macmono", "-u", "normal", "Settings", msg]);
    }

    // ---- Input ----
    property bool inputPending: false
    function runInput() {
        if (inputProc.running) { inputPending = true; return; }
        inputProc.stdinEnabled = true;
        inputProc.command = ["bash", genScript, "--section", "input", "apply"];
        inputProc.running = true;
    }
    Process {
        id: inputProc
        stdinEnabled: true
        stderr: StdioCollector { id: inputErr }
        onStarted: { write(root.buildInputLua()); stdinEnabled = false; }
        onExited: (code) => {
            if (code !== 0) root.notify("Input settings were not applied: " + (inputErr.text.trim() || "Hyprland rejected the config.") + " The previous config was restored.");
            if (root.inputPending) { root.inputPending = false; root.runInput(); }
        }
    }

    // ---- Power (idle) ----
    property bool idlePending: false
    function runIdle() {
        if (idleProc.running) { idlePending = true; return; }
        const m = idleMinutes;
        idleProc.command = ["bash", idleScript, "apply", String(Math.round(m.lock)), String(Math.round(m.screenOff)), String(Math.round(m.suspend))];
        idleProc.running = true;
    }
    Process {
        id: idleProc
        stderr: StdioCollector { id: idleErr }
        onExited: (code) => {
            if (code !== 0) root.notify("Power settings were not applied: " + (idleErr.text.trim() || "hypridle did not restart.") + " The previous config was restored.");
            if (root.idlePending) { root.idlePending = false; root.runIdle(); }
        }
    }
}
