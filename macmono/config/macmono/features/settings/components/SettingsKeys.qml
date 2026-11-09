import QtQuick
import "../../../core"

Column {
    id: root
    spacing: 0

    function matches(terms, words, title) {
        const free = words.slice();
        return terms.every(t => {
            let i = free.findIndex(w => w.startsWith(t));
            if (i >= 0) { free.splice(i, 1); return true; }
            return t.length >= 3 && title.some(w => w.startsWith(t));
        });
    }

    readonly property var shown: {
        const terms = field.text.toLowerCase().split(/[\s+]+/).filter(t => t !== "");
        if (terms.length === 0) return KeyList.groups;
        const out = [];
        for (const g of KeyList.groups) {
            const title = g.title.toLowerCase().split(/[\s+]+/);
            const items = g.items.filter(it => matches(terms, (it[0] + " " + it[1]).toLowerCase().split(/[\s+]+/), title));
            if (items.length > 0) out.push({ title: g.title, items: items });
        }
        return out;
    }

    onVisibleChanged: if (!visible) field.clear()

    SettingsSearchField {
        id: field
        width: root.width
        placeholder: "Search shortcuts"
    }

    Repeater {
        model: root.shown

        delegate: Column {
            id: grp
            required property var modelData

            width: root.width

            SettingsCaps { text: grp.modelData.title.toUpperCase() }

            Repeater {
                model: grp.modelData.items

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: grp.width
                    height: Theme.settingsListRowHeight

                    Rectangle {
                        visible: row.index > 0
                        x: Theme.settingsRowPadX
                        width: row.width - Theme.settingsRowPadX * 2
                        height: Theme.borderThin
                        color: Theme.line
                    }

                    SettingsText {
                        anchors {
                            left: parent.left; leftMargin: Theme.settingsRowPadX
                            right: caps.left; rightMargin: Theme.space12
                            verticalCenter: parent.verticalCenter
                        }
                        elide: Text.ElideRight
                        text: row.modelData[1]
                        font.pixelSize: Theme.fontHeading
                        font.weight: Font.Medium
                    }

                    Row {
                        id: caps
                        anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space4

                        Repeater {
                            model: String(row.modelData[0]).split(" + ")

                            delegate: Rectangle {
                                id: cap
                                required property string modelData

                                width: Math.max(Theme.cheatsheetKeycapMinWidth, capText.implicitWidth + Theme.cheatsheetKeycapPadding)
                                height: Theme.cheatsheetKeycapHeight
                                radius: Theme.radiusKey
                                color: Theme.tileMid
                                border.width: Theme.borderThin
                                border.color: Theme.lineStrong

                                SettingsText {
                                    id: capText
                                    anchors.centerIn: parent
                                    text: cap.modelData
                                    font.pixelSize: Theme.fontBodyLg
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsText {
        visible: root.shown.length === 0
        width: root.width
        leftPadding: Theme.settingsRowPadX
        topPadding: Theme.space12
        text: "No shortcuts match “" + field.text.trim() + "”"
        color: Theme.dim
    }
}
