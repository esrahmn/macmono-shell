import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int launcherMenuWidth: 700
    readonly property int launcherMenuRailWidth: 176
    readonly property int launcherMenuSearchHeight: 50
    readonly property int launcherMenuBodyHeight: 430
    readonly property int launcherMenuFootHeight: 50
    readonly property int launcherMenuCapsHeight: 24
    readonly property int launcherMenuGridColumns: 5
    readonly property int launcherMenuCellHeight: 84
    readonly property int launcherMenuDragEdge: 40   // px from the grid edge where drag autoscroll starts
    readonly property int launcherMenuDragStep: 14   // max px per tick (16 ms)
    readonly property int launcherMenuIconBox: 46
    readonly property int launcherMenuIcon: 22
    readonly property int launcherMenuAvatar: 24
    readonly property int launcherCtxWidth: 210
    readonly property int launcherCtxRowHeight: 34

    readonly property var cats: [
        { key: "dev",    label: "Development", match: "Development" },
        { key: "net",    label: "Internet",    match: "Network" },
        { key: "media",  label: "Multimedia",  match: "AudioVideo" },
        { key: "office", label: "Office",      match: "Office" },
        { key: "graph",  label: "Graphics",    match: "Graphics" },
        { key: "system", label: "System",      match: "System" },
        { key: "util",   label: "Utilities",   match: "Utility" },
        { key: "game",   label: "Games",       match: "Game" }
    ]

    readonly property var powerActions: [
        { act: "lock",     label: "Lock",      glyph: "lock",     confirm: false },
        { act: "sleep",    label: "Sleep",     glyph: "sleep",    confirm: false },
        { act: "logout",   label: "Log Out",   glyph: "logout",   confirm: true },
        { act: "restart",  label: "Restart",   glyph: "restart",  confirm: true },
        { act: "shutdown", label: "Shut Down", glyph: "power",    confirm: true }
    ]

    readonly property int recentMax: 8
    signal searchCleared()
    property string current: "fav"
    property string query: ""
    property int sel: -1
    onCurrentChanged: sel = -1
    onQueryChanged: sel = query.trim() !== "" ? 0 : -1
    property var recentIds: []
    property string armed: ""

    readonly property var allApps: {
        const out = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || !e.name) continue;
            out.push(e);
        }
        out.sort((a, b) => a.name.localeCompare(b.name));
        return out;
    }

    function resolvePin(raw) {
        const id = String(raw).toLowerCase();
        const apps = root.allApps;
        return apps.find(a => String(a.id).toLowerCase() === id)
            ?? apps.find(a => String(a.id).toLowerCase().endsWith("." + id))
            ?? apps.find(a => String(a.name).toLowerCase() === id)
            ?? null;
    }

    readonly property var favoriteEntries: {
        const out = [], seen = ({});
        for (const raw of Settings.pinnedApps) {
            const e = root.resolvePin(raw);
            if (e && !seen[e.id]) { seen[e.id] = true; out.push(e); }
        }
        return out;
    }

    function isPinned(entry) {
        return root.favoriteEntries.some(e => e.id === entry.id);
    }

    function setPinned(entry, pinned) {
        const keep = Array.from(Settings.pinnedApps).filter(raw => root.resolvePin(raw)?.id !== entry.id);
        if (pinned) keep.push(entry.id);
        SettingsStore.apply({ pinnedApps: keep }, []);
    }

    // Pins that no longer resolve to an installed app are kept, after the visible ones.
    function reorderPinned(from, to) {
        const n = root.favoriteEntries.length;
        if (from === to || from < 0 || to < 0 || from >= n || to >= n) return;
        const order = root.favoriteEntries.map(e => e.id);
        order.splice(to, 0, order.splice(from, 1)[0]);
        const unresolved = Array.from(Settings.pinnedApps).filter(raw => !root.resolvePin(raw));
        SettingsStore.apply({ pinnedApps: order.concat(unresolved) }, []);
        root.sel = to;
    }

    readonly property var recentEntries: {
        const out = [];
        for (const id of root.recentIds) {
            const e = root.allApps.find(a => a.id === id);
            if (e) out.push(e);
        }
        return out;
    }

    function catOf(entry) {
        let list = [];
        try { list = entry.categories ? Array.from(entry.categories) : []; } catch (e) {}
        const hay = list.join(" ").toLowerCase();
        for (const c of root.cats)
            if (hay.indexOf(c.match.toLowerCase()) >= 0) return c.key;
        return "util";
    }

    readonly property var counts: {
        const m = ({ fav: 0, recent: 0 });
        for (const c of root.cats) m[c.key] = 0;
        for (const e of root.allApps) {
            const k = root.catOf(e);
            m[k] = (m[k] || 0) + 1;
        }
        m.fav = root.favoriteEntries.length;
        m.recent = root.recentEntries.length;
        return m;
    }

    // Categories with no installed apps are not shown at all.
    readonly property var activeCats: root.cats.filter(c => (root.counts[c.key] || 0) > 0)

    // The panel opens on the first non-empty group: pinned first, then recent,
    // then the first populated category.
    function firstCategory() {
        if (root.counts.fav > 0) return "fav";
        if (root.counts.recent > 0) return "recent";
        for (const c of root.activeCats) return c.key;
        return "fav";
    }

    readonly property var shownApps: {
        const q = root.query.trim().toLowerCase();
        if (q !== "") {
            return root.allApps.filter(e => {
                if (String(e.name).toLowerCase().indexOf(q) >= 0) return true;
                if (String(e.id).toLowerCase().indexOf(q) >= 0) return true;
                return String(e.genericName || "").toLowerCase().indexOf(q) >= 0;
            });
        }
        if (root.current === "fav") return root.favoriteEntries;
        if (root.current === "recent") return root.recentEntries;
        return root.allApps.filter(e => root.catOf(e) === root.current);
    }

    readonly property string paneLabel: {
        if (root.query.trim() !== "") return "Search results";
        if (root.current === "fav") return "Favorites";
        if (root.current === "recent") return "Recent";
        for (const c of root.cats)
            if (c.key === root.current) return c.label;
        return "Applications";
    }

    function iconFor(name) {
        const p = Quickshell.iconPath(name || "", true);
        return p.length > 0 ? p : Quickshell.iconPath("application-x-executable");
    }

    readonly property int ctxActionMax: 8

    function noteRecent(entry) {
        const ids = root.recentIds.filter(id => id !== entry.id);
        ids.unshift(entry.id);
        root.recentIds = ids.slice(0, root.recentMax);
    }

    // DesktopAction.execute() ignores runInTerminal, so terminal apps get no actions.
    function ctxItems(entry) {
        const out = [{ kind: "open", label: "Open" }];
        if (!entry.runInTerminal) {
            const n = Math.min(entry.actions.length, root.ctxActionMax);
            for (let i = 0; i < n; i++) {
                const a = entry.actions[i];
                if (a.name) out.push({ kind: "action", label: a.name, action: a });
            }
        }
        if (root.current === "fav" && root.query.trim() === "") {
            const i = root.favoriteEntries.findIndex(e => e.id === entry.id);
            const moves = [];
            if (i > 0) moves.push({ kind: "earlier", label: "Move earlier" });
            if (i >= 0 && i < root.favoriteEntries.length - 1) moves.push({ kind: "later", label: "Move later" });
            if (moves.length > 0) moves[0].sep = true;
            for (const m of moves) out.push(m);
        }
        const pinned = root.isPinned(entry);
        out.push({ kind: pinned ? "unpin" : "pin", label: pinned ? "Unpin from Favorites" : "Pin to Favorites", sep: true });
        return out;
    }

    function runCtx(entry, item) {
        if (item.kind === "open") {
            root.launch(entry);
        } else if (item.kind === "action") {
            root.noteRecent(entry);
            Sys.spawn(item.action.command, entry.workingDirectory);
            Sys.launcherMenuOpen = false;
        } else if (item.kind === "earlier" || item.kind === "later") {
            const i = root.favoriteEntries.findIndex(e => e.id === entry.id);
            root.reorderPinned(i, item.kind === "earlier" ? i - 1 : i + 1);
        } else {
            root.setPinned(entry, item.kind === "pin");
            root.sel = Math.min(root.sel, root.shownApps.length - 1);
        }
    }

    function launch(entry) {
        if (!entry) return;
        root.noteRecent(entry);
        if (entry.runInTerminal) Sys.runInTerminal(entry.command, false);
        else Sys.spawn(entry.command, entry.workingDirectory);
        Sys.launcherMenuOpen = false;
    }

    function pickCategory(key) {
        root.current = key;
        root.searchCleared();
    }

    function requestPower(act, confirm) {
        if (confirm && root.armed !== act) {
            root.armed = act;
            disarm.restart();
            return;
        }
        root.armed = "";
        Sys.power(act);
    }

    Timer {
        id: disarm
        interval: Settings.powerConfirmMs
        onTriggered: root.armed = ""
    }

    component NavRow: Rectangle {
        readonly property int launcherMenuNavHeight: 32
        id: nav
        required property string label
        required property bool active
        signal tapped()

        width: parent.width
        height: launcherMenuNavHeight
        radius: Theme.radiusControl
        color: nav.active ? Theme.tileHover : (navArea.containsMouse ? Theme.tile : Theme.transparent)
        Behavior on color { TweenColor { duration: Theme.durFast } }

        Text {
            anchors { left: parent.left; leftMargin: Theme.space12; right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            text: nav.label
            color: nav.active ? Theme.text : Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontMd
            font.weight: nav.active ? Theme.weightMedium : Theme.weightRegular
        }
        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.tapped()
        }
    }

    component PowerButton: Rectangle {
        readonly property int launcherMenuPowerHeight: 30
        id: pb
        required property string act
        required property string label
        required property string glyph
        required property bool confirm

        readonly property bool hot: root.armed === pb.act

        width: Theme.iconMd + Theme.space8 + Math.max(tmLabel.advanceWidth, tmConfirm.advanceWidth) + Theme.space24
        height: launcherMenuPowerHeight
        radius: Theme.radiusControl
        color: pb.hot ? Theme.tile : (pbArea.containsMouse ? Theme.tile : Theme.transparent)

        TextMetrics { id: tmLabel; text: pb.label; font.family: Theme.font; font.pixelSize: Theme.fontSm }
        TextMetrics { id: tmConfirm; text: "Confirm"; font.family: Theme.font; font.pixelSize: Theme.fontSm }
        Behavior on color { TweenColor { duration: Theme.durFast } }

        Row {
            id: pbRow
            anchors.centerIn: parent
            spacing: Theme.space8
            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconMd; height: Theme.iconMd
                name: pb.glyph
                color: pb.hot ? Theme.text : Theme.dim
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pb.hot ? "Confirm" : pb.label
                color: pb.hot ? Theme.text : Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontSm
            }
        }
        MouseArea {
            id: pbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.requestPower(pb.act, pb.confirm)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.launcherMenuOpen && Sys.launcherMenuScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
            readonly property bool present: reveal.present

            readonly property int bodyHeight: Math.max(root.launcherMenuCellHeight * 3 + Theme.listHeaderHeight,
                Math.min(Math.min(root.launcherMenuBodyHeight, rail.height + Theme.space16 * 2),
                         win.height - Theme.space8 - root.launcherMenuSearchHeight - root.launcherMenuFootHeight
                         - Theme.borderStrong))

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:launcher-menu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (shown && !Sys.capturing) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property bool ctxOpen: false
            property var ctxEntry: null
            property var ctxModel: []
            property int ctxSel: 0
            property real ctxX: 0
            property real ctxY: 0

            property int dragFrom: -1
            property int dragTo: -1
            property real dragDX: 0
            property real dragDY: 0
            property real dragViewX: 0
            property real dragViewY: 0
            property real dragPressY: 0
            readonly property bool reorderable: root.current === "fav" && root.query.trim() === ""

            function resetDrag() {
                win.dragFrom = -1;
                win.dragTo = -1;
                win.dragDX = 0;
                win.dragDY = 0;
                win.dragViewX = 0;
                win.dragViewY = 0;
            }

            function dropIndex(x, y) {
                const cols = root.launcherMenuGridColumns;
                const col = Math.max(0, Math.min(cols - 1, Math.floor(x / appGrid.cellWidth)));
                const row = Math.max(0, Math.floor(y / appGrid.cellHeight));
                return Math.max(0, Math.min(root.shownApps.length - 1, row * cols + col));
            }

            function openCtx(entry, index, px, py) {
                root.sel = index;
                win.ctxEntry = entry;
                win.ctxModel = root.ctxItems(entry);
                win.ctxSel = 0;
                win.ctxX = px;
                win.ctxY = py;
                win.ctxOpen = true;
            }

            function openCtxForSelected() {
                const i = root.sel >= 0 ? root.sel : (root.query.trim() !== "" ? 0 : -1);
                if (i < 0 || i >= root.shownApps.length) return false;
                appGrid.positionViewAtIndex(i, GridView.Contain);
                appGrid.forceLayout();
                const item = appGrid.itemAtIndex(i);
                const p = item ? item.mapToItem(card, item.width / 2, item.height)
                               : Qt.point(card.width / 2, card.height / 2);
                win.openCtx(root.shownApps[i], i, p.x, p.y);
                return true;
            }

            function activateCtx(i) {
                const item = win.ctxModel[i];
                const entry = win.ctxEntry;
                win.ctxOpen = false;
                if (item && entry) root.runCtx(entry, item);
            }

            function handleCtxKey(e) {
                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                const n = win.ctxModel.length;
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_Left) {
                    win.ctxOpen = false;
                } else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                    win.ctxSel = (win.ctxSel + 1) % n;
                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                    win.ctxSel = (win.ctxSel + n - 1) % n;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    win.activateCtx(win.ctxSel);
                } else if (e.text.length > 0 && e.text >= " ") {
                    win.ctxOpen = false;
                    return false;
                }
                e.accepted = true;
                return true;
            }

            Timer {
                interval: 16
                repeat: true
                running: win.dragFrom >= 0
                onTriggered: {
                    const h = appGrid.height, edge = root.launcherMenuDragEdge;
                    let k = 0;
                    if (win.dragViewY < edge) k = -(edge - win.dragViewY) / edge;
                    else if (win.dragViewY > h - edge) k = (win.dragViewY - (h - edge)) / edge;
                    k = Math.max(-1, Math.min(1, k));
                    if (k === 0) return;
                    const maxY = Math.max(0, appGrid.contentHeight - h);
                    const ny = Math.max(0, Math.min(maxY, appGrid.contentY + k * root.launcherMenuDragStep));
                    if (ny === appGrid.contentY) return;
                    appGrid.contentY = ny;
                    const cy = win.dragViewY + ny;
                    win.dragDY = cy - win.dragPressY;
                    win.dragTo = win.dropIndex(win.dragViewX, cy);
                }
            }

            onShownChanged: {
                win.ctxOpen = false;
                win.resetDrag();
                if (!shown) return;
                input.text = "";
                root.query = "";
                root.current = root.firstCategory();
                root.sel = -1;
                root.armed = "";
                keyCatcher.forceActiveFocus();
            }

            // Keyboard navigation: arrows or Ctrl+J/K/N/P move the grid selection,
            // Tab/Shift+Tab switch category (or move the selection while searching), Enter opens.
            function handleKey(e) {
                if (win.ctxOpen && win.handleCtxKey(e)) return true;
                const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
                if (e.key === Qt.Key_Menu || (shift && (e.key === Qt.Key_F10 || e.key === Qt.Key_Return || e.key === Qt.Key_Enter))) {
                    if (win.openCtxForSelected()) {
                        e.accepted = true;
                        return true;
                    }
                }
                const n = root.shownApps.length;
                const cols = root.launcherMenuGridColumns;
                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                const typing = input.activeFocus && input.text !== "";
                let step = 0;
                if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) step = cols;
                else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) step = -cols;
                else if (!typing && e.key === Qt.Key_Right) step = 1;
                else if (!typing && e.key === Qt.Key_Left) step = -1;
                else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                    const dir = e.key === Qt.Key_Tab ? 1 : -1;
                    if (root.query.trim() !== "") step = dir;
                    else {
                        const keys = ["fav", "recent"].filter(k => (root.counts[k] || 0) > 0)
                            .concat(root.activeCats.map(c => c.key));
                        if (keys.length > 0) {
                            const i = keys.indexOf(root.current);
                            root.pickCategory(keys[((i < 0 ? 0 : i) + dir + keys.length) % keys.length]);
                        }
                        e.accepted = true;
                        return true;
                    }
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    const i = root.sel >= 0 ? root.sel : (root.query.trim() !== "" ? 0 : -1);
                    if (i >= 0 && i < n) root.launch(root.shownApps[i]);
                    e.accepted = true;
                    return true;
                } else return false;

                if (n > 0) {
                    let t = root.sel;
                    if (t < 0) t = 0;
                    else if (t + step >= 0 && t + step <= n - 1) t = t + step;
                    else if (step > 0 && Math.floor(t / cols) < Math.floor((n - 1) / cols)) t = n - 1;
                    root.sel = t;
                    appGrid.positionViewAtIndex(t, GridView.Contain);
                }
                e.accepted = true;
                return true;
            }

            Connections {
                target: root
                function onSearchCleared() { input.text = ""; }
                function onCurrentChanged() { win.ctxOpen = false; appGrid.positionViewAtBeginning(); }
                function onQueryChanged() { win.ctxOpen = false; appGrid.positionViewAtBeginning(); }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                enabled: win.shown && !Sys.capturing
                onPressed: Sys.launcherMenuOpen = false
            }

            Item {
                id: body
                anchors { top: parent.top; left: parent.left; topMargin: Theme.drawerGap; leftMargin: Theme.barMargin }
                width: Math.min(root.launcherMenuWidth, win.width - Theme.space16)
                height: card.height
                transform: Translate { y: Theme.drawerOffset(body.height + Theme.drawerGap, win.travel) }

                Rectangle {
                    id: card
                    anchors { top: parent.top; left: parent.left }
                    width: parent.width
                    height: root.launcherMenuSearchHeight + win.bodyHeight + root.launcherMenuFootHeight + Theme.borderStrong
                    radius: Theme.radiusPanel
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    clip: true

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Item {
                        id: keyCatcher
                        focus: true
                        Keys.onPressed: (e) => {
                            if (win.handleKey(e)) return;
                            if (e.key === Qt.Key_Escape) {
                                Sys.launcherMenuOpen = false;
                                e.accepted = true;
                            } else if (e.text.length > 0 && e.text >= " "
                                       && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                                input.forceActiveFocus();
                                input.text += e.text;
                                input.cursorPosition = input.text.length;
                                e.accepted = true;
                            }
                        }
                    }

                    MouseArea {
                        z: 10
                        anchors.fill: parent
                        visible: win.ctxOpen
                        enabled: win.ctxOpen
                        acceptedButtons: Qt.AllButtons
                        onPressed: win.ctxOpen = false
                        onWheel: (w) => { win.ctxOpen = false; w.accepted = false; }
                    }

                    Rectangle {
                        id: ctxMenu
                        z: 11
                        visible: win.ctxOpen
                        width: root.launcherCtxWidth
                        height: ctxCol.implicitHeight + Theme.space8 * 2
                        x: Math.max(Theme.space8, Math.min(card.width - width - Theme.space8, win.ctxX))
                        y: win.ctxY + height > card.height - Theme.space8
                           ? Math.max(Theme.space8, win.ctxY - height) : win.ctxY
                        radius: Theme.radiusCard
                        color: Theme.panel
                        border.width: Theme.borderThin
                        border.color: Theme.line

                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                        Column {
                            id: ctxCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }

                            Repeater {
                                model: win.ctxModel
                                delegate: Item {
                                    id: ci
                                    required property var modelData
                                    required property int index
                                    width: ctxCol.width
                                    height: root.launcherCtxRowHeight + (modelData.sep === true ? Theme.space8 : 0)

                                    Rectangle {
                                        visible: ci.modelData.sep === true
                                        anchors { left: parent.left; right: parent.right; top: parent.top
                                                  leftMargin: Theme.space4; rightMargin: Theme.space4; topMargin: Theme.space2 }
                                        height: Theme.borderThin
                                        color: Theme.line
                                    }

                                    Rectangle {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: root.launcherCtxRowHeight
                                        radius: Theme.radiusControl
                                        color: ci.index === win.ctxSel ? Theme.tileHover : Theme.transparent
                                        Behavior on color { TweenColor { duration: Theme.durFast } }

                                        Text {
                                            anchors { left: parent.left; leftMargin: Theme.space12; right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                            elide: Text.ElideRight
                                            text: ci.modelData.label
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontMd
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: win.ctxSel = ci.index
                                        onClicked: win.activateCtx(ci.index)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: col
                        width: parent.width
                        opacity: win.anim

                        Item {
                            width: col.width
                            height: root.launcherMenuSearchHeight

                            Glyph {
                                id: searchGlyph
                                anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                                width: Theme.iconMd; height: Theme.iconMd
                                name: "search"
                                color: input.text !== "" ? Theme.text : Theme.dim
                            }
                            TextInput {
                                id: input
                                anchors { left: searchGlyph.right; leftMargin: Theme.space12; right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                                color: Theme.text
                                selectionColor: Theme.tileHover
                                selectedTextColor: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontMd
                                clip: true
                                onTextChanged: root.query = text

                                Keys.onPressed: (e) => {
                                    if (win.handleKey(e)) return;
                                    if (e.key === Qt.Key_Escape) {
                                        if (input.text !== "") { input.text = ""; root.query = ""; }
                                        else Sys.launcherMenuOpen = false;
                                        e.accepted = true;
                                    }
                                }

                                Text {
                                    visible: input.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search apps…"
                                    color: Theme.dim
                                    font: input.font
                                }
                            }
                        }

                        Rectangle {
                            width: col.width
                            height: Theme.borderThin
                            color: Theme.line
                        }

                        Item {
                            width: col.width
                            height: win.bodyHeight

                            Flickable {
                                id: railFlick
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: root.launcherMenuRailWidth
                                contentHeight: rail.height
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: rail
                                    x: Theme.space12
                                    y: Theme.space16
                                    width: railFlick.width - Theme.space12 * 2
                                    spacing: Theme.space2

                                    Item {
                                        width: parent.width
                                        height: root.launcherMenuCapsHeight
                                        Text {
                                            anchors { left: parent.left; leftMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space4 }
                                            text: "LIBRARY"
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                                            font.letterSpacing: Theme.trackCaps
                                        }
                                    }

                                    NavRow {
                                        label: "Favorites"
                                        active: root.current === "fav"
                                        onTapped: root.pickCategory("fav")
                                    }
                                    NavRow {
                                        label: "Recent"
                                        active: root.current === "recent"
                                        onTapped: root.pickCategory("recent")
                                    }

                                    Item {
                                        width: parent.width
                                        height: Theme.space16
                                        Rectangle {
                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                            height: Theme.borderThin
                                            color: Theme.line
                                        }
                                    }

                                    Repeater {
                                        model: root.activeCats
                                        delegate: NavRow {
                                            required property var modelData
                                            label: modelData.label
                                            active: root.current === modelData.key
                                            onTapped: root.pickCategory(modelData.key)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors { left: railFlick.right; top: parent.top; bottom: parent.bottom }
                                width: Theme.borderThin
                                color: Theme.line
                            }

                            Item {
                                id: pane
                                anchors { left: railFlick.right; leftMargin: Theme.borderThin; right: parent.right; top: parent.top; bottom: parent.bottom }
                                clip: true

                                Item {
                                    id: paneHead
                                    width: parent.width
                                    height: Theme.listHeaderHeight

                                    Text {
                                        anchors { left: parent.left; leftMargin: Theme.space16; bottom: parent.bottom; bottomMargin: Theme.space8 }
                                        text: String(root.paneLabel).toUpperCase()
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                                        font.letterSpacing: Theme.trackCaps
                                    }
                                    Text {
                                        anchors { right: parent.right; rightMargin: Theme.space16; bottom: parent.bottom; bottomMargin: Theme.space8 }
                                        text: root.shownApps.length + (root.shownApps.length === 1 ? " app" : " apps")
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontXs
                                    }
                                }

                                Text {
                                    visible: root.shownApps.length === 0
                                    anchors.centerIn: parent
                                    text: root.query !== "" ? "No apps match" : "Nothing here yet"
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontMd
                                }

                                GridView {
                                    id: appGrid
                                    anchors { left: parent.left; right: parent.right; top: paneHead.bottom; bottom: parent.bottom; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                                    clip: true
                                    cellWidth: Math.floor(width / root.launcherMenuGridColumns)
                                    cellHeight: root.launcherMenuCellHeight
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: root.shownApps

                                    Rectangle {
                                        z: 20
                                        visible: win.dragFrom >= 0 && win.dragTo >= 0 && win.dragTo !== win.dragFrom
                                        readonly property int col: win.dragTo % root.launcherMenuGridColumns
                                        readonly property int row: Math.floor(win.dragTo / root.launcherMenuGridColumns)
                                        width: Theme.borderStrong
                                        height: appGrid.cellHeight - Theme.space8 * 2
                                        radius: width / 2
                                        x: (col + (win.dragTo > win.dragFrom ? 1 : 0)) * appGrid.cellWidth - width / 2
                                        y: row * appGrid.cellHeight + Theme.space8
                                        color: Theme.text
                                    }

                                    delegate: Item {
                                        id: cell
                                        required property var modelData
                                        required property int index
                                        readonly property bool isSel: index === root.sel
                                        readonly property bool lifted: win.dragFrom === index
                                        width: appGrid.cellWidth
                                        height: appGrid.cellHeight
                                        z: lifted ? 10 : 0
                                        transform: Translate { x: cell.lifted ? win.dragDX : 0; y: cell.lifted ? win.dragDY : 0 }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: Theme.space2
                                            radius: Theme.radiusCard
                                            color: cell.lifted ? Theme.tile : (cell.isSel ? Theme.tileHover : Theme.transparent)
                                            border.width: cell.lifted ? Theme.borderThin : 0
                                            border.color: Theme.line
                                            Behavior on color { TweenColor { duration: Theme.durFast } }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            width: parent.width - Theme.space8
                                            spacing: Theme.space8

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: root.launcherMenuIconBox
                                                height: width
                                                radius: Theme.radiusCard
                                                color: cell.isSel ? Theme.tile : Theme.tile
                                                Behavior on color { TweenColor { duration: Theme.durFast } }

                                                Image {
                                                    anchors.centerIn: parent
                                                    width: root.launcherMenuIcon
                                                    height: width
                                                    source: root.iconFor(cell.modelData.icon)
                                                    sourceSize.width: 84
                                                    sourceSize.height: 84
                                                    fillMode: Image.PreserveAspectFit
                                                    asynchronous: true
                                                    layer.enabled: true
                                                    layer.effect: MultiEffect { saturation: -1.0; contrast: 0.08 }
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: cell.modelData.name
                                                color: cell.isSel ? Theme.text : Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontSm
                                            }
                                        }

                                        MouseArea {
                                            id: cellArea
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            hoverEnabled: true
                                            cursorShape: cell.lifted ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                            property point pressPos: Qt.point(0, 0)
                                            property bool dragged: false
                                            onEntered: root.sel = cell.index
                                            onPressed: (m) => {
                                                cellArea.dragged = false;
                                                cellArea.pressPos = cellArea.mapToItem(appGrid.contentItem, m.x, m.y);
                                            }
                                            onPositionChanged: (m) => {
                                                if (!cellArea.pressed || !win.reorderable || !(m.buttons & Qt.LeftButton)) return;
                                                const p = cellArea.mapToItem(appGrid.contentItem, m.x, m.y);
                                                if (!cellArea.dragged) {
                                                    if (Math.hypot(p.x - cellArea.pressPos.x, p.y - cellArea.pressPos.y) < Qt.styleHints.startDragDistance) return;
                                                    cellArea.dragged = true;
                                                    win.dragFrom = cell.index;
                                                    root.sel = cell.index;
                                                }
                                                const v = cellArea.mapToItem(appGrid, m.x, m.y);
                                                win.dragViewX = v.x;
                                                win.dragViewY = v.y;
                                                win.dragPressY = cellArea.pressPos.y;
                                                win.dragDX = p.x - cellArea.pressPos.x;
                                                win.dragDY = p.y - cellArea.pressPos.y;
                                                win.dragTo = win.dropIndex(p.x, p.y);
                                            }
                                            onReleased: {
                                                if (!cellArea.dragged) return;
                                                const from = win.dragFrom, to = win.dragTo;
                                                win.resetDrag();
                                                Qt.callLater(() => root.reorderPinned(from, to));
                                            }
                                            onCanceled: win.resetDrag()
                                            onClicked: (m) => {
                                                if (cellArea.dragged) return;
                                                if (m.button === Qt.RightButton) {
                                                    const p = cellArea.mapToItem(card, m.x, m.y);
                                                    win.openCtx(cell.modelData, cell.index, p.x, p.y);
                                                } else {
                                                    root.launch(cell.modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: col.width
                            height: Theme.borderThin
                            color: Theme.line
                        }

                        Item {
                            width: col.width
                            height: root.launcherMenuFootHeight

                            Row {
                                anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                                spacing: Theme.space12

                                Rectangle {
                                    width: root.launcherMenuAvatar
                                    height: root.launcherMenuAvatar
                                    radius: Math.min(width, height) / 2
                                    color: Theme.tile
                                    border.width: Theme.borderThin
                                    border.color: Theme.line
                                    // User photo from AccountsService (same source as
                                    // Control Center); the initial is only a fallback if the file is missing.
                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: Theme.transparent
                                        visible: launcherAvatarImg.status === Image.Ready
                                        Image {
                                            id: launcherAvatarImg
                                            anchors.fill: parent
                                            source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize.width: root.launcherMenuAvatar * 2
                                            sourceSize.height: root.launcherMenuAvatar * 2
                                            asynchronous: true
                                        }
                                    }
                                    Text {
                                        visible: launcherAvatarImg.status !== Image.Ready
                                        anchors.centerIn: parent
                                        text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (Quickshell.env("USER") || "user") + " · macmono"
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontSm
                                }
                            }

                            Row {
                                anchors { right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
                                spacing: Theme.space2

                                Repeater {
                                    model: root.powerActions
                                    delegate: PowerButton {
                                        required property var modelData
                                        act: modelData.act
                                        label: modelData.label
                                        glyph: modelData.glyph
                                        confirm: modelData.confirm
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
