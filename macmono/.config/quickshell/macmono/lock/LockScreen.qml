pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../core"

// Lock screen native Quickshell (ext-session-lock lewat WlSessionLock).
// Shell sudah hidup -> wallpaper, font, Mpris, UPower semua sudah ke-load,
// jadi pas Sys.locked = true surface langsung tampil tanpa spawn proses baru.
// State password dipakai bareng semua monitor.
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property bool failed: false
    property int attempts: 0
    property bool capsLock: false
    property string fullName: ""

    signal shake()
    signal refocus()

    function reset() {
        password = "";
        busy = false;
        failed = false;
    }

    function submit() {
        if (busy || password === "") return;
        busy = true;
        failed = false;
        pam.start();
    }

    function checkCaps() {
        if (!capsProc.running) capsProc.running = true;
    }

    Connections {
        target: Sys
        function onLockedChanged() {
            if (!Sys.locked) return;
            root.reset();
            root.attempts = 0;
            root.checkCaps();
        }
        function onLockRefocus() { root.refocus(); }
    }

    PamContext {
        id: pam
        onPamMessage: {
            if (pam.responseRequired) pam.respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.reset();
                Sys.locked = false;
                return;
            }
            root.password = "";
            root.failed = true;
            root.attempts++;
            root.shake();
        }
    }

    // PAM bisa menggantung (modul pam lambat, home NFS mati, dsb). Tanpa timeout,
    // busy tetap true sehingga input terkunci tanpa jalan keluar. Batalkan saja;
    // abort() memicu completed(PamResult.Error) yang sudah menangani reset.
    Timer {
        interval: 10000
        running: root.busy
        onTriggered: {
            pam.abort();
            root.busy = false;
        }
    }

    // password yang diketik lalu ditinggal -> hapus otomatis
    Timer {
        interval: 30000
        running: Sys.locked && root.password !== "" && !root.busy
        onTriggered: root.password = ""
    }

    Process {
        id: capsProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards ?? [];
                    const main = kbs.find(k => k.main) ?? kbs[0];
                    root.capsLock = main ? !!main.capsLock : false;
                } catch (e) {
                    root.capsLock = false;
                }
            }
        }
    }

    // nama lengkap dari GECOS, dibaca sekali saat shell start (bukan saat lock)
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: root.fullName = text.trim() || (Quickshell.env("USER") ?? "")
        }
    }

    WlSessionLock {
        locked: Sys.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.canvas

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
