import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    property var entries: []
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
                const p = bin[1].split(/\s+/);
                const fmt = (p[2] || "").toUpperCase();
                const dim = (p[3] || "").replace("x", " × ");
                out.push({ line: line, id: id, preview: "Image " + fmt, type: "image",
                           meta: [fmt, dim, p[0] + " " + (p[1] || "")].filter(x => x.trim()).join(" · "),
                           ext: (p[2] || "png").toLowerCase() });
            } else {
                const isLink = /^(https?:\/\/|www\.)\S+$/.test(preview.trim());
                out.push({ line: line, id: id, preview: preview, type: isLink ? "link" : "text",
                           meta: isLink ? "Link" : "Text" });
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
            else Quickshell.execDetached(["rm", "-rf", "--", Sys.runtimeDir + "/clip"]);
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
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property bool present: reveal.present

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var filtered: {
                const q = search.text.trim().toLowerCase();
                if (!q) return root.entries;
                return root.entries.filter(e => e.preview.toLowerCase().includes(q) || e.meta.toLowerCase().includes(q));
            }
            property int current: 0
            readonly property var sel: filtered[current] ?? null
            onFilteredChanged: current = Math.min(current, Math.max(0, filtered.length - 1))

            property string detailText: ""
            property string detailImage: ""
            property string detailFor: ""
            onSelChanged: detailTimer.restart()
            Timer {
                id: detailTimer
                interval: Settings.clipboardDetailDebounceMs
                onTriggered: {
                    const e = win.sel;
                    if (!e) { win.detailText = ""; win.detailImage = ""; win.detailFor = ""; return; }
                    if (e.line === win.detailFor) return;
                    win.detailFor = e.line;
                    win.detailText = "";
                    win.detailImage = "";
                    if (e.type === "image") {
                        imgProc.exec(["bash", "-c",
                                     "umask 077; d=\"$2\"; mkdir -p \"$d\"; f=\"$d/$3.$4\"; " +
                                     "[ -s \"$f\" ] || printf '%s' \"$1\" | cliphist decode > \"$f\"; printf '%s' \"$f\"",
                                     "bash", e.line, Sys.runtimeDir + "/clip", e.id, e.ext]);
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

            function clearAll() {
                if (root.entries.length === 0) return;
                Quickshell.execDetached(["cliphist", "wipe"]);
                root.entries = [];
                current = 0;
                detailText = "";
                detailImage = "";
                detailFor = "";
                search.text = "";
            }

            onShownChanged: {
                if (!shown) return;
                {
                    search.text = "";
                    current = 0;
                    detailFor = "";
                    search.forceActiveFocus();
                }
            }

            MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: Sys.clipboardOpen = false }

            Rectangle {
                id: panel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.drawerGap
                width: Math.min(1120, parent.width - 32)
                height: Math.min(720, parent.height - y - 32)
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                transform: Translate { y: -(panel.height + Theme.drawerGap) * (1 - win.anim) }

                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    opacity: win.anim

                    Item {
                        id: header
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: Theme.clipHeaderHeight

                        Row {
                            anchors { left: parent.left; leftMargin: Theme.space18; verticalCenter: parent.verticalCenter }
                            spacing: Theme.space10
                            Glyph { anchors.verticalCenter: parent.verticalCenter; width: Theme.icon18; height: Theme.icon18; name: "clipboard"; color: Theme.text }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Clipboard"
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.panelTitleSize; font.weight: Font.DemiBold; font.letterSpacing: Theme.panelTitleTracking
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.loading ? "Loading…" : (win.filtered.length + (win.filtered.length === 1 ? " item" : " items"))
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                            }
                        }

                        Rectangle {
                            id: clearAllButton
                            anchors { right: searchBox.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                            width: clearLabel.implicitWidth + 34
                            height: Theme.clipClearHeight
                            radius: Math.min(width, height) / 2
                            color: clearArea.containsMouse ? Theme.tileHover : Theme.tile
                            opacity: root.entries.length > 0 ? 1 : 0.45
                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.space6
                                Glyph {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.icon13; height: Theme.icon13
                                    name: "trash"
                                    color: Theme.dim
                                }
                                Text {
                                    id: clearLabel
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Clear All"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.DemiBold
                                }
                            }
                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.entries.length > 0
                                onClicked: win.clearAll()
                            }
                        }

                        Rectangle {
                            id: searchBox
                            anchors { right: parent.right; rightMargin: Theme.space14; verticalCenter: parent.verticalCenter }
                            width: Theme.clipSearchWidth
                            height: Theme.clipSearchHeight
                            radius: Math.min(width, height) / 2
                            color: Theme.tile
                            border.width: search.activeFocus ? 1 : 0
                            border.color: Theme.faint

                            Glyph {
                                id: sIcon
                                anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                width: Theme.icon15; height: Theme.icon15
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

                    Rectangle {
                        id: headerLine
                        anchors { left: parent.left; right: parent.right; top: header.bottom }
                        height: Theme.borderThin
                        color: Theme.line
                    }


                    ListView {
                        id: list
                        anchors { left: parent.left; top: headerLine.bottom; bottom: parent.bottom; margins: Theme.space8 }
                        width: Theme.clipListWidth
                        clip: true
                        spacing: Theme.space2
                        model: win.filtered
                        currentIndex: win.current
                        reuseItems: true
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === win.current
                            width: list.width
                            height: Theme.clipRowHeight
                            radius: Theme.radiusXs
                            color: Theme.transparent
                            readonly property color fg: Theme.text
                            readonly property color fgDim: Theme.dim

                            SelBar { active: row.sel }

                            Rectangle {
                                id: typeIcon
                                anchors { left: parent.left; leftMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                width: Theme.clipTypeIconSize; height: Theme.clipTypeIconSize; radius: Theme.radiusXs
                                color: Theme.tile
                                Glyph {
                                    anchors.centerIn: parent
                                    width: Theme.icon16; height: Theme.icon16
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
                            MouseArea {
                                id: trash
                                visible: rowArea.containsMouse || containsMouse
                                anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                width: Theme.clipTrashSize; height: Theme.clipTrashSize
                                hoverEnabled: true
                                onClicked: { win.current = row.index; win.deleteSelected(); }
                                Rectangle { anchors.fill: parent; radius: Theme.radiusXs; color: parent.containsMouse ? Theme.tileHover : Theme.transparent }
                                Glyph { anchors.centerIn: parent; width: Theme.icon14; height: Theme.icon14; name: "trash"; color: row.fgDim }
                            }
                        }
                    }

                    Text {
                        visible: !root.loading && win.filtered.length === 0
                        anchors.centerIn: list
                        horizontalAlignment: Text.AlignHCenter
                        text: root.entries.length === 0 ? "Clipboard is empty" : "No matches"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                    }

                    Rectangle {
                        id: vline
                        anchors { left: list.right; leftMargin: Theme.space8; top: headerLine.bottom; bottom: parent.bottom }
                        width: Theme.borderThin
                        color: Theme.line
                    }

                    Item {
                        anchors { left: vline.right; right: parent.right; top: headerLine.bottom; bottom: parent.bottom; margins: Theme.space18 }

                        Item {
                            id: paneHead
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: Theme.clipPaneHeadHeight
                            visible: win.sel !== null

                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: win.sel ? (win.sel.meta + (win.sel.type !== "image" && win.detailText ? " · " + win.detailText.length + " characters" : "")) : ""
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                            }
                            Rectangle {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                width: copyRow.implicitWidth + 22
                                height: Theme.clipPaneChipHeight
                                radius: Math.min(width, height) / 2
                                color: copyArea.containsMouse ? Theme.tileHover : Theme.tile
                                Row {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: Theme.space6
                                    Glyph { anchors.verticalCenter: parent.verticalCenter; width: Theme.icon13; height: Theme.icon13; name: "clipboard"; color: Theme.dim }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Copy"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold }
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

                            Image {
                                visible: win.sel?.type === "image"
                                anchors { fill: parent; margins: Theme.space10 }
                                source: visible && win.detailImage !== "" ? "file://" + win.detailImage : ""
                                sourceSize.width: Math.round(width)
                                sourceSize.height: Math.round(height)
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
