import QtQuick
import Quickshell
import "../../../core"
import "../../../shared/components"

// Halaman Apps & Startup: aplikasi yang dijalankan saat login (XDG autostart lewat dex).
// Semua state berasal dari file .desktop di /etc/xdg/autostart dan ~/.config/autostart;
// mengubahnya langsung menulis ke file yang sama (lihat shared/services/AutostartService.qml),
// jadi berlaku pada login berikutnya — tidak perlu menyalin apa pun ke settings.json.
//
// Susunan halaman:
//   STARTUP APPLICATIONS  + tombol "+ Add" (picker aplikasi terpasang, satu baris satu maksud)
//   NOT USED ON HYPRLAND  diciutkan secara bawaan: entri khusus KDE/GNOME yang memang tidak jalan di sini,
//                         jadi tidak perlu menandai tiap barisnya (dulu 8 dari 14 baris bertanda sama).
// Baris memakai SettingsRow: nama entri + toggle. Perintah Exec tidak digambar (R5).
Column {
    id: root
    readonly property var svc: Sys.autostart
    spacing: 0   // jarak antar grup diatur komponen di bawah, bukan Column (kalau tidak, tiap baris ikut renggang)

    property bool adding: false       // picker "+ Add" terbuka
    property bool showInert: false    // grup "Not used on Hyprland" terbuka

    readonly property var liveEntries: svc.entries.filter(e => e.relevant !== false)
    readonly property var inertEntries: svc.entries.filter(e => e.relevant === false)

    // Aplikasi terpasang yang belum ada di daftar, disaring oleh kolom cari. Dihitung hanya saat picker terbuka.
    readonly property var matches: {
        if (!adding) return [];
        const have = ({});
        for (const e of svc.entries) have[svc.baseName(e.userPath !== "" ? e.userPath : e.systemPath)] = true;
        const q = field.text.trim().toLowerCase();
        const out = [];
        for (const a of DesktopEntries.applications.values) {
            if (a.noDisplay || have[a.id + ".desktop"]) continue;
            if (q !== "" && !(a.name.toLowerCase().includes(q) || a.id.toLowerCase().includes(q))) continue;
            out.push(a);
        }
        out.sort((x, y) => {
            const m = x.name.toLowerCase(), n = y.name.toLowerCase();
            return m < n ? -1 : (m > n ? 1 : 0);
        });
        return out.slice(0, Theme.settingsPickMax);
    }

    // Entri lama punya akhiran "(disabled by macmono)" di Name; toggle sudah menunjukkan keadaannya.
    function label(n) { return String(n).replace(/\s*\(disabled by macmono\)\s*$/i, ""); }
    function add(entry) { svc.addApp(entry.id); adding = false; }

    onVisibleChanged: { if (visible) svc.refresh(); else adding = false; }
    onAddingChanged: if (adding) { field.text = ""; Qt.callLater(() => field.forceActiveFocus()); }
    Component.onCompleted: svc.refresh()

    // Label KAPITAL renggang, sama dengan label grup di halaman lain.
    component CapsLabel: SettingsText {
        leftPadding: Theme.settingsRowPadX
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
    }

    // Keterangan kecil di bawah judul grup.
    component Note: SettingsText {
        width: root.width
        topPadding: Theme.space8
        bottomPadding: Theme.space4
        leftPadding: Theme.settingsRowPadX
        rightPadding: Theme.settingsRowPadX
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.pixelSize: Theme.fontBody
    }

    // Satu entri autostart. "Reset" = hapus penimpaan user (kembali ke versi sistem);
    // "Remove" = entri buatan sendiri (tidak punya versi sistem), filenya dihapus.
    component EntryRow: SettingsRow {
        id: entryRow
        required property var modelData
        required property int index

        width: root.width
        title: root.label(modelData.name)
        separator: index > 0
        resettable: modelData.removable === true
        resetLabel: modelData.systemPath === "" ? "Remove" : "Reset"
        onResetRequested: root.svc.removeUserEntry(modelData)
        opacity: modelData.relevant === false ? Theme.opacityDim : 1

        SettingsToggle {
            checked: entryRow.modelData.enabled
            onToggled: (v) => root.svc.setEnabled(entryRow.modelData, v)
        }
    }

    // ---- judul grup + tombol tambah ----
    Item {
        width: root.width
        height: Theme.settingsButtonHeight

        CapsLabel {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "STARTUP APPLICATIONS"
        }
        SettingsButton {
            anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
            label: root.adding ? "Close" : "+ Add"
            onClicked: root.adding = !root.adding
        }
    }

    // ---- picker: cari aplikasi terpasang, ketuk untuk menambah ----
    Column {
        visible: root.adding
        width: root.width
        spacing: Theme.space6
        topPadding: Theme.space8

        Rectangle {
            width: parent.width
            height: Theme.settingsSearchHeight
            radius: Theme.radiusCard
            color: Theme.tile
            border.width: Theme.borderThin
            border.color: field.activeFocus ? Theme.lineStrong : Theme.cardStroke
            TextInput {
                id: field
                anchors { fill: parent; leftMargin: Theme.settingsRowPadX; rightMargin: Theme.settingsRowPadX }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontBodyLg
                selectionColor: Theme.selection
                selectedTextColor: Theme.text
                clip: true
                onAccepted: if (root.matches.length > 0) root.add(root.matches[0])
                Keys.onEscapePressed: (event) => {
                    if (text !== "") { text = ""; event.accepted = true; }
                    else if (root.adding) { root.adding = false; event.accepted = true; }
                    else event.accepted = false;
                }
                SettingsText {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !field.text
                    text: "Search installed apps"
                    color: Theme.muted
                }
            }
        }

        Repeater {
            model: root.matches
            delegate: Rectangle {
                id: res
                required property var modelData
                width: parent.width
                height: Theme.settingsListRowHeight
                radius: Theme.radiusCard
                color: resArea.containsMouse ? Theme.tileHover : Theme.tile
                border.width: Theme.borderThin
                border.color: Theme.cardStroke
                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                SettingsText {
                    anchors { fill: parent; leftMargin: Theme.settingsRowPadX; rightMargin: Theme.settingsRowPadX }
                    verticalAlignment: Text.AlignVCenter
                    text: res.modelData.name
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: resArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.add(res.modelData)
                }
            }
        }

        SettingsText {
            visible: root.matches.length === 0
            leftPadding: Theme.settingsRowPadX
            text: field.text.trim() === "" ? "No other apps found." : "No apps match."
            color: Theme.dim
        }
    }

    Note { text: "Start automatically when you log in. Changes apply the next time you log in." }

    SettingsText {
        visible: root.svc.error !== ""
        width: root.width
        leftPadding: Theme.settingsRowPadX
        rightPadding: Theme.settingsRowPadX
        topPadding: Theme.space4
        wrapMode: Text.WordWrap
        text: root.svc.error
        font.pixelSize: Theme.fontBody
    }

    SettingsText {
        visible: root.liveEntries.length === 0
        width: root.width
        leftPadding: Theme.settingsRowPadX
        topPadding: Theme.space8
        text: (root.svc.loading && root.svc.entries.length === 0) ? "Reading startup entries…" : "No startup applications for Hyprland yet."
        color: Theme.dim
    }

    Repeater {
        model: root.liveEntries
        delegate: EntryRow {}
    }

    // ---- grup yang jarang dipakai: entri yang tidak jalan di Hyprland (ciut bawaan) ----
    Item {
        visible: root.inertEntries.length > 0
        width: root.width
        height: visible ? Theme.settingsGroupSpacing + Theme.settingsListRowHeight : 0

        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Theme.settingsListRowHeight

            CapsLabel {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "NOT USED ON HYPRLAND  ·  " + root.inertEntries.length
                color: inertArea.containsMouse ? Theme.text : Theme.labelCapsText
            }
            Glyph {
                anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
                width: Theme.icon13
                height: Theme.icon13
                name: "chevron"
                color: Theme.dim
                rotation: root.showInert ? 0 : -90
                Behavior on rotation { NumberAnimation { duration: Theme.animHover } }
            }
            MouseArea {
                id: inertArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showInert = !root.showInert
            }
        }
    }

    Note {
        visible: root.showInert && root.inertEntries.length > 0
        text: "These only start on other desktops, so they do nothing here."
    }

    Repeater {
        model: root.showInert ? root.inertEntries : []
        delegate: EntryRow {}
    }
}
