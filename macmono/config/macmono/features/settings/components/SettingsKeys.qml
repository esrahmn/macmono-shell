import QtQuick
import "../../../core"

// Halaman "Keyboard Shortcuts": daftar pintasan dengan kolom cari.
// Data: KeyList.groups (sumber yang sama dengan Cheatsheet), tiap baris [ "Super + S", "Keterangan" ].
//
// Tata letak mengikuti aturan halaman Settings: tanpa kartu, label grup KAPITAL, satu baris per
// pintasan dengan pemisah tipis. Keterangan di kiri (judul baris), keycap di kanan (kontrolnya).
// Keycap memakai token cheatsheet* supaya bentuknya identik dengan Cheatsheet.
//
// Pencarian: setiap kata harus cocok di awal kata pada tombol atau keterangan, satu kata kunci per kata ("super k", "lock"); nama grup ikut dari 3 huruf ("media").
Column {
    id: root
    spacing: 0   // jarak antar grup diatur SettingsCaps, bukan Column (kalau tidak, tiap baris ikut renggang)

    // Satu kata kunci memakai satu kata saja ("super s" tidak cocok dengan "Super + K": "s" tidak boleh
    // ikut memakai kata "Super" yang sudah dipakai kata kunci pertama).
    function matches(terms, words, title) {
        const free = words.slice();
        return terms.every(t => {
            let i = free.findIndex(w => w.startsWith(t));
            if (i >= 0) { free.splice(i, 1); return true; }
            // Nama grup ikut dicocokkan mulai 3 huruf, supaya "media" menampilkan satu grup tapi "s" tidak membuka grup Shell.
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

    // Keluar dari halaman: kolom cari dikosongkan, jadi kembali ke sini selalu mulai dari daftar penuh.
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
