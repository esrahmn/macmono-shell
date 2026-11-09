import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Privacy indicators (mic / camera / screen recording / screencast).
//  - mic & screencast = reaktif dari Pipewire (tanpa Process)
//  - camera & external recorder = dicek lewat fuser + pidof, TAPI hanya selama ada alasan:
//    ada window yang bisa membuka kamera, atau indikatornya sedang menyala. Kalau tidak,
//    timer berhenti dan tidak ada proses yang di-spawn sama sekali.
Scope {
    id: root

    // Kamera tidak bisa dibikin reaktif seperti mic: satu-satunya cara tahu kamera dipakai
    // adalah memeriksa devicenya (fuser /dev/video*). Karena itu dulu dicek terus-menerus,
    // termasuk saat lu cuma duduk di desktop. Sekarang cek hanya jalan kalau ada alasan —
    // lihat shouldPoll di bawah.
    property int activePollMs: 2000       // jeda antar-cek selama timer hidup; diisi Sys dari Settings
    property bool cameraPossible: false   // diisi Sys: ada window yang bisa membuka kamera

    // ---- mic (reactive, no Process) ----
    readonly property bool micInUse: Pipewire.nodes.values.some(n => {
        if (!n.isStream || n.isSink || !n.audio) return false;
        const app = String(n.properties?.["application.name"] ?? n.properties?.["node.name"] ?? n.name ?? "").toLowerCase();
        return !/easyeffects|pavucontrol|cava|quickshell|pipewire|wireplumber/.test(app);
    })

    // ---- screencast via xdg-desktop-portal (reactive) ----
    readonly property bool screencast: Pipewire.nodes.values.some(n => {
        const p = n.properties ?? {};
        const mc = String(p["media.class"] ?? "");
        const who = (String(n.name ?? "") + " " + String(p["application.name"] ?? "") + " " + String(p["node.name"] ?? "")).toLowerCase();
        return mc === "Video/Source" && /xdp|portal|screencast/.test(who);
    })

    // ---- camera & external recorders (polled, tapi lebih hemat) ----
    property bool camInUse: false
    property bool recordingProc: false

    Process {
        id: checkProc
        command: ["sh", "-c",
            "c=0; for d in /dev/video*; do [ -e \"$d\" ] || continue; fuser -s \"$d\" 2>/dev/null && { c=1; break; }; done; " +
            "r=0; pidof wf-recorder gpu-screen-recorder wl-screenrec >/dev/null 2>&1 && r=1; echo \"$c $r\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                if (f.length >= 2) {
                    root.camInUse = f[0] === "1";
                    root.recordingProc = f[1] === "1";
                }
            }
        }
    }

    // Timer hanya hidup kalau ada yang perlu dicek:
    //  - cameraPossible: ada window yang biasanya membuka kamera (browser, meeting, OBS...), atau
    //  - camInUse / recordingProc: indikator sedang menyala, jadi harus tetap dicek supaya bisa padam.
    // Di luar itu timer berhenti: tidak ada `sh`, `fuser`, atau `pidof` yang dijalankan saat idle.
    // Konsekuensi yang perlu diketahui: app kamera yang namanya tidak ada di pola
    // Sys.camWindowOpen tidak akan pernah terdeteksi. Kalau lu pakai app aneh, tambahkan
    // namanya di daftar pola itu.
    readonly property bool shouldPoll: cameraPossible || camInUse || recordingProc
    Timer {
        interval: root.activePollMs
        running: root.shouldPoll
        repeat: true
        onTriggered: if (!checkProc.running) checkProc.running = true
    }

    // Satu cek saat startup: kalau kamera sudah dipakai sebelum shell jalan, indikator
    // langsung benar tanpa menunggu window berkamera dibuka.
    Component.onCompleted: checkProc.running = true
}
