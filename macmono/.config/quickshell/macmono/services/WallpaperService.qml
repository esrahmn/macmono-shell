import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper list, persistence, thumbnails.
// UI memakai Sys.wallpaper* (fasad); logic berat di sini.
Scope {
    id: root

    // Dipasang Sys; lihat services/StateStore.qml
    property var stateStore: null

    property string wallpaper: ""
    property bool wallpaperMono: true
    property var wallpapers: []
    property bool pendingRandom: false
    property var wallpaperReadyScreens: []
    property string wallpaperLoadError: ""

    readonly property bool wallpaperReady: wallpaper !== "" && Quickshell.screens.length > 0
        && Quickshell.screens.every(screen => wallpaperReadyScreens.includes(screen.name))

    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/macmono/thumbs/"
    property int thumbsVersion: 0

    function thumbFor(path) {
        return thumbDir + Qt.md5(path) + ".jpg";
    }

    function markWallpaperReady(path, screenName) {
        if (path !== wallpaper || !screenName || wallpaperReadyScreens.includes(screenName))
            return;
        wallpaperReadyScreens = wallpaperReadyScreens.concat([screenName]);
    }

    function markWallpaperLoadError(path) {
        if (path === wallpaper)
            wallpaperLoadError = path;
    }

    onWallpaperChanged: {
        wallpaperReadyScreens = [];
        wallpaperLoadError = "";
    }

    function saveState(name, value) { if (root.stateStore) root.stateStore.save(name, value); }

    function setWallpaper(path) {
        wallpaper = path;
        saveState("wallpaper", path);
    }

    function setWallpaperMono(v) {
        wallpaperMono = v;
        saveState("wallpaper_mono", v ? "1" : "0");
    }

    function loadWallpapers() {
        if (!wallpaperFind.running)
            wallpaperFind.running = true;
    }

    function randomWallpaper() {
        if (wallpapers.length === 0) {
            pendingRandom = true;
            loadWallpapers();
            return;
        }
        setWallpaper(wallpapers[Math.floor(Math.random() * wallpapers.length)]);
    }

    Process {
        id: wallpaperRead
        command: ["sh", "-c",
            "cat \"$HOME/.local/state/macmono/wallpaper\" 2>/dev/null; echo; " +
            "cat \"$HOME/.local/state/macmono/wallpaper_mono\" 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                if (lines[0] && lines[0].trim())
                    root.wallpaper = lines[0].trim();
                if (lines[1] && lines[1].trim() === "0")
                    root.wallpaperMono = false;
            }
        }
    }

    Process {
        id: wallpaperFind
        command: ["sh", "-c",
            "find \"$HOME/Pictures/Wallpapers\" \"$HOME/Pictures\" \"$HOME/Wallpapers\" " +
            "\"$HOME/.local/share/backgrounds\" /usr/share/backgrounds /usr/share/wallpapers " +
            "-maxdepth 2 -type f -not -path '*/Screenshots/*' " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null " +
            "| awk '!seen[$0]++' | head -120"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n").filter(l => l.trim() !== "");
                if (root.pendingRandom) {
                    root.pendingRandom = false;
                    root.randomWallpaper();
                }
                if (root.wallpapers.length > 0) {
                    thumbProc.command = ["sh", Quickshell.shellDir + "/scripts/thumbs.sh"].concat(root.wallpapers);
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc
        onExited: root.thumbsVersion++
    }

    Component.onCompleted: wallpaperRead.running = true
}
