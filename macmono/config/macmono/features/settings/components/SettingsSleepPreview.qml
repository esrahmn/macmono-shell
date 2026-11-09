import QtQuick
import "../../../core"

// Pratinjau grup "Screen & sleep" (halaman Power): kapan layar terkunci, mati, dan komputer tidur
// kalau lu diam saja. Dibaca dari draft (belum di-Apply), jadi geser slider langsung terlihat di sini.
// Dipasang tepat di atas slider-nya lewat `preview: "sleep"` di SettingsSchema (bukan di level halaman).
Rectangle {
    id: root
    property int lockMin: 5
    property int offMin: 10
    property int suspendMin: 15

    readonly property var events: {
        const all = [
            { label: "Lock", m: lockMin },
            { label: "Screen off", m: offMin },
            { label: "Sleep", m: suspendMin }
        ].filter(e => e.m > 0);
        all.sort((a, b) => a.m - b.m);
        return all;
    }
    readonly property real axisMax: Math.max(15, events.length ? events[events.length - 1].m : 0)

    height: tlBody.height + Theme.settingsRowPadY * 2
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    Item {
        id: tlBody
        x: Theme.settingsRowPadX
        y: Theme.settingsRowPadY
        width: root.width - Theme.settingsRowPadX * 2
        height: root.events.length === 0 ? emptyText.height
                : Theme.settingsMarkSize + Theme.space4 + (root.events.length > 1 ? Theme.fontBody * 2 + Theme.space6 : Theme.fontBody) + Theme.space4

        SettingsText {
            id: emptyText
            visible: root.events.length === 0
            width: parent.width
            text: "Nothing happens automatically. The screen stays on and the computer never sleeps."
            color: Theme.settingsDescText
            font.pixelSize: Theme.fontBody
            wrapMode: Text.Wrap
        }

        Item {
            visible: root.events.length > 0
            anchors.fill: parent
            readonly property real trackW: width - Theme.settingsMarkSize

            // rel
            Rectangle {
                x: Theme.settingsMarkSize / 2
                y: Theme.settingsMarkSize / 2 - height / 2
                width: parent.trackW
                height: Theme.settingsSliderTrack
                radius: height / 2
                color: Theme.tileHover
            }
            // titik awal: "sekarang"
            Rectangle { x: 0; y: 0; width: Theme.settingsMarkSize; height: width; radius: width / 2; color: Theme.dim }
            SettingsText { x: 0; y: Theme.settingsMarkSize + Theme.space4; text: "Idle"; color: Theme.dim; font.pixelSize: Theme.fontCaption }

            Repeater {
                model: root.events
                delegate: Item {
                    id: ev
                    required property var modelData
                    required property int index
                    readonly property real cx: Theme.settingsMarkSize / 2 + parent.trackW * (modelData.m / root.axisMax)
                    Rectangle {
                        x: ev.cx - width / 2
                        y: 0
                        width: Theme.settingsMarkSize
                        height: width
                        radius: width / 2
                        color: Theme.text
                    }
                    SettingsText {
                        // dua baris label bergantian supaya titik yang berdekatan tidak saling tindih
                        x: Math.max(0, Math.min(ev.parent.width - width, ev.cx - width / 2))
                        y: Theme.settingsMarkSize + Theme.space4 + (ev.index % 2) * (Theme.fontBody + Theme.space6)
                        text: ev.modelData.label + " · " + ev.modelData.m + " min"
                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }
    }
}
