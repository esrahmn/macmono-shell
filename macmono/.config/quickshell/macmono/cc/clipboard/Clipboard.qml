import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../core"
import "../ui"

// Riwayat clipboard (cliphist) dengan dua panel: daftar di kiri, preview di kanan.
//  ↑↓ / Ctrl+J/K  pilih      ↵  salin & tutup      Shift+Del  hapus item      Esc  tutup
Scope {
    id: root

    property var entries: []      // { line, id, preview, type: "text"|"link"|"image", meta }
    property bool loading: false

    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            if (!line.trim()) continue;
            const tab = line.indexOf("\t");
            if (tab < 0) continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const bin = preview.match(/^\[\[\s*binary data\s+(.+?)\s*\]\]$/);
            if (bin) {
                // contoh: "123 KiB png 800x600"
                const p = bin[1].split(/\s+/);
                const fmt = (p[2] || "").toUpperCase();
                const dim = (p[3] || "").replace("x", " × ");
                out.push({ line: line, id: id, preview: "Gambar " + fmt, type: "image",
                           meta: [fmt, dim, p[0] + " " + (p[1] || "")].filter(x => x.trim()).join(" · "),
                           ext: (p[2] || "png").toLowerCase() });
            } else {
                const isLink = /^(https?:\/\/|www\.)\S+$/.test(preview.trim());
                out.push({ line: line, id: id, preview: preview, type: isLink ? "link" : "text",
                           meta: isLink ? "Link" : "Teks" });
            }
            if (out.length >= Settings.clipboardMaxItems) break;
        }
        return out;
    }

    function reload() {
        loading = true;
        listProc.running = false;
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text);
                root.loading = false;
            }
        }
        onExited: (code) => { if (code !== 0) { root.entries = []; root.loading = false; } }
    }

    Connections {
        target: Sys
        function onClipboardOpenChanged() {
            if (Sys.clipboardOpen) root.reload();
            else Quickshell.execDetached(["rm", "-rf", "--", Sys.runtimeDir + "/clip"]);   // gambar hasil decode jangan ditinggal
        }
        function onClipboardUpdated() { if (Sys.clipboardOpen) root.reload(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.clipboardOpen && Sys.clipboardScreen === modelData.name
            property real anim: 0
            NumberAnimation { id: openAnim; target: win; property: "anim"; from: 0; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }

            // Buka: animasi di QML. Tutup: langsung hilang (bersih, tanpa sisa blur),
            // sama seperti overview end4. Animasi layer Hyprland dimatiin lewat no_anim.
            visible: shown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // ---------------- filter & pilihan ----------------
            readonly property var filtered: {
                const q = search.text.trim().toLowerCase();
                if (!q) return root.entries;
                return root.entries.filter(e => e.preview.toLowerCase().includes(q) || e.meta.toLowerCase().includes(q));
            }
            property int current: 0
            readonly property var sel: filtered[current] ?? null
            onFilteredChanged: current = Math.min(current, Math.max(0, filtered.length - 1))

            // isi lengkap item terpilih (teks utuh / path gambar)
            property string detailText: ""
            property string detailImage: ""
            property string detailFor: ""
            onSelChanged: detailTimer.restart()
            Timer {
                id: detailTimer
                interval: 70
                onTriggered: {
                    const e = win.sel;
                    if (!e) { win.detailText = ""; win.detailImage = ""; win.detailFor = ""; return; }
                    if (e.line === win.detailFor) return;
                    win.detailFor = e.line;
                    win.detailText = "";
                    win.detailImage = "";
                    if (e.type === "image") {
                        imgProc.exec(["bash", "-c",
                            "umask 077; d=\"$4\"; mkdir -p \"$d\"; f=\"$d/$2.$3\"; " +
                            "[ -s \"$f\" ] || printf '%s' \"$1\" | cliphist decode > \"$f\"; printf '%s' \"$f\"",
                            "bash", e.line, e.id, e.ext, Sys.runtimeDir + "/clip"]);
                    } else {
                        textProc.exec(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | head -c 20000", "bash", e.line]);
                    }
                }
            }
            Process { id: textProc; stdout: StdioCollector { onStreamFinished: win.detailText = text } }
            Process { id: imgProc; stdout: StdioCollector { onStreamFinished: win.detailImage = text.trim() } }

            function copySelected() {
                const e = sel;
                if (!e) return;
                Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "bash", e.line]);
                Sys.clipboardOpen = false;
            }
            function deleteSelected() {
                const e = sel;
                if (!e) return;
                Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist delete", "bash", e.line]);
                root.entries = root.entries.filter(x => x.line !== e.line);
            }

            onShownChanged: {
                if (!shown) { openAnim.stop(); anim = 0; return; }
                openAnim.restart();
                {
                    search.text = "";
                    current = 0;
                    detailFor = "";
                    search.forceActiveFocus();
                }
            }

            MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: Sys.clipboardOpen = false }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barMargin + Theme.barHeight + 10 - 10 * (1 - win.anim)
                width: Math.min(860, parent.width - 40)
                height: Math.min(500, parent.height - y - 40)
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                opacity: Theme.openFromModal + (1 - Theme.openFromModal) * win.anim
                scale: 0.96 + 0.04 * win.anim
                transformOrigin: Item.Top

                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    opacity: win.anim

                    // ================= header =================
                    Item {
                        id: header
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: 62

                        Row {
                            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                            spacing: Theme.space10
                            Glyph { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; name: "clipboard"; color: Theme.text }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Clipboard"
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontHeading; font.weight: Font.DemiBold
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.loading ? "memuat…" : (win.filtered.length + " item")
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                            }
                        }

                        Rectangle { // kolom cari
                            anchors { right: parent.right; rightMargin: Theme.space14; verticalCenter: parent.verticalCenter }
                            width: 300
                            height: 36
                            radius: Math.min(width, height) / 2
                            color: Theme.tile
                            border.width: search.activeFocus ? 1 : 0
                            border.color: Theme.faint

                            Glyph {
                                id: sIcon
                                anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                width: 15; height: 15
                                name: "search"
                                color: Theme.dim
                            }
                            TextInput {
                                id: search
                                anchors { left: sIcon.right; leftMargin: Theme.space8; right: parent.right; rightMargin: Theme.space14; verticalCenter: parent.verticalCenter }
                                color: Theme.text
                                selectionColor: Theme.text
                                selectedTextColor: Theme.inverseText
                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                                clip: true
                                focus: true

                                Keys.onPressed: (e) => {
                                    const n = win.filtered.length;
                                    const ctrl = e.modifiers & Qt.ControlModifier;
                                    if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                                        if (n > 0) win.current = Math.min(win.current + 1, n - 1); e.accepted = true;
                                    } else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                                        win.current = Math.max(win.current - 1, 0); e.accepted = true;
                                    } else if (e.key === Qt.Key_PageDown) {
                                        win.current = Math.min(win.current + 8, Math.max(0, n - 1)); e.accepted = true;
                                    } else if (e.key === Qt.Key_PageUp) {
                                        win.current = Math.max(win.current - 8, 0); e.accepted = true;
                                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                        win.copySelected(); e.accepted = true;
                                    } else if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) {
                                        win.deleteSelected(); e.accepted = true;
                                    } else if (e.key === Qt.Key_Escape) {
                                        if (search.text !== "") search.text = "";
                                        else Sys.clipboardOpen = false;
                                        e.accepted = true;
                                    }
                                }

                                Text {
                                    visible: search.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search clipboard"
                                    color: Theme.faint
                                    font: search.font
                                }
                            }
                        }
                    }

                    Rectangle { // garis bawah header
                        id: headerLine
                        anchors { left: parent.left; right: parent.right; top: header.bottom }
                        height: 1
                        color: Theme.line
                    }

                    // ================= footer =================
                    Item {
                        id: footer
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 40

                        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.line }

                        Row {
                            anchors { left: parent.left; leftMargin: Theme.space18; verticalCenter: parent.verticalCenter }
                            spacing: Theme.space16
                            Repeater {
                                model: [["↑↓", "pilih"], ["↵", "salin"], ["⇧ Del", "hapus"], ["esc", "tutup"]]
                                delegate: Row {
                                    required property var modelData
                                    spacing: Theme.space6
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: k.implicitWidth + 10; height: 20; radius: Theme.radiusKey
                                        color: Theme.tile
                                        Text { id: k; anchors.centerIn: parent; text: modelData[0]; color: Theme.dim; font.family: Theme.font; font.pixelSize: Theme.fontCaption }
                                    }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.faint; font.family: Theme.font; font.pixelSize: Theme.fontSmall }
                                }
                            }
                        }
                    }

                    // ================= daftar (kiri) =================
                    ListView {
                        id: list
                        anchors { left: parent.left; top: headerLine.bottom; bottom: footer.top; margins: Theme.space8 }
                        width: 330
                        clip: true
                        spacing: Theme.space2
                        model: win.filtered
                        currentIndex: win.current
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === win.current
                            width: list.width
                            height: 54
                            radius: Theme.radiusMedium
                            color: sel ? Theme.inverse : (rowArea.containsMouse ? Theme.tileFaint : Theme.transparent)
                            readonly property color fg: sel ? Theme.inverseText : Theme.text
                            readonly property color fgDim: sel ? Theme.inverseDim : Theme.dim

                            Rectangle {
                                id: typeIcon
                                anchors { left: parent.left; leftMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                width: 32; height: 32; radius: Theme.radiusXs
                                color: row.sel ? Theme.inverseTile : Theme.tile
                                Glyph {
                                    anchors.centerIn: parent
                                    width: 16; height: 16
                                    name: row.modelData.type === "image" ? "image" : (row.modelData.type === "link" ? "link" : "text")
                                    color: row.fg
                                }
                            }
                            Column {
                                anchors { left: typeIcon.right; leftMargin: Theme.space12; right: trash.left; rightMargin: Theme.space6; verticalCenter: parent.verticalCenter }
                                spacing: Theme.space2
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    text: row.modelData.preview.replace(/\s+/g, " ")
                                    textFormat: Text.PlainText
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.Medium
                                }
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: row.modelData.meta
                                    color: row.fgDim
                                    font.family: Theme.font; font.pixelSize: Theme.fontCaption
                                }
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: win.current = row.index
                                onDoubleClicked: { win.current = row.index; win.copySelected(); }
                            }
                            MouseArea { // tombol hapus pas hover
                                id: trash
                                visible: rowArea.containsMouse || containsMouse
                                anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                width: 26; height: 26
                                hoverEnabled: true
                                onClicked: { win.current = row.index; win.deleteSelected(); }
                                Rectangle { anchors.fill: parent; radius: Theme.radiusXs; color: parent.containsMouse ? (row.sel ? Theme.inverseTile : Theme.tileHover) : Theme.transparent }
                                Glyph { anchors.centerIn: parent; width: 14; height: 14; name: "trash"; color: row.fgDim }
                            }
                        }
                    }

                    Text { // kalau kosong
                        visible: !root.loading && win.filtered.length === 0
                        anchors.centerIn: list
                        horizontalAlignment: Text.AlignHCenter
                        text: root.entries.length === 0 ? "Clipboard is empty" : "No matches"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                    }

                    Rectangle { // pemisah vertikal
                        id: vline
                        anchors { left: list.right; leftMargin: Theme.space8; top: headerLine.bottom; bottom: footer.top }
                        width: 1
                        color: Theme.line
                    }

                    // ================= preview (kanan) =================
                    Item {
                        anchors { left: vline.right; right: parent.right; top: headerLine.bottom; bottom: footer.top; margins: Theme.space18 }

                        // info + tombol salin
                        Item {
                            id: paneHead
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 30
                            visible: win.sel !== null

                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: win.sel ? (win.sel.meta + (win.sel.type !== "image" && win.detailText ? " · " + win.detailText.length + " karakter" : "")) : ""
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                            }
                            Rectangle {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                width: copyRow.implicitWidth + 22
                                height: 28
                                radius: Math.min(width, height) / 2
                                color: copyArea.containsMouse ? Theme.inverseHover : Theme.inverse
                                Row {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: Theme.space6
                                    Glyph { anchors.verticalCenter: parent.verticalCenter; width: 13; height: 13; name: "clipboard"; color: Theme.inverseText }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Salin"; color: Theme.inverseText; font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold }
                                }
                                MouseArea { id: copyArea; anchors.fill: parent; hoverEnabled: true; onClicked: win.copySelected() }
                            }
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: paneHead.bottom; topMargin: Theme.space12; bottom: parent.bottom }
                            radius: Theme.radiusCard
                            color: Theme.inset
                            border.width: Theme.borderThin
                            border.color: Theme.line
                            clip: true
                            visible: win.sel !== null

                            // teks
                            Flickable {
                                id: textFlick
                                visible: win.sel?.type !== "image"
                                anchors { fill: parent; margins: Theme.space14 }
                                contentHeight: body.paintedHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                TextEdit {
                                    id: body
                                    width: textFlick.width
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.WrapAnywhere
                                    textFormat: TextEdit.PlainText
                                    text: win.detailText || (win.sel?.preview ?? "")
                                    color: Theme.text
                                    selectionColor: Theme.text
                                    selectedTextColor: Theme.inverseText
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontBody
                                }
                            }

                            // gambar
                            Image {
                                visible: win.sel?.type === "image"
                                anchors { fill: parent; margins: Theme.space10 }
                                source: visible && win.detailImage !== "" ? "file://" + win.detailImage : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                smooth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
