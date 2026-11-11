import QtQuick
import "../../../core"
import "../../../shared/components"

FocusScope {
    id: root

    readonly property int settingsGutter: 16
    readonly property int settingsHeaderHeight: 64
    readonly property int settingsContentMax: 720
    readonly property int settingsSideWidth: 236
    readonly property int settingsBarHeight: 44
    readonly property color settingsBarFill: Qt.rgba(0.11, 0.11, 0.11, 0.96)
    readonly property int settingsPadTop: 16
    readonly property int settingsSearchWidth: 240
    readonly property int settingsSavedMs: 1700
    readonly property int settingsScrollbarWidth: 3
    readonly property int settingsScrollbarInset: 7
    readonly property int settingsScrollbarMin: 24
    signal closeRequested()
    signal navMoved()

    property string pageId: SettingsSchema.pages[0].id
    property var draft: ({})

    property bool savedFlash: false
    Timer { id: savedTimer; interval: root.settingsSavedMs; onTriggered: root.savedFlash = false }

    readonly property string query: searchInput.text
    readonly property bool searching: query.trim() !== ""
    readonly property bool atPage: !searching
    readonly property int dirtyCount: Object.keys(draft).length
    readonly property bool dirty: dirtyCount > 0
    readonly property bool barShown: dirty || savedFlash

    readonly property var navSections: [
        { title: "Personalization", ids: ["appearance", "display", "wallpaper"] },
        { title: "Devices & Input", ids: ["input", "sound"] },
        { title: "System", ids: ["weather", "notif", "power", "apps"] },
        { title: "MacMono", ids: ["keys", "backup", "about"] }
    ]

    readonly property var navGroups: {
        const used = ({});
        const out = [];
        for (const s of navSections) {
            const items = [];
            for (const id of s.ids)
                for (const p of SettingsSchema.pages)
                    if (p.id === id) { items.push(p); used[id] = true; }
            if (items.length > 0) out.push({ title: s.title, items: items });
        }
        const rest = [];
        for (const p of SettingsSchema.pages)
            if (!used[p.id]) rest.push(p);
        if (rest.length > 0) out.push({ title: "More", items: rest });
        return out;
    }

    readonly property var navIds: {
        const ids = [];
        for (const g of navGroups)
            for (const p of g.items) ids.push(p.id);
        return ids;
    }

    readonly property var currentPage: {
        for (const p of SettingsSchema.pages)
            if (p.id === pageId) return p;
        return null;
    }

    readonly property var searchGroups: {
        const q = query.trim().toLowerCase();
        if (q === "") return [];
        const hit = (s) => String(s ?? "").toLowerCase().indexOf(q) >= 0;

        const pageHits = [];
        for (const p of SettingsSchema.pages) {
            let groupHit = false;
            for (const g of p.groups)
                if (hit(g.title)) groupHit = true;
            if (hit(p.label) || hit(p.desc) || groupHit)
                pageHits.push({ id: p.id, label: p.label, desc: p.desc, icon: p.icon });
        }

        const out = [];
        if (pageHits.length > 0)
            out.push({ title: "Pages", pageRows: true, items: pageHits });
        for (const p of SettingsSchema.pages) {
            const items = [];
            for (const g of p.groups)
                for (const it of g.items)
                    if (hit(it.label) || hit(it.desc ?? "") || hit(it.key))
                        items.push(it);
            if (items.length > 0) out.push({ title: p.label, pageId: p.id, pageRows: false, items: items });
        }
        return out;
    }
    readonly property int resultCount: {
        let n = 0;
        for (const g of searchGroups) n += g.items.length;
        return n;
    }
    readonly property var shownGroups: searching ? searchGroups : (currentPage ? currentPage.groups : [])

    readonly property real contentW: Math.min(root.settingsContentMax, flick.width - root.settingsGutter * 2)
    readonly property real contentX: Math.max(root.settingsGutter, (flick.width - contentW) / 2)

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

    function valueOf(item) {
        if (draft.hasOwnProperty(item.key)) return draft[item.key];
        return SettingsStore.v(item.key, item.def);
    }

    function setValue(item, v) {
        savedFlash = false;
        const next = Object.assign({}, draft);
        if (same(v, SettingsStore.v(item.key, item.def))) delete next[item.key];
        else next[item.key] = v;
        draft = next;
        if (previewKeys.indexOf(item.key) >= 0) previewInput();
    }

    // Input settings that are shown live while they are still a draft. Keyboard layout,
    // variant and options are left out on purpose (a wrong layout can lock the keyboard).
    readonly property var previewKeys: [
        "inputSensitivity", "inputRepeatRate", "inputRepeatDelayMs", "inputNaturalScroll",
        "inputTapToClick", "inputDisableWhileTyping", "inputClickfinger", "inputScrollFactor"
    ]
    function previewInput() {
        const get = k => valueOf(SettingsSchema.find(k));
        Sys.hyprSync.previewInput({
            sensitivity: get("inputSensitivity"), repeatRate: get("inputRepeatRate"),
            repeatDelay: get("inputRepeatDelayMs"), naturalScroll: get("inputNaturalScroll"),
            tapToClick: get("inputTapToClick"), disableWhileTyping: get("inputDisableWhileTyping"),
            clickfinger: get("inputClickfinger"), scrollFactor: get("inputScrollFactor")
        });
    }

    function pageResettable(page) {
        if (!page || !page.groups) return false;
        for (const g of page.groups)
            for (const it of g.items)
                if (!it.ro && !it.live) return true;
        return false;
    }

    function pageChangedCount(page) {
        if (!page || !page.groups) return 0;
        let n = 0;
        for (const g of page.groups)
            for (const it of g.items)
                if (!it.ro && !it.live && !same(valueOf(it), it.def)) n++;
        return n;
    }

    function pageDirty(page) {
        if (!page || !page.groups) return false;
        for (const g of page.groups)
            for (const it of g.items)
                if (draft.hasOwnProperty(it.key)) return true;
        return false;
    }

    function resetPage() {
        if (!currentPage) return;
        savedFlash = false;
        const next = Object.assign({}, draft);
        let touchesInput = false;
        for (const g of currentPage.groups)
            for (const it of g.items) {
                if (it.ro || it.live) continue;
                if (previewKeys.indexOf(it.key) >= 0) touchesInput = true;
                if (same(it.def, SettingsStore.v(it.key, it.def))) delete next[it.key];
                else next[it.key] = it.def;
            }
        draft = next;
        if (touchesInput) previewInput();
    }

    function revert() {
        savedFlash = false;
        draft = ({});
        Sys.hyprSync.restoreInput();
    }

    function apply() {
        if (!dirty) return;
        const sets = {};
        const removes = [];
        for (const k in draft) {
            const it = SettingsSchema.find(k);
            if (it && same(draft[k], it.def)) removes.push(k);
            else sets[k] = draft[k];
        }
        const syncs = ({});
        for (const k in draft) {
            const it = SettingsSchema.find(k);
            if (it && it.sync) syncs[it.sync] = true;
        }
        SettingsStore.apply(sets, removes);
        Sys.hyprSync.endPreview();
        if (syncs.input) Sys.hyprSync.syncInput();
        if (syncs.idle) Sys.hyprSync.syncIdle();
        draft = ({});
        savedFlash = true;
        savedTimer.restart();
    }

    function openPage(id) {
        searchInput.text = "";
        pageId = id;
    }

    property string flashKey: ""
    property var pendingReveal: null

    function jumpTo(id, key) {
        flashKey = "";
        openPage(id);
        flashKey = key;
    }

    function jumpToFirstResult() {
        for (const g of searchGroups)
            if (!g.pageRows && g.items.length > 0) { jumpTo(g.pageId, g.items[0].key); return; }
        for (const g of searchGroups)
            if (g.pageRows && g.items.length > 0) { openPage(g.items[0].id); return; }
    }

    function revealRow(entry) {
        pendingReveal = entry;
        if (!pageIntro.running) Qt.callLater(doReveal);
    }
    function doReveal() {
        const e = pendingReveal;
        if (!e) return;
        pendingReveal = null;
        flashKey = "";
        const top = e.mapToItem(flick.contentItem, 0, 0).y;
        const maxY = Math.max(0, flick.contentHeight - flick.height);
        scrollAnim.to = Math.max(0, Math.min(maxY, top - (flick.height - e.height) / 2));
        scrollAnim.restart();
        e.pulse();
    }

    function stepPage(delta) {
        const i = Math.max(0, navIds.indexOf(pageId));
        pageId = navIds[Math.max(0, Math.min(navIds.length - 1, i + delta))];
        navMoved();
    }

    function focusSearch() { searchInput.forceActiveFocus(); }
    function focusPanel() { root.forceActiveFocus(); }

    onPageIdChanged: { flick.contentY = 0; pageIntro.restart(); }
    onQueryChanged: { flick.contentY = 0; pageIntro.restart(); }

    Keys.onEscapePressed: {
        if (searching) searchInput.text = "";
        else if (dirty) revert();
        else closeRequested();
    }
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
            apply();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            focusSearch();
            event.accepted = true;
        } else if (event.text === "/" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && !searchInput.activeFocus) {
            focusSearch();
            event.accepted = true;
        }
    }
    Keys.onUpPressed: if (atPage) stepPage(-1)
    Keys.onDownPressed: if (atPage) stepPage(1)

    component Btn: Rectangle {
        id: btn
        property string label
        property bool primary: false
        signal clicked()

        implicitWidth: btnLabel.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
        implicitHeight: SettingsMetrics.settingsButtonHeight
        radius: Theme.radiusControl + 1
        color: primary ? (btnArea.containsMouse ? Theme.accentHover : Theme.accent)
                       : (btnArea.containsMouse ? Theme.tileHover : Theme.tile)
        Behavior on color { TweenColor { duration: Theme.durFast } }

        SettingsText {
            id: btnLabel
            anchors.centerIn: parent
            text: btn.label
            font.weight: Theme.weightMedium
            color: btn.primary ? Theme.textOnAccent : Theme.text
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component RoundBtn: Rectangle {
        id: rb
        property string glyph
        property int glyphRotation: 0
        property string accessibleName: ""
        signal clicked()

        width: Theme.iconXl + Theme.space8
        height: width
        radius: height / 2
        color: rbArea.containsMouse ? Theme.tileHover : Theme.tile
        Behavior on color { TweenColor { duration: Theme.durFast } }

        Glyph {
            anchors.centerIn: parent
            name: rb.glyph
            rotation: rb.glyphRotation
            color: Theme.text
            width: Theme.iconSm
            height: Theme.iconSm
        }
        MouseArea {
            id: rbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.clicked()
        }
        Accessible.role: Accessible.Button
        Accessible.name: rb.accessibleName
    }

    component NavRow: Item {
        id: navRow
        property var page: null
        property int rowIndex: 0
        property bool current: false
        property bool compact: false

        width: parent ? parent.width : 0
        height: SettingsMetrics.settingsListRowHeight

        Connections {
            target: root
            function onNavMoved() { if (navRow.current && navRow.compact) sideFlick.reveal(navRow); }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusControl
            color: navRow.current ? Theme.tile : (navArea.containsMouse ? Theme.tile : Theme.transparent)
            Behavior on color { TweenColor { duration: Theme.durFast } }
        }

        Rectangle {
            visible: navRow.rowIndex > 0 && !navRow.compact
            z: 2
            x: SettingsMetrics.settingsRowPadX + Theme.iconMd + Theme.space12
            width: navRow.width - x - SettingsMetrics.settingsRowPadX
            height: Theme.borderThin
            color: Theme.line
        }

        Item {
            id: iconBox
            x: SettingsMetrics.settingsRowPadX
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconMd
            height: Theme.iconMd

            Glyph {
                anchors.centerIn: parent
                name: navRow.page ? navRow.page.icon : ""
                color: navRow.current ? Theme.text : Theme.dim
                width: Theme.iconMd
                height: Theme.iconMd
            }

            Rectangle {
                visible: navRow.page ? root.pageDirty(navRow.page) : false
                width: SettingsMetrics.settingsDot
                height: SettingsMetrics.settingsDot
                radius: height / 2
                color: Theme.accent
                anchors { right: parent.right; top: parent.top; rightMargin: -Theme.space2; topMargin: -Theme.space2 }
            }
        }

        Glyph {
            id: chevron
            visible: !navRow.compact
            anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
            name: "chevron"
            rotation: -90
            color: Theme.faint
            width: Theme.iconSm
            height: Theme.iconSm
        }

        SettingsText {
            anchors {
                left: iconBox.right; leftMargin: Theme.space12
                right: navRow.compact ? parent.right : chevron.left
                rightMargin: Theme.space8
                verticalCenter: parent.verticalCenter
            }
            text: navRow.page ? navRow.page.label : ""
            color: (navRow.current || !navRow.compact) ? Theme.text : Theme.text
            font.pixelSize: navRow.compact ? Theme.fontLg : Theme.fontLg
            font.weight: Theme.weightMedium
            font.letterSpacing: Theme.trackSnug
            elide: Text.ElideRight
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (navRow.page) root.openPage(navRow.page.id)
        }

        Accessible.role: Accessible.Button
        Accessible.name: navRow.page ? navRow.page.label : ""
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.panel
        border.width: Theme.borderThin
        border.color: Theme.line
        clip: true
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: root.forceActiveFocus() }

        Item {
            id: header
            anchors { top: parent.top; left: sideNav.right; right: parent.right }
            height: root.settingsHeaderHeight

            SettingsText {
                id: titleText
                x: root.contentX + SettingsMetrics.settingsRowPadX
                width: parent.width - x - root.settingsSearchWidth - Theme.iconXl - Theme.space8 - root.settingsGutter - Theme.space12 * 2
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.searching ? "Search" : (root.currentPage ? root.currentPage.label : "Settings")
                font.pixelSize: Theme.font2xl
                font.weight: Theme.weightSemibold
                font.letterSpacing: Theme.trackTight
                font.variableAxes: ({ "opsz": 32, "wght": Theme.weightSemibold })
            }

            RoundBtn {
                anchors { right: parent.right; rightMargin: root.settingsGutter; verticalCenter: parent.verticalCenter }
                glyph: "close"
                accessibleName: "Close"
                onClicked: root.closeRequested()
            }
        }

        Item {
            id: sideNav
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: root.settingsSideWidth

            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: Theme.borderThin
                color: Theme.line
            }

            Item {
                id: sideTitleBox
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: root.settingsHeaderHeight

                SettingsText {
                    anchors { left: parent.left; leftMargin: Theme.space8 + SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
                    text: "Settings"
                    font.pixelSize: Theme.fontLg
                    font.weight: Theme.weightSemibold
                    font.letterSpacing: Theme.trackSnug
                }
            }

            Flickable {
                id: sideFlick
                anchors {
                    top: sideTitleBox.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                    leftMargin: Theme.space8; rightMargin: Theme.space8; bottomMargin: Theme.radiusPanel
                }
                contentWidth: width
                contentHeight: sideSections.height + Theme.space16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                function reveal(item) {
                    const top = item.mapToItem(contentItem, 0, 0).y - Theme.space12;
                    const bottom = top + item.height + Theme.space12 * 2;
                    if (top < contentY) contentY = Math.max(0, top);
                    else if (bottom > contentY + height) contentY = Math.max(0, Math.min(contentHeight - height, bottom - height));
                }

                Column {
                    id: sideSections
                    width: parent.width
                    spacing: SettingsMetrics.settingsGroupSpacing

                    Repeater {
                        model: root.navGroups
                        delegate: Column {
                            id: sideSection
                            required property var modelData
                            width: sideSections.width
                            spacing: Theme.space4

                            SettingsText {
                                text: sideSection.modelData.title.toUpperCase()
                                color: Theme.dim
                                font.pixelSize: Theme.fontXs
                                font.weight: Theme.weightSemibold
                                font.letterSpacing: Theme.trackCaps
                                leftPadding: SettingsMetrics.settingsRowPadX
                            }

                            Repeater {
                                model: sideSection.modelData.items
                                delegate: NavRow {
                                    required property var modelData
                                    required property int index
                                    compact: true
                                    page: modelData
                                    rowIndex: index
                                    current: !root.searching && root.pageId === modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: searchBox
            anchors {
                top: parent.top; topMargin: (root.settingsHeaderHeight - SettingsMetrics.settingsSearchHeight) / 2
                right: parent.right; rightMargin: root.settingsGutter + Theme.iconXl + Theme.space8 + Theme.space12
            }
            width: root.settingsSearchWidth
            height: SettingsMetrics.settingsSearchHeight
            radius: height / 2
            color: Theme.scrim
            border.width: Theme.borderThin
            border.color: searchInput.activeFocus ? Theme.lineFocus : Theme.line

            Glyph {
                id: searchIcon
                name: "search"
                color: Theme.dim
                width: Theme.iconMd
                height: Theme.iconMd
                anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
            }

            TextInput {
                id: searchInput
                anchors { left: searchIcon.right; leftMargin: Theme.space8; right: clearBtn.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                color: Theme.text
                selectionColor: Theme.tileHover
                font.family: Theme.font
                font.pixelSize: Theme.fontLg
                font.hintingPreference: Font.PreferVerticalHinting
                renderType: TextInput.NativeRendering
                clip: true
                selectByMouse: true
                Accessible.name: "Search settings"
                Keys.onUpPressed: if (root.atPage) root.stepPage(-1)
                Keys.onDownPressed: if (root.atPage) root.stepPage(1)
                onAccepted: root.jumpToFirstResult()
                Keys.onEscapePressed: event => {
                    if (text !== "") { text = ""; event.accepted = true; }
                    else { event.accepted = false; }
                }

                SettingsText {
                    visible: searchInput.text === ""
                    text: "Search settings"
                    color: Theme.faint
                    font.pixelSize: Theme.fontLg
                }
            }

            Item {
                id: clearBtn
                visible: searchInput.text !== ""
                width: Theme.iconXl
                height: Theme.iconXl
                anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }

                Glyph {
                    anchors.centerIn: parent
                    name: "close"
                    color: Theme.dim
                    width: Theme.iconSm
                    height: Theme.iconSm
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { searchInput.text = ""; searchInput.forceActiveFocus(); }
                }
            }
        }

        Flickable {
            id: flick
            anchors { top: header.bottom; topMargin: Theme.space12; bottom: parent.bottom; bottomMargin: Theme.space8; left: sideNav.right; right: parent.right }
            contentWidth: width
            contentHeight: content.height + root.settingsPadTop + root.settingsGutter * 2
                           + (root.barShown ? root.settingsBarHeight + Theme.space8 : Theme.space8)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            function reveal(item) {
                const top = item.mapToItem(contentItem, 0, 0).y - Theme.space12;
                const bottom = top + item.height + Theme.space12 * 2;
                if (top < contentY) contentY = Math.max(0, top);
                else if (bottom > contentY + height) contentY = Math.max(0, Math.min(contentHeight - height, bottom - height));
            }

            Column {
                id: content
                x: root.contentX
                y: root.settingsPadTop
                width: root.contentW
                spacing: SettingsMetrics.settingsGroupSpacing
                transform: Translate { id: contentShift }

                SettingsAbout {
                    visible: root.atPage && root.currentPage && root.currentPage.about === true
                    width: content.width
                }

                SettingsKeys {
                    visible: root.atPage && root.currentPage && root.currentPage.keys === true
                    width: content.width
                }

                SettingsDisplay {
                    visible: root.atPage && root.currentPage && root.currentPage.monitors === true
                    width: content.width
                }

                SettingsWeatherPreview {
                    visible: root.atPage && root.currentPage && root.currentPage.weather === true && Sys.weather.hasLocation
                    width: content.width
                }

                SettingsWeather {
                    visible: root.atPage && root.currentPage && root.currentPage.weather === true
                    width: content.width
                }

                SettingsPower {
                    visible: root.atPage && root.currentPage && root.currentPage.power === true
                    width: content.width
                }

                SettingsSound {
                    visible: root.atPage && root.currentPage && root.currentPage.sound === true
                    width: content.width
                }

                SettingsNotifications {
                    visible: root.atPage && root.currentPage && root.currentPage.notifications === true
                    width: content.width
                }

                SettingsApps {
                    visible: root.atPage && root.currentPage && root.currentPage.apps === true
                    width: content.width
                }

                SettingsBackup {
                    visible: root.atPage && root.currentPage && root.currentPage.backup === true
                    width: content.width
                }

                SettingsAppearancePreview {
                    visible: root.atPage && root.currentPage && root.currentPage.preview === "appearance"
                    width: content.width
                    panelOpacity: root.valueOf(SettingsSchema.find("panelOpacity"))
                    clock24h: root.valueOf(SettingsSchema.find("clock24h"))
                    seconds: root.valueOf(SettingsSchema.find("clockSeconds"))
                    showDate: root.valueOf(SettingsSchema.find("clockDate"))
                }

                SettingsWallpaperPreview {
                    visible: root.atPage && root.currentPage && root.currentPage.preview === "wallpaper"
                    width: content.width
                }

                SettingsText {
                    visible: root.searching && root.resultCount === 0
                    leftPadding: SettingsMetrics.settingsRowPadX
                    text: "No results for “" + root.query.trim() + "”"
                    color: Theme.dim
                }

                Repeater {
                    model: root.shownGroups

                    delegate: Column {
                        id: group
                        required property var modelData
                        width: content.width
                        spacing: Theme.space8

                        SettingsText {
                            text: group.modelData.title.toUpperCase()
                            color: Theme.dim
                            font.pixelSize: Theme.fontXs
                            font.weight: Theme.weightSemibold
                            font.letterSpacing: Theme.trackCaps
                            leftPadding: SettingsMetrics.settingsRowPadX
                        }

                        SettingsTouchpadPreview {
                            visible: root.atPage && group.modelData.preview === "touchpad"
                            width: parent.width
                            natural: root.valueOf(SettingsSchema.find("inputNaturalScroll"))
                            factor: root.valueOf(SettingsSchema.find("inputScrollFactor"))
                        }
                        SettingsPointerPreview {
                            visible: root.atPage && group.modelData.preview === "pointer"
                            width: parent.width
                            sens: root.valueOf(SettingsSchema.find("inputSensitivity"))
                        }
                        SettingsKeyboardPreview {
                            visible: root.atPage && group.modelData.preview === "keyboard"
                            width: parent.width
                            rate: root.valueOf(SettingsSchema.find("inputRepeatRate"))
                            delayMs: root.valueOf(SettingsSchema.find("inputRepeatDelayMs"))
                        }
                        SettingsNightPreview {
                            visible: root.atPage && group.modelData.preview === "night"
                            width: parent.width
                            warmKelvin: root.valueOf(SettingsSchema.find("nightLightKelvin"))
                            normalKelvin: root.valueOf(SettingsSchema.find("nightLightOffKelvin"))
                            active: Sys.nightLight
                        }
                        SettingsSleepPreview {
                            visible: root.atPage && group.modelData.preview === "sleep"
                            width: parent.width
                            lockMin: root.valueOf(SettingsSchema.find("idleLockMin"))
                            offMin: root.valueOf(SettingsSchema.find("idleScreenOffMin"))
                            suspendMin: root.valueOf(SettingsSchema.find("idleSuspendMin"))
                        }
                        SettingsAlertPreview {
                            visible: root.atPage && group.modelData.preview === "alert"
                            width: parent.width
                            warnLevels: root.valueOf(SettingsSchema.find("batteryWarnLevels"))
                            criticalLevel: root.valueOf(SettingsSchema.find("batteryCriticalLevel"))
                        }

                        Rectangle {
                            width: parent.width
                            height: rows.height
                            color: Theme.transparent

                            Column {
                                id: rows
                                width: parent.width

                                Repeater {
                                    model: group.modelData.pageRows ? group.modelData.items : []

                                    delegate: NavRow {
                                        required property var modelData
                                        required property int index
                                        page: modelData
                                        rowIndex: index
                                    }
                                }

                                Repeater {
                                    model: group.modelData.pageRows ? [] : group.modelData.items

                                    delegate: SettingsItem {
                                        id: entry
                                        required property var modelData
                                        required property int index

                                        width: rows.width
                                        item: modelData
                                        separator: index > 0
                                        modified: !modelData.ro && root.draft.hasOwnProperty(modelData.key)
                                        titleLink: root.searching
                                        onTitleClicked: root.jumpTo(group.modelData.pageId, modelData.key)
                                        readonly property bool wanted: root.flashKey !== "" && modelData.key === root.flashKey
                                        onWantedChanged: if (wanted) root.revealRow(entry)
                                        Component.onCompleted: if (wanted) root.revealRow(entry)
                                        value: modelData.ro
                                            ? ""
                                            : (modelData.live ? Sys[modelData.key] : root.valueOf(modelData))
                                        onEdit: v => {
                                            if (modelData.live) Sys[modelData.liveAction]();
                                            else root.setValue(modelData, v);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsResetPage {
                    visible: root.atPage && root.pageResettable(root.currentPage)
                    width: content.width
                    pageKey: root.pageId
                    changedCount: root.pageChangedCount(root.currentPage)
                    onConfirmed: root.resetPage()
                }
            }
        }

        ParallelAnimation {
            id: pageIntro
            Tween { target: content; property: "opacity"; from: 0; to: 1 }
            Tween { target: contentShift; property: "y"; from: Theme.space8; to: 0 }
            onFinished: root.doReveal()
        }
        Tween { id: scrollAnim; target: flick; property: "contentY"; duration: Theme.durSlow }

        Rectangle {
            visible: flick.contentHeight > flick.height
            x: flick.x + flick.width - root.settingsScrollbarInset
            y: flick.y + flick.visibleArea.yPosition * flick.height
            width: root.settingsScrollbarWidth
            height: Math.max(root.settingsScrollbarMin, flick.visibleArea.heightRatio * flick.height)
            radius: width / 2
            color: Theme.tilePress
        }

        Rectangle {
            id: statusBar
            property real slide: root.barShown ? 0 : 1
            Behavior on slide { Tween {} }

            anchors { left: sideNav.right; right: parent.right; bottom: parent.bottom; leftMargin: root.settingsGutter; rightMargin: root.settingsGutter; bottomMargin: root.settingsGutter }
            height: root.settingsBarHeight
            radius: Theme.radiusCard
            color: root.settingsBarFill
            border.width: Theme.borderThin
            border.color: Theme.line
            opacity: 1 - slide
            visible: opacity > 0
            transform: Translate { y: statusBar.slide * Theme.space12 }

            MouseArea { anchors.fill: parent }

            Item {
                anchors { left: parent.left; leftMargin: SettingsMetrics.settingsRowPadX; right: barButtons.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                height: statusText.implicitHeight

                Glyph {
                    id: savedCheck
                    visible: !root.dirty
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    name: "check"
                    color: Theme.text
                    width: Theme.iconSm
                    height: Theme.iconSm
                }

                SettingsText {
                    id: statusText
                    anchors {
                        left: savedCheck.visible ? savedCheck.right : parent.left
                        leftMargin: savedCheck.visible ? Theme.space8 : 0
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontLg
                    font.weight: Theme.weightMedium
                    text: root.dirty
                        ? root.dirtyCount + (root.dirtyCount === 1 ? " unsaved change" : " unsaved changes")
                        : "Saved"
                }
            }

            Row {
                id: barButtons
                visible: root.dirty
                anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                spacing: Theme.space8

                Btn { label: "Cancel"; onClicked: root.revert() }
                Btn { label: "Apply"; primary: true; onClicked: root.apply() }
            }
        }
    }
}
