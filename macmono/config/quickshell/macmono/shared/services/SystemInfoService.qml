import QtQuick
import Quickshell
import Quickshell.Io

// Info sistem untuk halaman About di Pengaturan.
//
// Quickshell TIDAK punya singleton `SystemInfo` (yang ada cuma `SystemClock` —
// lihat daftar tipe modul Quickshell core), jadi datanya dibaca langsung dari OS:
//   /etc/os-release  -> nama OS       (PRETTY_NAME, fallback NAME)
//   uname -r         -> versi kernel
//   uname -m         -> arsitektur
//   /proc/uptime     -> uptime (detik) saat dibaca
//
// Keempat proses jalan sekali saat shell start, lalu berhenti. Uptime tidak di-poll:
// nilainya dihitung dari selisih jam terhadap `bootStamp`, jadi tetap akurat tanpa proses
// tambahan (dan tanpa timer yang bangun tiap detik).
Scope {
    id: root

    property string osName: "Linux"
    property string kernelVersion: ""
    property string architecture: ""

    // Uptime (detik) sebagai FUNGSI, bukan property: property di QML menghitung sekali
    // lalu menyimpan hasilnya, jadi angka uptime akan membeku. Dipanggil ulang tiap 30 detik
    // oleh baris About.
    function uptimeSeconds() {
        return boot > 0 ? boot + Math.max(0, (Date.now() - bootStamp) / 1000) : 0;
    }

    property real boot: 0        // uptime (detik) saat /proc/uptime dibaca
    property real bootStamp: 0   // Date.now() pada saat yang sama

    // PRETTY_NAME="Arch Linux" -> "Arch Linux"; kalau tak ada, pakai NAME.
    function parseOsRelease(text) {
        let name = "";
        for (const line of String(text).split("\n")) {
            const m = line.match(/^(PRETTY_NAME|NAME)="?(.*?)"?\s*$/);
            if (!m) continue;
            if (m[1] === "PRETTY_NAME") return m[2].trim();
            if (name === "") name = m[2].trim();
        }
        return name !== "" ? name : "Linux";
    }

    Process {
        command: ["cat", "/etc/os-release"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.osName = root.parseOsRelease(text)
        }
    }

    Process {
        command: ["uname", "-r"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.kernelVersion = text.trim() }
    }

    Process {
        command: ["uname", "-m"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.architecture = text.trim() }
    }

    Process {
        command: ["cat", "/proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text);
                if (isFinite(v)) {
                    root.boot = v;
                    root.bootStamp = Date.now();
                }
            }
        }
    }
}
