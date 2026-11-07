import QtQuick
import "../../../core"
import "../../../shared/components"

// Daftar pintasan keyboard untuk halaman "Keyboard Shortcuts" di Pengaturan.
// Datanya KeyList.groups (sumber yang sama dengan Cheatsheet): tiap baris [ "Super + S", "Keterangan" ].
// Keycap-nya memakai token cheatsheet* supaya bentuknya identik dengan Cheatsheet, bukan salinan baru.
Item {
    id: root
    property var rows: []

    implicitHeight: col.height + Theme.settingsRowPadY * 2

    Column {
        id: col
        x: Theme.settingsRowPadX
        y: Theme.settingsRowPadY
        width: root.width - Theme.settingsRowPadX * 2
        spacing: Theme.space2

        Repeater {
            model: root.rows

            delegate: Item {
                id: row
                required property var modelData
                required property int index

                width: col.width
                height: Theme.cheatsheetRowHeight

                Row {
                    id: caps
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space4

                    Repeater {
                        model: String(row.modelData[0]).split(" + ")

                        delegate: Rectangle {
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
                                text: parent.modelData
                                font.pixelSize: Theme.fontBodyLg
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                SettingsText {
                    anchors {
                        left: caps.right; leftMargin: Theme.space12
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: row.modelData[1]
                    color: Theme.settingsDescText
                    font.pixelSize: Theme.fontBodyLg
                }
            }
        }
    }
}
