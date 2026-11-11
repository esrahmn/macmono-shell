import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var inputValues: ({})
    property var idleMinutes: ({})

    readonly property string genScript: Quickshell.shellDir + "/scripts/hypr/apply-generated.sh"
    readonly property string idleScript: Quickshell.shellDir + "/scripts/hypr/apply-idle.sh"

    function syncInput() { inputDebounce.restart(); }
    function syncIdle() { idleDebounce.restart(); }

    Timer { id: inputDebounce; interval: 150; onTriggered: root.runInput() }
    Timer { id: idleDebounce; interval: 150; onTriggered: root.runIdle() }

    function bool(b) { return b ? "true" : "false"; }
    function csv(list) {
        if (!list || list.length === 0) return "";
        return list.map(x => String(x).trim()).filter(x => x !== "").join(",");
    }
    // withKb=false is used for the live preview: keyboard layouts are never previewed,
    // a bad layout would leave the keyboard unusable until the next reload.
    function buildInputLua(v, withKb) {
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
            "        },"
        ];
        const kb = [["kb_layout", csv(v.kbLayouts)], ["kb_variant", csv(v.kbVariants)], ["kb_options", csv(v.kbOptions)]];
        for (let i = 0; i < kb.length && withKb; i++)
            if (kb[i][1] !== "") lines.push("        " + kb[i][0] + " = " + JSON.stringify(kb[i][1]) + ",");
        lines.push("    },", "})", "");
        return lines.join("\n");
    }

    function notify(msg) {
        Quickshell.execDetached(["notify-send", "-a", "macmono", "-u", "normal", "Settings", msg]);
    }

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
        onStarted: { write(root.buildInputLua(root.inputValues, true)); stdinEnabled = false; }
        onExited: (code) => {
            if (code !== 0) root.notify("Input settings were not applied: " + (inputErr.text.trim() || "Hyprland rejected the config.") + " The previous config was restored.");
            if (root.inputPending) { root.inputPending = false; root.runInput(); }
        }
    }

    // Live preview: pushes unsaved Settings values straight to Hyprland with `hyprctl eval`,
    // without touching macmono-generated.lua. Apply still goes through runInput() (file + reload).
    property bool previewActive: false
    property bool previewPending: false
    property var previewVals: ({})
    property double lastPreviewAt: 0

    function previewInput(v) { previewVals = v; previewActive = true; previewDebounce.restart(); }
    // Back to the saved values (cancel / close without Apply).
    function restoreInput() {
        if (!previewActive) return;
        previewActive = false;
        previewVals = inputValues;
        previewDebounce.restart();
    }
    // A Hyprland reload resets runtime values to the file. Put the unsaved preview back,
    // but skip reloads that come right after our own push so it can never loop.
    function reapplyPreview() {
        if (!previewActive || Date.now() - lastPreviewAt < 1500) return;
        previewDebounce.restart();
    }
    // Apply takes over: the saved config is about to be rewritten and reloaded anyway.
    function endPreview() { previewActive = false; previewDebounce.stop(); }

    Timer { id: previewDebounce; interval: 60; onTriggered: root.runPreview() }

    function runPreview() {
        if (previewProc.running) { previewPending = true; return; }
        lastPreviewAt = Date.now();
        previewProc.command = ["hyprctl", "eval", buildInputLua(previewVals, false).replace(/\n/g, " ")];
        previewProc.running = true;
    }
    Process {
        id: previewProc
        onExited: if (root.previewPending) { root.previewPending = false; root.runPreview(); }
    }

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
