import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../components"

// Launcher macmono (desain "A · Spotlight"): satu panel kaca di bawah jam.
//  - kolom search kosong -> app Pinned + overview workspace (drag window antar workspace, ala end4)
//  - mulai ngetik        -> hasil per kelompok (Top Hit, Windows, Apps, Actions) + panel preview di kanan
Scope {
    id: root

    readonly property var actions: [
        { id: "clipboard",  name: "Clipboard", sub: "Copy history", kw: "clipboard history paste riwayat salin", glyph: "clipboard" },
        { id: "wallpaper",  name: "Change Wallpaper", sub: "Pick a wallpaper", kw: "wallpaper background image tema", glyph: "image" },
        { id: "random",     name: "Random Wallpaper", sub: "Shuffle wallpaper", kw: "wallpaper random shuffle acak", glyph: "image" },
        { id: "screenshot", name: "Screenshot", sub: "Capture the screen", kw: "screenshot snip capture tangkap layar", glyph: "camera" },
        { id: "update",     name: "System Update", sub: "Update all packages in a terminal", kw: "update upgrade pacman cachyos hello perbarui sistem", glyph: "restart" },
        { id: "lock",       name: "Lock Screen", sub: "Lock the session", kw: "lock kunci", glyph: "lock" },
        { id: "sleep",      name: "Sleep", sub: "Suspend", kw: "sleep suspend tidur", glyph: "sleep" },
        { id: "restart",    name: "Restart", sub: "Reboot the computer", kw: "restart reboot mulai ulang", glyph: "restart" },
        { id: "shutdown",   name: "Shut Down", sub: "Power off", kw: "shutdown poweroff power off matikan", glyph: "power" },
        { id: "logout",     name: "Log Out", sub: "End the session", kw: "logout log out sign out keluar", glyph: "logout" }
    ]

    function runAction(id) {
        switch (id) {
        case "clipboard":  Sys.toggleClipboard(); return;
        case "wallpaper":  Sys.openWallpaper(); return;
        case "random":     Sys.randomWallpaper(); break;
        case "screenshot": Sys.screenshot("copy", true); return;
        case "update":
            Sys.runInTerminal(["sh", "-c",
                "if command -v cachy-update >/dev/null; then cachy-update; " +
                "elif command -v paru >/dev/null; then paru -Syu; " +
                "elif command -v yay >/dev/null; then yay -Syu; else sudo pacman -Syu; fi"], true);
            break;
        case "lock":       Sys.lock(); break;
        case "sleep":      Quickshell.execDetached(["sh", "-c", "systemctl suspend"]); break;
        case "restart":    Quickshell.execDetached(["sh", "-c", "systemctl reboot"]); break;
        case "shutdown":   Quickshell.execDetached(["sh", "-c", "systemctl poweroff"]); break;
        case "logout":     Sys.power("logout"); break;
        }
        Sys.launcherOpen = false;
    }

    // Skor pencarian: makin tinggi makin atas
    function score(text, q) {
        if (!text) return 0;
        const t = String(text).toLowerCase();
        if (t === q) return 100;
        if (t.startsWith(q)) return 80;
        if (t.includes(" " + q) || t.includes("-" + q) || t.includes("." + q)) return 60;
        if (t.includes(q)) return 40;
        return 0;
    }

    function iconFor(name) {
        const p = Quickshell.iconPath(name || "", true);
        return p.length > 0 ? p : Quickshell.iconPath("application-x-executable");
    }

    function compute(query) {
        const q = query.trim().toLowerCase();
        const out = [];
        if (q === "") return out;

        // kalkulator: cuma angka dan operator
        if (/^[0-9+\-*\/().%^\s]+$/.test(q) && /[0-9]/.test(q) && /[+\-*\/%^]/.test(q)) {
            try {
                const v = eval(q.replace(/\^/g, "**"));
                if (typeof v === "number" && isFinite(v))
                    out.push({ kind: "calc", name: String(Math.round(v * 1e10) / 1e10), sub: q + " =", glyph: "calc", tag: "Copy" });
            } catch (e) {}
        }

        const scored = [];
        // window yang lagi kebuka
        for (const c of Sys.hyprClients) {
            if (!c.mapped || (c.workspace?.id ?? 0) <= 0) continue;
            const s = Math.max(score(c.title, q) * 0.9, score(c.class, q));
            if (s > 0) {
                const e = DesktopEntries.heuristicLookup(c.class);
                scored.push({ s: s + 8, item: {
                    kind: "window", address: c.address, name: c.title || c.class,
                    sub: (e?.name || c.class) + " · Workspace " + c.workspace.id,
                    icon: e?.icon || c.class.toLowerCase(), tag: "Window" } });
            }
        }
        // aksi sistem
        for (const a of actions) {
            const s = Math.max(score(a.name, q), score(a.kw, q) * 0.7);
            if (s > 0) scored.push({ s: s + 4, item: { kind: "action", id: a.id, name: a.name, sub: a.sub, glyph: a.glyph, tag: "Action" } });
        }
        // aplikasi
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            let kw = "";
            try { kw = e.keywords ? Array.from(e.keywords).join(" ") : ""; } catch (err) {}
            const s = Math.max(score(e.name, q), score(e.genericName, q) * 0.6, score(kw, q) * 0.4, score(e.comment, q) * 0.3);
            if (s > 0) scored.push({ s: s, item: { kind: "app", entry: e, name: e.name, sub: e.genericName || e.comment || "", icon: e.icon, tag: e.runInTerminal ? "Terminal" : "" } });
        }
        scored.sort((a, b) => (b.s - a.s) || a.item.name.localeCompare(b.item.name));
        const ranked = scored.slice(0, 40).map(r => r.item);

        // Kelompokkan: Top Hit (hasil terbaik, atau hasil kalkulator) lalu Windows, Apps, Actions.
        // Urutan di dalam kelompok tetap sesuai skor; ListView memakai field "group" sebagai judul bagian.
        const top = out.length > 0 ? out.shift() : ranked.shift();
        const grouped = [];
        if (top) grouped.push(Object.assign({}, top, { group: "Top Hit" }));
        const names = { window: "Windows", app: "Apps", action: "Actions", calc: "Calculator" };
        let appCount = 0;
        for (const k of ["calc", "window", "app", "action"])
            for (const it of out.concat(ranked)) {
                if (it.kind !== k) continue;
                if (k === "app" && ++appCount > Settings.launcherMaxResults) continue;  // batas cuma buat daftar app
                grouped.push(Object.assign({}, it, { group: names[k] }));
            }
        return grouped;
    }

    // jalankan app (app terminal dibuka di kitty, karena execute() Quickshell nggak membuka terminal)
    function launchEntry(e) {
        if (!e) return;
        if (e.runInTerminal) Sys.runInTerminal(e.command, false);
        else e.execute();
        Sys.launcherOpen = false;
    }

    // app Pinned (Settings.pinnedApps): id .desktop dulu, kalau nggak ada coba tebak dari nama
    // Dihitung dari DesktopEntries.applications (bukan byId) supaya ikut diperbarui begitu daftar app selesai dimuat.
    readonly property var pinned: {
        const apps = DesktopEntries.applications.values;
        const out = [], seen = ({});
        for (const raw of Settings.pinnedApps) {
            const id = String(raw).toLowerCase();
            const e = apps.find(a => String(a.id).toLowerCase() === id)
                   ?? apps.find(a => String(a.id).toLowerCase().endsWith("." + id))
                   ?? apps.find(a => String(a.name).toLowerCase() === id)
                   ?? null;
            if (e && !seen[e.id]) { seen[e.id] = true; out.push(e); }
        }
        return out;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            // Buka & tutup: animasi di QML (components/Reveal.qml), laci dari bawah bar seperti control center.
            // Animasi layer Hyprland dimatiin (no_anim).
            readonly property bool shown: Sys.launcherOpen && Sys.launcherScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            // window mulai di tepi bawah bar: panel keluar dari balik bar (bagian di atasnya terpotong)
            margins { top: Theme.barMargin + Theme.barHeight }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property var results: []
            property int current: 0
            readonly property bool searching: input.text.trim() !== ""
            readonly property var sel: results[current] ?? null
            readonly property var selToplevel: (sel && sel.kind === "window")
                ? (Hyprland.toplevels.values.find(t => "0x" + t.address === sel.address)?.wayland ?? null) : null

            function refresh() {
                results = compute(input.text);
                current = 0;
            }
            function activate(i) {
                const r = results[i];
                if (!r) return;
                if (r.kind === "app") {
                    root.launchEntry(r.entry);
                } else if (r.kind === "window") {
                    Sys.closeAndDispatch("hl.dsp.focus({ window = \"address:" + r.address + "\" })");
                } else if (r.kind === "action") {
                    runAction(r.id);
                } else if (r.kind === "calc") {
                    Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", r.name]);
                    Sys.launcherOpen = false;
                }
            }
            // window terpilih -> pindahkan ke workspace yang sedang aktif (ikut fokus ke sana)
            function moveHere(addr) {
                const ws = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
                Sys.closeAndDispatch("hl.dsp.window.move({ workspace = " + ws + ", follow = true, window = \"address:" + addr + "\" })");
            }
            function closeWindow(addr) {
                Hyprland.dispatch("hl.dsp.window.close({ window = \"address:" + addr + "\" })");
                Sys.refreshHypr();
            }

            onShownChanged: {
                if (!shown) return;
                input.text = "";
                refresh();
                input.forceActiveFocus();
            }
            Connections {
                target: Sys
                function onCapturingChanged() { if (!Sys.capturing && win.shown) input.forceActiveFocus(); }
                function onHyprClientsChanged() { if (win.shown && win.searching) win.refresh(); }
            }

    
            MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: Sys.launcherOpen = false }

            // ================= panel =================
            Rectangle {
                id: panel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.drawerGap
                width: Math.max(1000, ovv.implicitWidth + 32)
                height: col.implicitHeight + 32
                radius: Theme.radiusXl
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                // laci: panel keluar dari tepi bawah bar; isi di-fade lewat opacity di dalamnya
                transform: Translate { y: -(panel.height + Theme.drawerGap) * (1 - win.anim) }

                MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }   // klik di panel jangan nutup

                Column {
                    id: col
                    x: 16; y: 16
                    width: panel.width - 32
                    spacing: Theme.space16
                    opacity: win.anim

                    // ---------- kolom search ----------
                    Rectangle {
                        width: col.width
                        height: 62
                        radius: Theme.radiusLarge
                        color: Theme.tileFaint

                        Glyph {
                            id: searchIcon
                            anchors { left: parent.left; leftMargin: Theme.space18; verticalCenter: parent.verticalCenter }
                            width: 22; height: 22
                            name: "search"
                            color: win.searching ? Theme.text : Theme.dim
                        }
                        TextInput {
                            id: input
                            anchors { left: searchIcon.right; leftMargin: Theme.space12; right: hintChip.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                            color: Theme.text
                            selectionColor: Theme.text
                            selectedTextColor: Theme.inverseText
                            font.family: Theme.font
                            font.pixelSize: Theme.fontDisplaySm
                            clip: true
                            focus: true
                            onTextChanged: win.refresh()

                            Keys.onPressed: (e) => {
                                const n = win.results.length;
                                if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))
                                    || ((e.modifiers & Qt.ControlModifier) && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                                    if (n > 0) win.current = (win.current + 1) % n;
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab
                                    || ((e.modifiers & Qt.ControlModifier) && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                                    if (n > 0) win.current = (win.current - 1 + n) % n;
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    win.activate(win.current);
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Escape) {
                                    if (input.text !== "") input.text = "";
                                    else Sys.launcherOpen = false;
                                    e.accepted = true;
                                }
                            }

                            Text {
                                visible: input.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search apps, windows, actions, or calculate…"
                                color: Theme.faint
                                font: input.font
                            }
                        }
                        Rectangle {
                            id: hintChip
                            anchors { right: parent.right; rightMargin: Theme.space14; verticalCenter: parent.verticalCenter }
                            width: hintText.implicitWidth + 16
                            height: 24
                            radius: Theme.radiusXs
                            color: Theme.tile
                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: win.searching ? (win.results.length + (win.results.length === 1 ? " result" : " results")) : "Esc"
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                            }
                        }
                    }

                    // ---------- idle: Pinned + Workspaces ----------
                    Column {
                        visible: !win.searching
                        width: col.width
                        spacing: Theme.space14

                        Column {
                            visible: root.pinned.length > 0
                            width: parent.width
                            spacing: Theme.space8
                            SectionLabel { text: "PINNED" }
                            Row {
                                id: pinRow
                                width: parent.width
                                spacing: Theme.space8
                                readonly property real cell: (width - 7 * spacing) / 8
                                Repeater {
                                    model: root.pinned.slice(0, 8)
                                    delegate: MouseArea {
                                        id: pin
                                        required property var modelData
                                        width: pinRow.cell
                                        height: 108
                                        hoverEnabled: true
                                        onClicked: root.launchEntry(pin.modelData)
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radius
                                            color: pin.containsMouse ? Theme.tile : Theme.transparent
                                        }
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: Theme.space8
                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 64; height: 64; radius: Theme.radius
                                                color: Theme.tileFaint
                                                border.width: Theme.borderThin; border.color: Theme.line
                                                Image {
                                                    anchors.centerIn: parent
                                                    width: 42; height: 42
                                                    source: root.iconFor(pin.modelData.icon)
                                                    sourceSize.width: 84; sourceSize.height: 84
                                                    fillMode: Image.PreserveAspectFit
                                                    asynchronous: true
                                                    layer.enabled: true
                                                    layer.effect: MultiEffect { saturation: -1.0; contrast: 0.08 }
                                                }
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: pinRow.cell - 6
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: pin.modelData.name
                                                color: Theme.textSoft
                                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.space8
                            Item {
                                width: parent.width; height: 16
                                SectionLabel { text: "WORKSPACES" }
                                Text {
                                    anchors.right: parent.right
                                    text: "Click to switch · drag a window to move it"
                                    color: Theme.faint
                                    font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                }
                            }
                            Overview {
                                id: ovv
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Theme.transparent
                                border.width: Theme.borderNone
                                screenInfo: win.modelData
                                live: win.shown && !win.searching
                                onActivated: (cmd) => Sys.closeAndDispatch(cmd)
                            }
                        }
                    }

                    // ---------- mencari: hasil per kelompok + panel preview ----------
                    Row {
                        visible: win.searching
                        width: col.width
                        spacing: Theme.space12

                        Item {
                            id: resultsBox
                            width: col.width - preview.width - 12
                            height: Math.max(list.height, 120)

                            Text {
                                visible: win.results.length === 0
                                anchors.centerIn: parent
                                text: "No matches"
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                            }

                            ListView {
                                id: list
                                width: parent.width
                                height: Math.min(contentHeight, 560)
                                clip: true
                                model: win.results
                                currentIndex: win.current
                                reuseItems: true
                                boundsBehavior: Flickable.StopAtBounds
                                highlightMoveDuration: 0
                                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)


                                // judul kelompok (TOP HIT / WINDOWS / APPS / ACTIONS) ditaruh di atas baris pertama tiap kelompok
                                delegate: Column {
                                    id: rowWrap
                                    required property var modelData
                                    required property int index
                                    readonly property bool showHead: index === 0 || win.results[index - 1]?.group !== modelData.group
                                    width: list.width

                                    Item {
                                        visible: rowWrap.showHead
                                        width: parent.width
                                        height: visible ? 28 : 0
                                        SectionLabel {
                                            anchors { left: parent.left; leftMargin: Theme.space10; bottom: parent.bottom; bottomMargin: Theme.space6 }
                                            text: String(rowWrap.modelData.group || "").toUpperCase()
                                        }
                                    }

                                Rectangle {
                                    id: row
                                    readonly property var modelData: rowWrap.modelData
                                    readonly property int index: rowWrap.index
                                    readonly property bool sel: index === win.current
                                    readonly property bool isTop: modelData.group === "Top Hit"
                                    width: list.width
                                    height: isTop ? 68 : 56
                                    radius: Theme.radiusCard
                                    color: sel ? Theme.inverse : (rowArea.containsMouse ? Theme.tileFaint : Theme.transparent)
                                    readonly property color fg: sel ? Theme.inverseText : Theme.text
                                    readonly property color fgDim: sel ? Theme.inverseDim : Theme.dim

                                    Item {
                                        id: iconBox
                                        anchors { left: parent.left; leftMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                        width: row.isTop ? 48 : 38; height: width

                                        Image {
                                            visible: row.modelData.kind === "app" || row.modelData.kind === "window"
                                            anchors.fill: parent
                                            source: visible ? root.iconFor(row.modelData.icon) : ""
                                            sourceSize.width: 84
                                            sourceSize.height: 84
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            layer.enabled: visible
                                            layer.effect: MultiEffect { saturation: -1.0; contrast: 0.08 }
                                        }
                                        Rectangle {
                                            visible: row.modelData.kind === "action" || row.modelData.kind === "calc"
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: row.sel ? Theme.inverseTile : Theme.tile
                                            Glyph {
                                                anchors.centerIn: parent
                                                width: 17; height: 17
                                                name: row.modelData.glyph || "action"
                                                color: row.fg
                                            }
                                        }
                                    }

                                    Column {
                                        anchors { left: iconBox.right; leftMargin: Theme.space12; right: tag.left; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                        spacing: Theme.space2
                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: row.modelData.name
                                            color: row.fg
                                            font.family: Theme.font
                                            font.pixelSize: row.modelData.kind === "calc" ? Theme.fontDisplayMd : (row.isTop ? Theme.fontHeadingLg : Theme.fontTitle)
                                            font.weight: row.isTop ? Font.DemiBold : Font.Medium
                                        }
                                        Text {
                                            visible: text !== ""
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: row.modelData.sub
                                            color: row.fgDim
                                            font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                                        }
                                    }

                                    Rectangle {
                                        id: tag
                                        visible: row.sel || row.modelData.tag !== ""
                                        anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                        width: visible ? tagText.implicitWidth + 14 : 0
                                        height: 22
                                        radius: Theme.radiusXs
                                        color: row.sel ? Theme.inverseTile : Theme.tile
                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: row.sel ? "↵ " + (row.modelData.kind === "window" ? "Switch" : row.modelData.kind === "calc" ? "Copy" : "Open") : row.modelData.tag
                                            color: row.fgDim
                                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: win.current = row.index
                                        onClicked: win.activate(row.index)
                                    }
                                }
                                }
                            }
                        }

                        // panel preview hasil terpilih
                        Rectangle {
                            id: preview
                            width: 340
                            height: Math.max(resultsBox.height, prevCol.implicitHeight + 32)
                            radius: Theme.radiusLarge
                            color: Theme.tileFaint
                            visible: win.sel !== null

                            Column {
                                id: prevCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
                                spacing: Theme.space12

                                Rectangle {   // gambar: preview live window / ikon app / ikon aksi
                                    width: parent.width
                                    height: Math.round(width * 10 / 16)
                                    radius: Theme.radiusMedium
                                    color: Theme.inset
                                    border.width: Theme.borderThin; border.color: Theme.line
                                    clip: true

                                    ScreencopyView {
                                        anchors { fill: parent; margins: Theme.space1 }
                                        visible: win.sel?.kind === "window" && hasContent
                                        captureSource: (win.shown && win.searching) ? win.selToplevel : null
                                        live: true
                                    }
                                    Image {
                                        visible: win.sel?.kind === "app" || (win.sel?.kind === "window" && !win.selToplevel)
                                        anchors.centerIn: parent
                                        width: 64; height: 64
                                        source: visible ? root.iconFor(win.sel?.icon) : ""
                                        sourceSize.width: 128; sourceSize.height: 128
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        layer.enabled: visible
                                        layer.effect: MultiEffect { saturation: -1.0; contrast: 0.08 }
                                    }
                                    Glyph {
                                        visible: win.sel?.kind === "action"
                                        anchors.centerIn: parent
                                        width: 40; height: 40
                                        name: win.sel?.glyph || "action"
                                        color: Theme.text
                                    }
                                    Text {
                                        visible: win.sel?.kind === "calc"
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: win.sel?.name ?? ""
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontDisplay; font.weight: Font.DemiBold
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: Theme.space3
                                    Text {
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        text: win.sel?.name ?? ""
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontLead; font.weight: Font.DemiBold
                                    }
                                    Text {
                                        visible: text !== ""
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        text: win.sel?.kind === "app" ? (win.sel.entry?.comment || win.sel.sub || "") : (win.sel?.sub ?? "")
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                                    }
                                }

                                // tombol aksi sesuai jenis hasil
                                Column {
                                    width: parent.width
                                    spacing: Theme.space6
                                    Repeater {
                                        model: {
                                            const s = win.sel;
                                            if (!s) return [];
                                            if (s.kind === "window") return [
                                                { label: "Switch to window", run: () => win.activate(win.current) },
                                                { label: "Move here", run: () => win.moveHere(s.address) },
                                                { label: "Close window", run: () => win.closeWindow(s.address) }
                                            ];
                                            if (s.kind === "app") {
                                                const out = [{ label: "Open", run: () => win.activate(win.current) }];
                                                const acts = s.entry?.actions ?? [];
                                                for (let i = 0; i < acts.length && out.length < 4; i++) {
                                                    const a = acts[i];
                                                    out.push({ label: a.name, run: () => { a.execute(); Sys.launcherOpen = false; } });
                                                }
                                                return out;
                                            }
                                            if (s.kind === "calc") return [{ label: "Copy result", run: () => win.activate(win.current) }];
                                            return [{ label: "Run", run: () => win.activate(win.current) }];
                                        }
                                        delegate: MouseArea {
                                            id: pb
                                            required property var modelData
                                            required property int index
                                            width: prevCol.width
                                            height: 40
                                            hoverEnabled: true
                                            onClicked: pb.modelData.run()
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: Theme.radiusMedium
                                                color: pb.containsMouse ? Theme.tileHover : (pb.index === 0 ? Theme.tileMid : Theme.tileFaint)
                                            }
                                            Text {
                                                anchors { left: parent.left; leftMargin: Theme.space12; right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                                elide: Text.ElideRight
                                                text: pb.modelData.label
                                                color: Theme.text
                                                font.family: Theme.font; font.pixelSize: Theme.fontSubtitle
                                                font.weight: pb.index === 0 ? Font.DemiBold : Font.Normal
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------- petunjuk keyboard ----------
                    Rectangle { width: col.width; height: 1; color: Theme.line }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.space18
                        Repeater {
                            model: win.searching ? ["↑↓  Navigate", "↵  Open", "Esc  Clear"]
                                                 : ["Type to search", "Super+V  Clipboard", "Esc  Close"]
                            delegate: Text {
                                required property string modelData
                                text: modelData
                                color: Theme.faint
                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                            }
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        color: Theme.faint
        font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }
}
