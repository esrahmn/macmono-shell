import QtQuick
import "../../../core"

// Satu baris pengaturan: judul di kiri, kontrol di kanan.
// `stacked` (slider, daftar chip): kontrol pindah ke bawah judul dan melebar penuh; nilai (`valueText`)
// tampil di ujung kanan baris judul. Deskripsi dan nama key sengaja tidak digambar: keduanya
// terbaca sebagai teks ganda di bawah judul, dan key-nya sudah bisa dilihat di file settings.json.
Item {
    id: row
    property string title: ""
    property string valueText: ""      // nilai di ujung kanan baris judul (dipakai baris stacked)
    property bool modified: false      // ada perubahan yang belum diterapkan
    property bool resettable: false    // nilai sekarang beda dari bawaan
    property string resetLabel: "Reset"  // teks tautan di samping judul (mis. "Remove" untuk entri buatan sendiri)
    property bool stacked: false
    property bool separator: false
    property bool titleLink: false     // judul bisa diklik (hasil pencarian: lompat ke halamannya)
    signal resetRequested()
    signal titleClicked()

    // Sorot baris sebentar (dipakai setelah lompat dari hasil pencarian). Hanya opasitas, tidak menggeser tata letak (R6).
    function pulse() { flashAnim.restart(); }

    default property alias content: slot.data

    readonly property int padX: Theme.settingsRowPadX
    readonly property int padY: Theme.settingsRowPadY
    readonly property int padBottom: padY
    readonly property int bodyHeight: stacked ? texts.height + Theme.space10 + slot.height : Math.max(texts.height, slot.height)

    implicitHeight: padY + bodyHeight + padBottom

    Rectangle {
        id: flashRect
        z: -1      // di bawah teks dan kontrol
        anchors.fill: parent
        radius: Theme.radiusXs
        color: Theme.tileHover
        opacity: 0
    }
    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: flashRect; property: "opacity"; to: 1; duration: Theme.animBase; easing.type: Theme.easeOut }
        PauseAnimation { duration: Theme.settingsFlashHoldMs }
        NumberAnimation { target: flashRect; property: "opacity"; to: 0; duration: Theme.settingsFlashFadeMs; easing.type: Theme.easeOut }
    }

    Rectangle {
        visible: row.separator
        z: 2      // digambar di atas sorotan hover, supaya garis pemisah tidak berkedip hilang-muncul
        x: row.padX
        width: row.width - row.padX * 2
        height: Theme.borderThin
        color: Theme.line
    }

    Column {
        id: texts
        x: row.padX
        y: row.stacked ? row.padY : row.padY + (row.bodyHeight - height) / 2   // rata tengah dengan kontrol di kanan
        width: row.stacked ? row.width - row.padX * 2 : row.width - row.padX * 2 - slot.width - Theme.space18
        spacing: Theme.space3

        Item {
            width: parent.width
            height: titleText.height

            Row {
                spacing: Theme.space8

                SettingsText {
                    id: titleText
                    text: row.title
                    font.pixelSize: Theme.fontHeading
                    font.weight: Font.Medium
                    font.underline: row.titleLink && titleArea.containsMouse

                    MouseArea {
                        id: titleArea
                        anchors.fill: parent
                        enabled: row.titleLink
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.titleClicked()
                    }
                }

                Item {
                    visible: row.modified
                    width: Theme.settingsDot
                    height: titleText.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.settingsDot
                        height: Theme.settingsDot
                        radius: height / 2
                        color: Theme.inverse
                    }
                }

                Item {
                    visible: row.resettable
                    width: resetText.implicitWidth
                    height: titleText.height

                    SettingsText {
                        id: resetText
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.resetLabel
                        font.pixelSize: Theme.fontBodyLg
                        color: resetArea.containsMouse ? Theme.text : Theme.muted
                        font.underline: resetArea.containsMouse
                    }
                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        anchors.margins: -Theme.space4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.resetRequested()
                    }
                }
            }

            SettingsText {
                visible: row.valueText !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.valueText
                color: Theme.textSoft
                font.pixelSize: Theme.fontHeading
                font.features: ({ "tnum": 1 })
            }
        }

    }

    Item {
        id: slot
        x: row.stacked ? row.padX : row.width - row.padX - width
        y: row.stacked ? row.padY + texts.height + Theme.space10 : row.padY + (row.bodyHeight - height) / 2
        width: row.stacked ? row.width - row.padX * 2 : childrenRect.width
        height: childrenRect.height
    }
}
