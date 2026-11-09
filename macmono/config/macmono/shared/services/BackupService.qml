import QtQuick
import Quickshell
import Quickshell.Io

// Backup & Reset untuk halaman Settings.
//
// Yang disalin: settings.json (semua override Settings) dan
// hypr/custom/macmono-generated.lua (blok monitors + input). Dua file ini yang
// menentukan tampilan dan input, jadi membackup salah satunya saja tidak cukup.
//
// Backup disimpan sebagai folder bertanggal di ~/.local/state/macmono/backups/,
// bukan satu file arsip: tidak butuh tar/zip, gampang diperiksa dengan `ls`, dan
// memulihkan satu file tertentu jadi mungkin tanpa membongkar apa pun.
//
// Restore settings.json langsung terbaca karena SettingsStore memakai
// FileView watchChanges; config Hyprland diterapkan dengan `hyprctl reload`.
Scope {
    id: root

    property var backups: []
    property bool busy: false
    property string status: ""
    property string lastAction: ""   // "create" | "restore" | "reset" | "remove" | "clear": aksi yang menghasilkan `status` (halaman menampilkannya di zona aksi itu)
    // Dipancarkan setelah settings.json kembali ke default: halaman Settings memakainya untuk menulis ulang
    // config Hyprland (input) dan hypridle, supaya yang dipakai sistem sama dengan yang ditampilkan halaman.
    signal resetApplied()

    readonly property string settingsPath: Quickshell.env("HOME") + "/.config/macmono/settings.json"
    readonly property string generatedPath: Quickshell.env("HOME") + "/.config/hypr/custom/macmono-generated.lua"
    readonly property string backupDir: Quickshell.env("HOME") + "/.local/state/macmono/backups"

    property string pending: ""

    function pretty(stamp) {
        // Akhiran "-N" cuma muncul kalau dua backup lahir di detik yang sama (jaring pengaman Restore/Reset).
        const m = /^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})(?:-\d+)?$/.exec(String(stamp));
        if (!m) return String(stamp);
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return Number(m[3]) + " " + months[Number(m[2]) - 1] + " " + m[1] + ", " + m[4] + ":" + m[5];
    }

    function refresh() {
        listProc.running = true;
    }

    function run(args, action) {
        if (busy) return;
        busy = true;
        status = "";
        lastAction = "";
        pending = action;
        mutateProc.command = args;
        mutateProc.running = true;
    }

    function createBackup() {
        run(["sh", "-c",
            "ts=$(date +%Y%m%d-%H%M%S); d=\"$1/$ts\"; " +
            "mkdir -p \"$d\" || exit 1; " +
            "{ [ -f \"$2\" ] && cp \"$2\" \"$d/settings.json\"; } || :; " +
            "{ [ -f \"$3\" ] && cp \"$3\" \"$d/macmono-generated.lua\"; } || :; " +
            "exit 0",
            "sh", backupDir, settingsPath, generatedPath], "create");
    }

    // Jaring pengaman: sebelum apa pun ditimpa, keadaan sekarang disalin ke backup bertanggal.
    // Kalau salah pilih backup, Restore yang keliru itu masih bisa dibatalkan.
    function restore(entry) {
        if (!entry) return;
        run(["sh", "-c",
            "d=\"$1\"; [ -d \"$d\" ] || exit 1; " +
            "ts=$(date +%Y%m%d-%H%M%S); b=\"$4/$ts\"; i=1; " +
            "while [ -d \"$b\" ]; do b=\"$4/$ts-$i\"; i=$((i+1)); done; " +   // jangan menimpa backup yang lahir di detik yang sama
            "mkdir -p \"$b\" || exit 1; " +
            "{ [ -f \"$2\" ] && cp \"$2\" \"$b/settings.json\"; } || :; " +
            "{ [ -f \"$3\" ] && cp \"$3\" \"$b/macmono-generated.lua\"; } || :; " +
            "{ [ -f \"$d/settings.json\" ] && cp \"$d/settings.json\" \"$2\"; } || :; " +
            "{ [ -f \"$d/macmono-generated.lua\" ] && cp \"$d/macmono-generated.lua\" \"$3\"; } || :; " +
            "hyprctl reload >/dev/null 2>&1 || :; " +
            "exit 0",
            "sh", entry.dir, settingsPath, generatedPath, backupDir], "restore");
    }

    // Menulis ulang settings.json sebagai objek kosong: semua nilai kembali ke default di Settings.qml.
    // Keadaan sekarang dibackup dulu (sama seperti Restore), jadi Reset tetap bisa dibatalkan.
    // File generated TIDAK dikosongkan di sini; halaman Settings menulis ulang nilainya lewat
    // Sys.hyprSync (sinyal resetApplied) setelah file settings terbaca lagi.
    function resetSettings() {
        run(["sh", "-c",
            "ts=$(date +%Y%m%d-%H%M%S); b=\"$2/$ts\"; i=1; " +
            "while [ -d \"$b\" ]; do b=\"$2/$ts-$i\"; i=$((i+1)); done; " +
            "mkdir -p \"$b\" || exit 1; " +
            "{ [ -f \"$1\" ] && cp \"$1\" \"$b/settings.json\"; } || :; " +
            "{ [ -f \"$3\" ] && cp \"$3\" \"$b/macmono-generated.lua\"; } || :; " +
            "printf '{}\\n' > \"$1\"",
            "sh", settingsPath, backupDir, generatedPath], "reset");
    }

    // Hapus satu backup. Nama folder harus berupa stamp (angka dan "-" saja), jadi tidak mungkin
    // menunjuk ke luar backupDir lewat "/" atau "..".
    function remove(entry) {
        if (!entry) return;
        run(["sh", "-c",
            "case \"$2\" in \"\"|*[!0-9-]*) exit 1;; esac; " +
            "[ -d \"$1/$2\" ] && rm -rf -- \"$1/$2\"; " +
            "exit 0",
            "sh", backupDir, entry.stamp], "remove");
    }

    // Hapus semua backup. Hanya folder ber-stamp yang dihapus; apa pun selain itu di backupDir dibiarkan.
    function clearAll() {
        run(["sh", "-c",
            "d=\"$1\"; [ -d \"$d\" ] || exit 0; " +
            "for f in \"$d\"/*; do [ -d \"$f\" ] || continue; " +
            "case \"$(basename \"$f\")\" in \"\"|*[!0-9-]*) continue;; esac; " +
            "rm -rf -- \"$f\"; done; exit 0",
            "sh", backupDir], "clear");
    }

    function parseList(text) {
        const out = [];
        for (const line of String(text ?? "").split("\n")) {
            const stamp = line.trim();
            if (stamp === "") continue;
            out.push({ stamp: stamp, dir: backupDir + "/" + stamp, label: pretty(stamp) });
        }
        backups = out;
    }

    Component.onCompleted: refresh()

    Process {
        id: listProc
        command: ["sh", "-c",
            "d=\"$1\"; [ -d \"$d\" ] || exit 0; " +
            "for f in \"$d\"/*; do [ -d \"$f\" ] || continue; printf '%s\\n' \"$(basename \"$f\")\"; done | sort -r",
            "sh", backupDir]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
    }

    Process {
        id: mutateProc
        onExited: (code) => {
            const action = root.pending;
            root.pending = "";
            root.busy = false;
            root.lastAction = action;

            if (code !== 0) {
                root.status = "Failed (exit " + code + ").";
                return;
            }
            if (action === "create") {
                root.status = "Backup created.";
                root.refresh();
            } else if (action === "restore") {
                root.status = "Backup restored.";
                root.refresh();   // backup jaring pengaman yang baru dibuat ikut tampil di daftar
            } else if (action === "reset") {
                root.status = "Settings reset to defaults.";
                root.refresh();
                root.resetApplied();
            } else if (action === "remove") {
                root.status = "Backup deleted.";
                root.refresh();
            } else if (action === "clear") {
                root.status = "All backups deleted.";
                root.refresh();
            }
        }
    }
}
