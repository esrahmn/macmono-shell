import QtQuick
import "../../../core"

// Footer "Reset page" di dasar halaman pengaturan yang punya draft.
// Zona sendiri: jarak + garis tipis dari grup di atasnya, lalu satu baris (judul kiri, tombol kanan)
// dan satu catatan akibat aksi. Dua ketukan, sama dengan Reset di Backup & Reset:
// ketukan pertama "mempersenjatai" tombol (putih + "Tap again"), tidak diketuk lagi dalam
// Theme.settingsConfirmMs -> kembali normal. Reset hanya mengisi draft, jadi tetap bisa dibatalkan (Cancel).
Column {
    id: root

    property int changedCount: 0     // jumlah opsi di halaman ini yang beda dari bawaan (draft ikut dihitung)
    property string pageKey: ""      // id halaman; berganti halaman -> tombol dilepas
    signal confirmed()

    property bool armed: false
    spacing: 0

    onPageKeyChanged: { armed = false; confirmTimer.stop(); }
    onChangedCountChanged: if (changedCount === 0) { armed = false; confirmTimer.stop(); }

    Timer {
        id: confirmTimer
        interval: Theme.settingsConfirmMs
        onTriggered: root.armed = false
    }

    // jarak + garis pemisah: zona ini tidak boleh terlihat sebagai lanjutan daftar pengaturan
    Item {
        width: root.width
        height: Theme.settingsGroupSpacing * 2

        Rectangle {
            x: Theme.settingsRowPadX
            y: (parent.height - height) / 2
            width: parent.width - Theme.settingsRowPadX * 2
            height: Theme.borderThin
            color: Theme.line
        }
    }

    SettingsRow {
        width: root.width
        title: "Reset this page"

        SettingsButton {
            label: root.armed ? "Tap again to reset" : "Reset"
            primary: root.armed
            enabled: root.changedCount > 0
            onClicked: {
                if (!root.armed) {
                    root.armed = true;
                    confirmTimer.restart();
                    return;
                }
                confirmTimer.stop();
                root.armed = false;
                root.confirmed();
            }
        }
    }

    SettingsNote {
        width: root.width
        text: root.changedCount > 0
            ? "Sets " + root.changedCount + (root.changedCount === 1 ? " option" : " options")
              + " on this page back to default. Nothing is saved until you Apply."
            : "Everything on this page is already at its default."
    }
}
