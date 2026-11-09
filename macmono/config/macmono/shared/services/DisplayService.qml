import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property int confirmSeconds: 15
    readonly property string script: Quickshell.shellDir + "/scripts/hypr/apply-generated.sh"
    readonly property var scalePresets: [1, 1.1, 1.25, 1.5, 1.6, 1.75, 2, 2.25, 2.5, 3]

    property var monitors: []
    property var draft: ({})
    property string error: ""
    property bool busy: false
    property int confirmLeft: 0
    readonly property bool dirty: Object.keys(draft).length > 0

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }
    Process {
        id: readProc
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.monitors = Array.isArray(d) ? d : [];
                } catch (e) { root.monitors = []; }
            }
        }
    }

    function modesOf(m) {
        const out = [];
        for (const s of (m.availableModes || [])) {
            const x = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s);
            if (x) out.push({ res: x[1] + "x" + x[2], w: +x[1], h: +x[2], rate: x[3] });
        }
        return out;
    }
    function resList(m) {
        const seen = {}, out = [];
        for (const e of modesOf(m)) if (!seen[e.res]) { seen[e.res] = true; out.push(e.res); }
        return out;
    }
    function rateList(m, res) {
        return modesOf(m).filter(e => e.res === res).map(e => e.rate);
    }
    function validScales(m, res) {
        const p = String(res).split("x"), w = +p[0], h = +p[1];
        const swap = (m.transform % 2) === 1;
        const ww = swap ? h : w, hh = swap ? w : h;
        return root.scalePresets.filter(s => {
            const a = ww / s, b = hh / s;
            return Math.abs(a - Math.round(a)) < 1e-6 && Math.abs(b - Math.round(b)) < 1e-6;
        });
    }

    function current(m) {
        return { res: m.width + "x" + m.height, rate: Number(m.refreshRate).toFixed(2), scale: Number(m.scale), transform: m.transform };
    }
    function value(m) { return draft[m.name] ?? current(m); }
    function setField(m, field, v) {
        const d = Object.assign({}, draft);
        const cur = Object.assign({}, value(m));
        cur[field] = v;
        if (field === "res") {
            const rates = rateList(m, v);
            if (rates.indexOf(cur.rate) < 0) cur.rate = rates[0];
        }
        const ok = validScales(m, cur.res);
        if (ok.indexOf(cur.scale) < 0) cur.scale = ok.length ? ok[0] : 1;
        const base = current(m);
        if (cur.res === base.res && cur.rate === base.rate && cur.scale === base.scale && cur.transform === base.transform)
            delete d[m.name];
        else d[m.name] = cur;
        draft = d;
    }
    function reset() { draft = ({}); error = ""; }

    function logicalWidth(v) {
        const w = +String(v.res).split("x")[0], h = +String(v.res).split("x")[1];
        return Math.round(((v.transform % 2) === 1 ? h : w) / v.scale);
    }
    function buildLua() {
        const list = monitors.slice().sort((a, b) => a.x - b.x);
        let x = list.length ? list[0].x : 0;
        const lines = [];
        for (const m of list) {
            const v = value(m);
            lines.push("hl.monitor({ output = \"" + m.name + "\", mode = \"" + v.res + "@" + v.rate + "\", position = \""
                + x + "x" + m.y + "\", scale = " + v.scale + ", transform = " + v.transform + " })");
            x += logicalWidth(v);
        }
        return lines.join("\n") + "\n";
    }

    function apply() {
        if (busy || !dirty) return;
        error = "";
        busy = true;
        applyProc.stdinEnabled = true;
        applyProc.command = ["bash", script, "--section", "monitors", "apply", String(confirmSeconds)];
        applyProc.running = true;
    }
    Process {
        id: applyProc
        stdinEnabled: true
        stderr: StdioCollector { id: applyErr }
        onStarted: { write(root.buildLua()); stdinEnabled = false; }
        onExited: (code) => {
            root.busy = false;
            if (code === 0) {
                root.confirmLeft = root.confirmSeconds;
                tick.restart();
            } else {
                root.error = applyErr.text.trim() || "Hyprland rejected the config. Nothing was changed.";
                root.draft = ({});
            }
            root.refresh();
        }
    }

    function keep() {
        tick.stop(); confirmLeft = 0;
        Quickshell.execDetached(["bash", script, "confirm"]);
        draft = ({});
    }
    function revert() {
        tick.stop(); confirmLeft = 0; draft = ({});
        Quickshell.execDetached(["bash", script, "restore"]);
        refreshLater.restart();
    }
    Timer { id: refreshLater; interval: 1500; onTriggered: root.refresh() }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            root.confirmLeft -= 1;
            if (root.confirmLeft <= 0) {
                tick.stop();
                root.draft = ({});
                refreshLater.restart();
            }
        }
    }
}
