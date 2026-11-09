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
        const kb = [["kb_layout", csv(v.kbLayouts)], ["kb_variant", csv(v.kbVariants)], ["kb_options", csv(v.kbOptions)]];
        for (let i = 0; i < kb.length; i++)
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
        onStarted: { write(root.buildInputLua()); stdinEnabled = false; }
        onExited: (code) => {
            if (code !== 0) root.notify("Input settings were not applied: " + (inputErr.text.trim() || "Hyprland rejected the config.") + " The previous config was restored.");
            if (root.inputPending) { root.inputPending = false; root.runInput(); }
        }
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
