import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    readonly property int fontEmoji: 24
    readonly property int emojiTitleHeight: 28
    readonly property int emojiCategoryHeight: 28
    readonly property int emojiCellSize: 40
    readonly property int emojiScrollbarWidth: 3
    readonly property int emojiFooterHeight: 34

    property var entries: []
    property var recentEmojis: []
    property bool loading: true
    property bool loadFailed: false
    property string selectedCategory: "all"

    readonly property var categoryOptions: {
        const options = [
            { id: "all", label: "All" },
            { id: "faces", label: "Faces" },
            { id: "people", label: "People" },
            { id: "nature", label: "Nature" },
            { id: "food", label: "Food" },
            { id: "activity", label: "Activity" },
            { id: "travel", label: "Travel" },
            { id: "objects", label: "Objects" },
            { id: "symbols", label: "Symbols" },
            { id: "flags", label: "Flags" }
        ];
        if (recentEmojis.length > 0)
            options.splice(1, 0, { id: "recent", label: "Terbaru" });
        return options;
    }

    function matchesCategory(entry, category) {
        const name = entry.name.toLowerCase();
        const patterns = {
            faces: /\b(face|smile|grin|frown|wink|kiss|cry|laugh|expression|emotion|angry|sick|sleepy|shocked|scream)\b/,
            people: /\b(person|people|man|woman|boy|girl|child|baby|family|hand|finger|foot|leg|arm|hair|body|clothing|shoe|shirt|dress)\b/,
            nature: /\b(animal|bird|cat|dog|monkey|bear|rabbit|fish|whale|bug|insect|plant|flower|tree|leaf|weather|sun|moon|cloud|fire|water|snow|rain|wind|earth|nature|reptile|amphibian)\b/,
            food: /\b(food|drink|fruit|vegetable|meal|bread|cake|meat|dish|coffee|tea|beer|wine|cheese|snack|cooking|sweet|ice cream)\b/,
            activity: /\b(sport|ball|game|medal|trophy|art|music|instrument|event|award|celebration|party|holiday|entertainment|playing)\b/,
            travel: /\b(vehicle|car|truck|bus|plane|airplane|ship|boat|transport|building|house|place|map|hotel|railway|road|mountain|beach|bridge|station|travel|camping)\b/,
            objects: /\b(tool|phone|computer|light|book|money|key|weapon|mail|clock|camera|battery|office|paper|science|medical|household|furniture|musical instrument|watch|gift|bag)\b/,
            symbols: /\b(heart|arrow|religion|sign|button|number|keycap|currency|punctuation|letter|zodiac|warning|check|cross|symbol|mark|radioactive|recycle)\b/,
            flags: /\bflag\b/
        };
        const pattern = patterns[category];
        return pattern ? pattern.test(name) : false;
    }

    function parseData(data) {
        const parsed = [];
        for (const line of data.split("\n")) {
            const value = line.trim();
            const separator = value.indexOf(" ");
            if (separator <= 0) continue;
            parsed.push({
                emoji: value.slice(0, separator),
                name: value.slice(separator + 1).trim()
            });
        }
        entries = parsed;
        loading = false;
        loadFailed = parsed.length === 0;
    }

    Process {
        id: dataProc
        command: ["cat", Quickshell.shellDir + "/features/emojiPicker/data/emoji.txt"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseData(text)
        }
        onExited: (code) => {
            if (code !== 0) {
                root.loading = false;
                root.loadFailed = true;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.emojiOpen && Sys.emojiScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
            readonly property bool present: reveal.present
            readonly property var filtered: {
                const query = search.text.trim().toLowerCase();
                if (query)
                    return root.entries.filter(entry => entry.name.toLowerCase().includes(query)
                        || entry.emoji.includes(query));
                if (root.selectedCategory === "recent")
                    return root.recentEmojis.map(emoji =>
                        root.entries.find(entry => entry.emoji === emoji)).filter(entry => entry);
                if (root.selectedCategory === "all")
                    return root.entries;
                return root.entries.filter(entry => root.matchesCategory(entry, root.selectedCategory));
            }

            function selectEmoji(index) {
                if (grid.count === 0)
                    return;
                grid.currentIndex = Math.max(0, Math.min(index, grid.count - 1));
                grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
            }

            function navKey(event) {
                const count = win.filtered.length;
                if (event.key === Qt.Key_Down) {
                    if (count > 0) win.selectEmoji(grid.currentIndex + grid.columnCount);
                    return true;
                } else if (event.key === Qt.Key_Up) {
                    if (count > 0) win.selectEmoji(grid.currentIndex - grid.columnCount);
                    return true;
                } else if (event.key === Qt.Key_Right) {
                    if (count > 0) win.selectEmoji(grid.currentIndex + 1);
                    return true;
                } else if (event.key === Qt.Key_Left) {
                    if (count > 0) win.selectEmoji(grid.currentIndex - 1);
                    return true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    win.copyEmoji(grid.currentIndex);
                    return true;
                }
                return false;
            }

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:emoji"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onShownChanged: {
                if (!shown)
                    return;
                search.text = "";
                grid.currentIndex = 0;
                grid.contentY = 0;
                keyCatcher.forceActiveFocus();
            }

            MouseArea {
                anchors.fill: parent
                enabled: win.shown
                onClicked: Sys.emojiOpen = false
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: Math.min(470, parent.width - 32)
                height: Math.min(490, parent.height - 40)
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                transform: Translate { y: Theme.drawerOffset(panel.y + panel.height, win.travel) }

                MouseArea { anchors.fill: parent }

                Item {
                    id: keyCatcher
                    focus: true
                    Keys.onPressed: (e) => {
                        if (win.navKey(e)) { e.accepted = true; return; }
                        if (e.key === Qt.Key_Escape) {
                            Sys.emojiOpen = false;
                            e.accepted = true;
                        } else if (e.text.length > 0 && e.text >= " "
                                   && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                            search.forceActiveFocus();
                            search.text += e.text;
                            search.field.cursorPosition = search.text.length;
                            e.accepted = true;
                        }
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.space16
                    spacing: Theme.space12
                    opacity: win.anim

                    Row {
                        id: title
                        width: parent.width
                        height: root.emojiTitleHeight
                        spacing: Theme.space8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Emoji"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.font2xl
                            font.weight: Theme.weightSemibold
                            font.letterSpacing: Theme.trackTight
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.loading ? "Loading…" : win.filtered.length + " emoji"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontXs
                        }
                    }

                    UiSearchField {
                        id: search
                        width: parent.width
                        radius: height / 2
                        placeholder: "Search emoji"
                        onEscaped: Sys.emojiOpen = false
                        onKeyPressed: (event) => { if (win.navKey(event)) event.accepted = true; }
                    }

                    Flickable {
                        id: categoryBar
                        width: parent.width
                        height: root.emojiCategoryHeight
                        contentWidth: categoryRow.implicitWidth
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        Row {
                            id: categoryRow
                            height: parent.height
                            width: implicitWidth
                            spacing: Theme.space8

                            Repeater {
                                model: root.categoryOptions
                                delegate: Item {
                                    id: catItem
                                    required property var modelData
                                    readonly property bool picked: root.selectedCategory === modelData.id
                                    width: categoryLabel.implicitWidth + Theme.space8
                                    height: parent.height

                                    Rectangle {
                                        anchors { left: categoryLabel.left; right: categoryLabel.right; top: categoryLabel.bottom; topMargin: Theme.space2 }
                                        height: Theme.borderThin
                                        color: Theme.text
                                        visible: catItem.picked
                                    }

                                    Text {
                                        id: categoryLabel
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: catItem.picked ? Theme.text : Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontXs
                                        font.weight: catItem.picked ? Theme.weightSemibold : Theme.weightMedium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.selectedCategory = modelData.id;
                                            grid.currentIndex = 0;
                                            grid.contentY = 0;
                                            categoryBar.contentX = Math.max(0, Math.min(parent.x,
                                                categoryBar.contentWidth - categoryBar.width));
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GridView {
                        id: grid
                        width: parent.width
                        height: Math.max(0, parent.height - title.height - search.height
                            - categoryBar.height - footer.height - parent.spacing * 4)
                        cellWidth: 46
                        cellHeight: 46
                        readonly property int columnCount: Math.max(1, Math.floor(width / cellWidth))
                        clip: true
                        model: win.filtered
                        currentIndex: 0
                        reuseItems: true
                        boundsBehavior: Flickable.StopAtBounds
                        onModelChanged: {
                            currentIndex = 0;
                            contentY = 0;
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !root.loading && win.filtered.length === 0
                            text: root.loadFailed ? "Could not load emoji" : "No emoji found"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSm
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: root.emojiCellSize
                            height: root.emojiCellSize
                            radius: Theme.radiusControl
                            color: mouse.containsMouse || grid.currentIndex === index ? Theme.tileHover : Theme.transparent
                            border.width: grid.currentIndex === index ? Theme.borderThin : 0
                            border.color: Theme.line

                            Behavior on color {
                                TweenColor { duration: Theme.durFast }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.emoji
                                font.pixelSize: root.fontEmoji
                            }
                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: grid.currentIndex = index
                                onClicked: win.copyEmoji(index)
                            }
                        }

                        Rectangle {
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                                rightMargin: Theme.space2
                            }
                            width: root.emojiScrollbarWidth
                            radius: width / 2
                            color: Theme.tile
                            visible: grid.contentHeight > grid.height + 1

                            Rectangle {
                                width: parent.width
                                height: Math.max(22, grid.height * grid.height / grid.contentHeight)
                                y: grid.contentY / Math.max(1, grid.contentHeight - grid.height)
                                    * (parent.height - height)
                                radius: width / 2
                                color: Theme.text
                            }
                        }
                    }

                    Item {
                        id: footer
                        width: parent.width
                        visible: root.loading || root.loadFailed || win.filtered.length === 0
                        height: visible ? root.emojiFooterHeight : 0
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.loading ? "Loading emoji…" :
                                  root.loadFailed ? "Could not load emoji" :
                                  (win.filtered.length === 0 ? "No emoji found" : "")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSm
                        }

                    }
                }
            }

            function copyEmoji(index) {
                const entry = win.filtered[index];
                if (!entry) return;
                Quickshell.execDetached(["wl-copy", entry.emoji]);
                const recent = root.recentEmojis.slice();
                const previousIndex = recent.indexOf(entry.emoji);
                if (previousIndex >= 0)
                    recent.splice(previousIndex, 1);
                recent.unshift(entry.emoji);
                root.recentEmojis = recent.slice(0, 24);
                Sys.emojiOpen = false;
            }
        }
    }
}
