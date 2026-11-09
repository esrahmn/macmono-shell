import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property var freqs: [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property real q: 1.5

    property string status: ""
    property bool ok: true

    function buildPreset(gains) {
        const bands = ({});
        let boost = 0;
        for (let i = 0; i < freqs.length; i++) {
            const g = Number(gains[i] || 0);
            if (g > boost) boost = g;
            bands["band" + i] = { "frequency": freqs[i], "gain": g, "mode": "APO (DR)", "mute": false,
                                  "q": q, "slope": "x1", "solo": false, "type": "Bell", "width": 4.0 };
        }
        const eq = { "balance": 0.0, "bypass": false, "input-gain": -boost, "left": bands, "mode": "IIR",
                     "num-bands": freqs.length, "output-gain": 0.0, "pitch-left": 0.0, "pitch-right": 0.0,
                     "right": bands, "split-channels": false };
        return JSON.stringify({ "output": { "blocklist": [], "equalizer#0": eq, "plugins_order": ["equalizer#0"] } }, null, 2);
    }

    property bool _wantEnabled: false
    property var _wantGains: []
    property bool _queued: false

    function apply(enabled, gains) {
        _wantEnabled = enabled;
        _wantGains = gains.slice();
        debounce.restart();
    }

    Timer { id: debounce; interval: 450; onTriggered: root._run() }

    function _run() {
        if (proc.running) { _queued = true; return; }
        proc.mode = _wantEnabled ? "enable" : "disable";
        proc.json = _wantEnabled ? buildPreset(_wantGains) : "";
        proc.command = ["bash", Quickshell.shellDir + "/scripts/audio/apply-eq.sh", proc.mode];
        proc.running = true;
    }

    Process {
        id: proc
        property string mode: "disable"
        property string json: ""
        stdinEnabled: true
        stderr: StdioCollector { id: err }
        onStarted: { if (mode === "enable") write(json); stdinEnabled = false; }
        onExited: (code) => {
            stdinEnabled = true;
            root.ok = code === 0;
            if (code === 0) root.status = mode === "enable" ? "Applied to Easy Effects." : "Off. Easy Effects is bypassed.";
            else if (code === 3) root.status = "Easy Effects is not running. Start it, then switch the equalizer on again.";
            else if (code === 4) root.status = "Easy Effects is not installed (pacman -S easyeffects).";
            else root.status = err.text.trim() || "Could not apply the equalizer.";
            if (root._queued) { root._queued = false; root._run(); }
        }
    }
}
