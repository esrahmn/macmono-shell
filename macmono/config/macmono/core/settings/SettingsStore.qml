pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io


Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/macmono"
    readonly property string path: dir + "/settings.json"

    property bool storageReady: false

    property var data: ({})

    function v(key, fallback) {
        const value = data[key];
        return value === undefined ? fallback : value;
    }

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
                console.warn("[SettingsStore] Failed to create the settings directory (exit", code, ")");
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
                console.warn("[SettingsStore] settings.json must be a JSON object; using defaults.");
            }
        } catch (error) {
            console.warn("[SettingsStore] settings.json is invalid; using defaults:", error);
        }
    }

    FileView {
        id: settingsFile
        path: root.storageReady ? root.path : ""
        watchChanges: true

        onLoaded: root.parse(text())
        onFileChanged: reload()
        onLoadFailed: (error) => {
            console.warn("[SettingsStore] Failed to read settings.json:", error);
        }
    }
}
