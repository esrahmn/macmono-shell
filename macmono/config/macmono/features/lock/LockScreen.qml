pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../core"

Scope {
    id: root

    property string password: ""
    property bool busy: false
    property bool failed: false
    property int attempts: 0
    property bool capsLock: false
    // PAM success: play the exit scene first; the session only really opens in finishUnlock().
    property bool unlocking: false
    property string fullName: ""

    signal shake()
    signal refocus()

    function reset() {
        password = "";
        busy = false;
        failed = false;
    }

    function beginUnlock() {
        if (unlocking) return;
        unlocking = true;
        unlockFallback.restart();
    }

    function finishUnlock() {
        if (!unlocking) return;
        unlockFallback.stop();
        unlocking = false;
        reset();
        Sys.locked = false;
    }

    function submit() {
        if (busy || unlocking || password === "") return;
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
            root.unlocking = false;
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
                root.beginUnlock();
                return;
            }
            root.password = "";
            root.failed = true;
            root.attempts++;
            root.shake();
        }
    }

    Timer {
        interval: Settings.lockPamTimeoutMs
        running: root.busy
        onTriggered: {
            pam.abort();
            root.busy = false;
        }
    }

    // Safety net: if the exit scene never finishes, open the session anyway.
    Timer { id: unlockFallback; interval: 1500; onTriggered: root.finishUnlock() }

    Timer {
        interval: Settings.lockClearPasswordMs
        running: Sys.locked && root.password !== "" && !root.busy && !root.unlocking
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
            color: Theme.scrim

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
