import QtQuick
import Quickshell
import Quickshell.Io

// Equalizer sistem lewat Easy Effects. Sengaja TIDAK memilih "Easy Effects Sink" sebagai output
// default: README Easy Effects menyuruh hardware tetap jadi default; Easy Effects sendiri yang
// menggeser stream aplikasi lewat sink virtualnya.
//
// Hanya bekerja saat dipanggil dari UI (Sys.eq.apply): tidak ada apply otomatis waktu shell start,
// jadi preset Easy Effects milik user tidak tertimpa tiap login.
// Preset ditulis ke ~/.config/easyeffects/output/macmono-eq.json oleh scripts/audio/apply-eq.sh.
Scope {
    id: root

    // 10 band satu oktaf. Q 1.5 + mode "APO (DR)" = bell RBJ biasa, sama dengan rumus grafik di
    // SettingsEqualizer, jadi kurva yang terlihat mendekati yang benar-benar dipakai.
    readonly property var freqs: [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property real q: 1.5

    property string status: ""    // hasil terakhir untuk UI
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
        // Headroom: input diturunkan sebesar boost terbesar supaya tidak clipping.
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

    // Tunggu user selesai menggeser / mengklik beberapa kali.
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
