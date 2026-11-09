import QtQuick
import Quickshell
import Quickshell.Io

// Autostart sesi (XDG autostart). Hyprland sendiri tidak membaca folder autostart, jadi
// hypr/hyprland/scripts/xdg_autostart.sh (dipanggil execs.lua; file user menimpa file sistem), yang membaca
// /etc/xdg/autostart dan ~/.config/autostart.
//
// Sumber kebenaran tetap file .desktop, bukan settings.json:
//   - file user dengan nama sama menimpa file sistem (spesifikasi XDG),
//   - mematikan aplikasi = Hidden=true di file user (pola yang sudah dipakai untuk
//     nm-applet, blueman, dan geoclue-demo-agent di mesin ini).
// Jadi halaman Settings hanya mengedit file yang sama yang dibaca dex — tidak ada
// daftar kedua yang harus dijaga sinkron.
Scope {
    id: root

    property var entries: []
    property bool loading: false
    property string error: ""

    readonly property string userDir: Quickshell.env("HOME") + "/.config/autostart"

    function baseName(p) {
        const s = String(p ?? "");
        const i = s.lastIndexOf("/");
        return i >= 0 ? s.slice(i + 1) : s;
    }

    // Satu baris per file: path <TAB> Name <TAB> Exec <TAB> Hidden <TAB> OnlyShowIn <TAB> NotShowIn
    // (\t dan \n sengaja ditulis sebagai escape literal supaya printf yang mengubahnya.)
    readonly property string listScript:
        "for d in /etc/xdg/autostart \"$HOME/.config/autostart\"; do " +
        "[ -d \"$d\" ] || continue; " +
        "for f in \"$d\"/*.desktop; do " +
        "[ -f \"$f\" ] || continue; " +
        "n=$(sed -n 's/^Name=//p' \"$f\" | head -n 1); " +
        "e=$(sed -n 's/^Exec=//p' \"$f\" | head -n 1); " +
        "h=$(sed -n 's/^Hidden=//p' \"$f\" | head -n 1); " +
        "o=$(sed -n 's/^OnlyShowIn=//p' \"$f\" | head -n 1); " +
        "s=$(sed -n 's/^NotShowIn=//p' \"$f\" | head -n 1); " +
        "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$f\" \"$n\" \"$e\" \"$h\" \"$o\" \"$s\"; " +
        "done; done"

    // Menulis Hidden= ke file user. Kalau file user belum ada, file sistem disalin dulu
    // (itu cara XDG menimpa entri sistem). Hidden lama dihapus supaya tidak menumpuk,
    // dan disisipkan tepat setelah [Desktop Entry] — bukan di akhir file, karena bisa
    // jatuh ke grup lain (mis. [Desktop Action ...]).
    readonly property string writeScript:
        "src=$1; dst=$2; val=$3; " +
        "mkdir -p \"$(dirname \"$dst\")\" || exit 1; " +
        "[ -f \"$dst\" ] || cp \"$src\" \"$dst\" || exit 1; " +
        "awk -v val=\"$val\" '/^Hidden=/ {next} {print} /^\\[Desktop Entry\\]/ {print \"Hidden=\" val}' " +
        "\"$dst\" > \"$dst.tmp\" && mv \"$dst.tmp\" \"$dst\" || exit 1; " +
        "grep -q '^Hidden=' \"$dst\" || printf 'Hidden=%s\\n' \"$val\" >> \"$dst\""

    // Menambah entri: menyalin file .desktop aplikasi ke ~/.config/autostart (cara yang sama dipakai
    // desktop environment lain). Pencarian file mengikuti urutan XDG: user dulu, lalu sistem, lalu Flatpak.
    // Kode field deprecated di Exec (%f %F %u %U %d %D %n %N) dibuang karena tidak ada berkas yang dibuka
    // saat login. Keluar 3 = file .desktop tidak ditemukan (id dari DesktopEntries tanpa file langsung).
    readonly property string addScript:
        "id=$1; case \"$id\" in ''|*/*) exit 1;; esac; " +
        "dst=\"$HOME/.config/autostart/$id.desktop\"; [ -e \"$dst\" ] && exit 0; " +
        "for d in \"$HOME/.local/share/applications\" /usr/local/share/applications /usr/share/applications " +
        "/var/lib/flatpak/exports/share/applications \"$HOME/.local/share/flatpak/exports/share/applications\"; do " +
        "[ -f \"$d/$id.desktop\" ] || continue; " +
        "mkdir -p \"$HOME/.config/autostart\" || exit 1; " +
        "sed -E '/^Exec=/ s/ %[fFuUdDnN]//g' \"$d/$id.desktop\" > \"$dst.tmp\" && mv \"$dst.tmp\" \"$dst\" || exit 1; " +
        "exit 0; done; exit 3"

    // Aturan XDG: OnlyShowIn / NotShowIn dicocokkan dengan XDG_CURRENT_DESKTOP (di sini "Hyprland").
    // Entri khusus KDE/GNOME tidak dijalankan walau tidak di-Hidden, jadi halaman memberi tanda.
    readonly property var desktops: String(Quickshell.env("XDG_CURRENT_DESKTOP") ?? "Hyprland").split(":")
    function shownHere(only, not) {
        const o = String(only ?? "").split(";").filter(x => x !== "");
        const n = String(not ?? "").split(";").filter(x => x !== "");
        if (o.length > 0 && !o.some(x => desktops.includes(x))) return false;
        if (n.some(x => desktops.includes(x))) return false;
        return true;
    }

    function parse(text) {
        const sys = ({});
        const usr = ({});
        for (const line of String(text ?? "").split("\n")) {
            if (line === "") continue;
            const p = line.split("\t");
            if (p.length < 5) continue;
            const path = p[0];
            const item = {
                path: path,
                name: p[1] !== "" ? p[1] : baseName(path).replace(/\.desktop$/, ""),
                exec: p[2],
                // Cuma Hidden=true yang mematikan autostart. NoDisplay hanya menyembunyikan dari menu aplikasi
                // (banyak daemon sistem memakainya tapi tetap jalan), jadi tidak ikut dihitung.
                enabled: p[3].toLowerCase() !== "true",
                relevant: root.shownHere(p[4], p[5])
            };
            if (path.startsWith("/etc/")) sys[baseName(path)] = item;
            else usr[baseName(path)] = item;
        }

        const out = [];
        for (const key in sys) {
            const s = sys[key];
            const u = usr[key];
            out.push({
                name: u ? u.name : s.name,
                exec: u ? u.exec : s.exec,
                enabled: u ? u.enabled : s.enabled,
                relevant: u ? u.relevant : s.relevant,
                userPath: u ? u.path : "",
                systemPath: s.path,
                removable: u !== undefined
            });
        }
        for (const key in usr) {
            if (sys[key]) continue;
            const u = usr[key];
            out.push({ name: u.name, exec: u.exec, enabled: u.enabled, relevant: u.relevant, userPath: u.path, systemPath: "", removable: true });
        }

        out.sort((a, b) => {
            const x = a.name.toLowerCase(), y = b.name.toLowerCase();
            return x < y ? -1 : (x > y ? 1 : 0);
        });
        entries = out;
    }

    function refresh() {
        loading = true;
        error = "";
        scan.running = true;
    }

    function setEnabled(entry, on) {
        if (!entry) return;
        const src = entry.userPath !== "" ? entry.userPath : entry.systemPath;
        if (src === "" || src === undefined) return;
        const dst = root.userDir + "/" + baseName(src);
        error = "";
        mutate.command = ["sh", "-c", writeScript, "sh", src, dst, on ? "false" : "true"];
        mutate.running = true;
    }

    // Tambah aplikasi terpasang (id desktop entry, tanpa ".desktop") ke autostart.
    function addApp(id) {
        if (!id || adder.running) return;
        error = "";
        adder.command = ["sh", "-c", addScript, "sh", String(id)];
        adder.running = true;
    }

    // Menghapus file user: entri kembali ke versi sistem (kalau ada), atau hilang dari daftar.
    function removeUserEntry(entry) {
        if (!entry || entry.userPath === "") return;
        error = "";
        mutate.command = ["sh", "-c", "rm -f \"$1\"", "sh", entry.userPath];
        mutate.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: scan
        command: ["sh", "-c", root.listScript]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
        onExited: root.loading = false
    }

    Process {
        id: mutate
        onExited: (code) => {
            if (code !== 0) root.error = "Couldn't change that entry.";
            root.refresh();
        }
    }

    Process {
        id: adder
        onExited: (code) => {
            if (code === 3) root.error = "Couldn't find that app's launcher file.";
            else if (code !== 0) root.error = "Couldn't add that app.";
            root.refresh();
        }
    }
}
