pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
// SETTINGSSTORE macmono
// Menyimpan override Settings ke ~/.config/macmono/settings.json.
// Jika file/folder belum ada, storage disiapkan otomatis saat startup.
// ============================================================================

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/macmono"
    readonly property string path: dir + "/settings.json"

    // FileView baru diaktifkan setelah direktori dan file tersedia.
    property bool storageReady: false

    // Nilai override. Nilai yang tidak ada memakai fallback dari Settings.qml.
    property var data: ({})

    function v(key, fallback) {
        const value = data[key];
        return value === undefined ? fallback : value;
    }

    // sets = { key: value }, removes = [key]
    function apply(sets, removes) {
        const next = Object.assign({}, data);
        for (const key in sets) next[key] = sets[key];
        for (const key of removes) delete next[key];
        data = next;
        saveTimer.restart();
    }

    property string lastWritten: ""

    function write() {
        if (!storageReady) return;

        const contents = JSON.stringify(data, null, 2) + "\n";
        lastWritten = contents;

        // Direktori sudah dibuat oleh prepareStorage.
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' \"$3\" > \"$2.tmp\" && mv \"$2.tmp\" \"$2\"",
            "sh", dir, path, contents
        ]);
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.write()
    }

    // Buat direktori dan file hanya jika belum ada.
    // File yang sudah ada tidak pernah ditimpa saat startup.
    Process {
        id: prepareStorage
        command: [
            "sh", "-c",
            "mkdir -p \"$1\" && if [ ! -e \"$2\" ]; then printf '{}\\n' > \"$2\"; fi",
            "sh", root.dir, root.path
        ]
        running: true

        onExited: (code) => {
            if (code === 0) {
                root.storageReady = true;
            } else {
                console.warn("[SettingsStore] Gagal menyiapkan direktori settings (exit", code, ")");
            }
        }
    }

    function parse(contents) {
        if (contents === lastWritten) return;

        try {
            const parsed = JSON.parse(contents);
            if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
                data = parsed;
            } else {
                console.warn("[SettingsStore] settings.json harus berupa objek JSON; nilai bawaan dipakai.");
            }
        } catch (error) {
            console.warn("[SettingsStore] settings.json tidak valid; nilai bawaan dipakai:", error);
        }
    }

    FileView {
        id: settingsFile
        path: root.storageReady ? root.path : ""
        watchChanges: true

        onLoaded: root.parse(text())
        onFileChanged: reload()
        onLoadFailed: (error) => {
            console.warn("[SettingsStore] Gagal membaca settings.json:", error);
        }
    }
}
