import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var stateStore: null

    property var searchDirs: []
    property int scanDepth: 2
    property int maxFiles: 500

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
            "find \"$@\" " +
            "-maxdepth " + Math.floor(root.scanDepth) + " -type f -not -path '*/Screenshots/*' " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null " +
            "| awk '!seen[$0]++' | head -" + Math.floor(root.maxFiles),
            "sh"
        ].concat(root.searchDirs.map(d => d.startsWith("~") ? Quickshell.env("HOME") + d.slice(1) : d))
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n").filter(l => l.trim() !== "");
                if (root.pendingRandom) {
                    root.pendingRandom = false;
                    root.randomWallpaper();
                }
                if (root.wallpapers.length > 0) {
                    thumbProc.command = ["sh", Quickshell.shellDir + "/features/wallpaper/scripts/thumbs.sh"].concat(root.wallpapers);
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
