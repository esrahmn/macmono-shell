import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../shared/components"

// Editorial command palette. Search-first, monochrome, one-line rows.
// Open/close motion is exclusively owned by shared/components/Reveal.qml.
Scope {
    id: root

    readonly property var commands: [
        { id: "settings", name: "Open Settings", group: "Settings", category: "Settings", keywords: "preferences configure options", glyph: "sliders" },
        { id: "control-center", name: "Control Center", group: "System", category: "System", keywords: "quick settings wifi bluetooth volume brightness", glyph: "sliders" },
        { id: "clipboard", name: "Clipboard History", group: "System", category: "System", keywords: "copy paste history", glyph: "clipboard" },
        { id: "emoji", name: "Emoji Picker", group: "System", category: "System", keywords: "symbols emoticons", glyph: "action" },
        { id: "wallpaper", name: "Change Wallpaper", group: "System", category: "System", keywords: "background appearance", glyph: "image" },
        { id: "screenshot", name: "Take Screenshot", group: "System", category: "System", keywords: "capture screen snip", glyph: "camera" },
        { id: "lock", name: "Lock Screen", group: "System", category: "System", keywords: "secure session", glyph: "lock" },
        { id: "sleep", name: "Sleep", group: "System", category: "System", keywords: "suspend", glyph: "sleep" },
        { id: "restart", name: "Restart", group: "System", category: "System", keywords: "reboot", glyph: "restart" },
        { id: "shutdown", name: "Shut Down", group: "System", category: "System", keywords: "power off", glyph: "power" },
        { id: "logout", name: "Log Out", group: "System", category: "System", keywords: "sign out end session", glyph: "logout" },
        { id: "overview", name: "Show Overview", group: "Workspace", category: "Workspace", keywords: "windows workspaces", glyph: "grid" },
        { id: "media", name: "Media Controls", group: "Media", category: "Media", keywords: "music player playback", glyph: "music" }
    ]

    function score(value, query) {
        const text = String(value || "").toLowerCase();
        if (!text) return 0;
        if (text === query) return 100;
        if (text.startsWith(query)) return 80;
        if (text.includes(" " + query)) return 60;
        if (text.includes(query)) return 40;
        return 0;
    }

    function buildResults(query, selectedCategory) {
        const q = String(query || "").trim().toLowerCase();
        const category = selectedCategory || "All";
        const out = [];
        if (category === "Apps" || (category === "All" && q.length > 0)) {
            for (const app of DesktopEntries.applications.values) {
                if (app.noDisplay) continue;
                const name = app.name || app.id || "Application";
                const kw = [app.genericName || "", app.comment || "", app.id || ""].join(" ");
                const points = q ? Math.max(score(name, q), score(kw, q) * 0.55) : 0;
                if (!q || points > 0)
                    out.push({ kind: "app", name: name, group: "Applications", category: "Apps", entry: app, points: points });
            }
        }
        if (category !== "Apps") {
            for (const cmd of commands) {
                if (category !== "All" && category !== cmd.category) continue;
                const points = q ? Math.max(score(cmd.name, q), score(cmd.keywords, q) * 0.65) : 0;
                if (!q || points > 0)
                    out.push({ kind: "command", name: cmd.name, group: cmd.group, category: cmd.category, id: cmd.id, glyph: cmd.glyph, points: points });
            }
        }
        const order = { Applications: 0, System: 1, Workspace: 2, Media: 3, Settings: 4 };
        out.sort((a, b) => (order[a.group] - order[b.group]) || (b.points - a.points) || a.name.localeCompare(b.name));
        return out.slice(0, 60);
    }

    function execute(item) {
        if (!item) return;
        if (item.kind === "app") {
            const entry = item.entry;
            if (entry.runInTerminal) Sys.runInTerminal(entry.command, false);
            else Sys.spawn(entry.command, entry.workingDirectory);
            Sys.commandPaletteOpen = false;
            return;
        }
        switch (item.id) {
        case "settings": Sys.toggleSettings(); break;
        case "control-center": Sys.toggleCC(Sys.focusedScreenName()); break;
        case "clipboard": Sys.toggleClipboard(); break;
        case "emoji": Sys.toggleEmoji(); break;
        case "wallpaper": Sys.openWallpaper(); break;
        case "screenshot": Sys.screenshot("copy", true); break;
        case "lock": Sys.lock(); break;
        case "sleep": Sys.power("sleep"); break;
        case "restart": Sys.power("restart"); break;
        case "shutdown": Sys.power("shutdown"); break;
        case "logout": Sys.power("logout"); break;
        case "overview": Sys.toggleLauncher(); break;
        case "media": Sys.toggleMedia(); break;
        }
        Sys.commandPaletteOpen = false;
    }

    readonly property var categories: ["All", "Apps", "System", "Workspace", "Media", "Settings"]

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool shown: Sys.commandPaletteOpen && Sys.commandPaletteScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property bool present: reveal.present
            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:command-palette"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property string category: "All"
            property int currentIndex: 0
            readonly property bool searching: search.text.trim().length > 0
            readonly property var results: searching ? root.buildResults(search.text, category) : []
            readonly property var selected: results[currentIndex] ?? null
            onResultsChanged: currentIndex = Math.min(currentIndex, Math.max(0, results.length - 1))

            MouseArea {
                anchors.fill: parent
                enabled: win.shown
                onClicked: Sys.commandPaletteOpen = false
            }

            Rectangle {
                id: panel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.drawerGap
                width: Math.min(Theme.commandPaletteWidth, parent.width - Theme.space30 * 2)
                height: win.searching
                    ? Math.min(Theme.commandPaletteMaxHeight, Theme.commandPaletteSearchHeight + Theme.commandPaletteCategoryHeight + Theme.borderThin * 2 + Math.max(resultList.contentHeight, Theme.commandPaletteRowHeight + Theme.space12))
                    : Theme.commandPaletteSearchHeight + Theme.borderThin
                transform: Translate { y: -(panel.height + Theme.drawerGap) * (1 - reveal.progress) }
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.lineStrong
                clip: true

                // Search field
                Row {
                    id: searchRow
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Theme.commandPaletteSearchHeight
                    opacity: reveal.progress
                    spacing: Theme.space12
                    anchors.leftMargin: Theme.commandPalettePadding
                    anchors.rightMargin: Theme.commandPalettePadding

                    Glyph { anchors.verticalCenter: parent.verticalCenter; width: Theme.icon22; height: Theme.icon22; name: "search"; color: Theme.dim }
                    TextInput {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: searchRow.width - Theme.icon22 - Theme.space12
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSubtitle
                        selectionColor: Theme.selection
                        selectedTextColor: Theme.text
                        clip: true
                        focus: win.shown
                        activeFocusOnTab: true
                        onTextChanged: win.currentIndex = 0
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) { Sys.commandPaletteOpen = false; event.accepted = true; }
                            else if (event.key === Qt.Key_Down) { win.currentIndex = Math.min(win.currentIndex + 1, win.results.length - 1); event.accepted = true; }
                            else if (event.key === Qt.Key_Up) { win.currentIndex = Math.max(0, win.currentIndex - 1); event.accepted = true; }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.execute(win.selected); event.accepted = true; }
                        }
                        Text {
                            anchors.fill: parent
                            text: "Search commands and applications"
                            color: Theme.muted
                            font: search.font
                            verticalAlignment: Text.AlignVCenter
                            visible: !search.text
                        }
                    }
                }
                Rectangle { anchors.top: searchRow.bottom; width: parent.width; height: Theme.borderThin; color: Theme.line }

                // Category filters — selected state is typographic, not a filled chip.
                Row {
                    id: categoryRow
                    anchors { top: searchRow.bottom; left: parent.left; right: parent.right }
                    height: Theme.commandPaletteCategoryHeight
                    opacity: reveal.progress
                    anchors.leftMargin: Theme.commandPalettePadding
                    spacing: Theme.space18
                    visible: win.searching
                    Repeater {
                        model: root.categories
                        delegate: Item {
                            required property string modelData
                            width: categoryLabel.implicitWidth
                            height: categoryRow.height
                            Text {
                                id: categoryLabel
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: win.category === parent.modelData ? Theme.text : Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontBody
                                font.weight: win.category === parent.modelData ? Font.DemiBold : Font.Normal
                            }
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: Theme.borderStrong
                                color: Theme.text
                                visible: win.category === parent.modelData
                            }
                            MouseArea { anchors.fill: parent; onClicked: { win.category = parent.modelData; win.currentIndex = 0; } }
                        }
                    }
                }
                Rectangle { anchors.top: categoryRow.bottom; width: parent.width; height: Theme.borderThin; color: Theme.line; visible: win.searching }

                ListView {
                    id: resultList
                    anchors { top: categoryRow.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
                    clip: true
                    opacity: reveal.progress
                    visible: win.searching
                    model: win.results
                    currentIndex: win.currentIndex
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Column {
                        id: resultDelegate
                        required property var modelData
                        required property int index
                        width: resultList.width
                        readonly property bool groupStart: index === 0 || modelData.group !== win.results[index - 1].group
                        Text {
                            visible: resultDelegate.groupStart
                            text: resultDelegate.modelData.group.toUpperCase()
                            color: Theme.labelCapsText
                            font.family: Theme.font
                            font.pixelSize: Theme.labelCapsSize
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.labelCapsTracking
                            leftPadding: Theme.commandPalettePadding
                            topPadding: Theme.space12
                            bottomPadding: Theme.space6
                        }
                        Item {
                            // Keep the hover surface inset from the panel edge so its rounded
                            // corners never visually escape the Command Palette container.
                            x: Theme.commandPalettePadding
                            width: parent.width - Theme.commandPalettePadding * 2
                            height: Theme.commandPaletteRowHeight
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusXs
                                color: (rowArea.containsMouse || win.currentIndex === resultDelegate.index) ? Theme.tileHover : Theme.transparent
                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                            }
                            Row {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: Theme.space12
                                anchors.leftMargin: Theme.space8
                                Glyph {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.icon18; height: Theme.icon18
                                    name: resultDelegate.modelData.kind === "app" ? "grid" : (resultDelegate.modelData.glyph || "command")
                                    color: Theme.textSoft
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Theme.commandPalettePadding * 2 - Theme.icon18 - Theme.space12
                                    text: resultDelegate.modelData.name
                                    color: Theme.textSoft
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontHeading
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.currentIndex = resultDelegate.index
                                onClicked: root.execute(resultDelegate.modelData)
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: win.results.length === 0
                        text: "No results"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBodyLg
                    }
                }
            }

            onShownChanged: {
                if (shown) {
                    category = "All";
                    search.text = "";
                    currentIndex = 0;
                    Qt.callLater(() => search.forceActiveFocus());
                }
            }
        }
    }
}
