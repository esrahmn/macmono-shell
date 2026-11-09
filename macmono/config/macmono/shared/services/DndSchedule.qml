import QtQuick
import Quickshell

// Jadwal Do Not Disturb: menyalakan/mematikan Sys.dnd saat masuk atau keluar jendela waktu.
// Jendela boleh lewat tengah malam (1320 = 22:00 sampai 420 = 07:00).
//
// Sengaja dipolling tiap 30 detik, bukan pakai timer "sisa waktu ke batas berikutnya":
// jam bisa diubah manual, laptop bisa suspend, dan shell bisa di-restart — semua itu bikin
// hitungan sisa waktu meleset, sedangkan polling selalu mengoreksi diri. Batas jendela
// paling lambat telat 30 detik; untuk quiet hours itu cukup.
//
// Service ini tidak membaca Settings maupun Sys (biar nggak ada impor melingkar):
// Sys.qml yang menyuapkan nilainya dan menerima windowChanged.
Scope {
    id: root

    property bool enabled: false
    property int startMin: 1320      // menit sejak tengah malam: 1320 = 22:00
    property int endMin: 420         // 420 = 07:00
    property bool active: false      // true = sekarang di dalam jendela DND

    signal windowChanged(bool active)

    function clampMin(v) { return Math.max(0, Math.min(24 * 60 - 1, Math.round(Number(v) || 0))); }
    function nowMinutes() { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); }

    function inside(now, from, to) {
        const a = clampMin(from), b = clampMin(to);
        if (a === b) return false;                  // jendela nol = fitur mati, bukan 24 jam
        return a < b ? (now >= a && now < b)        // jendela biasa, mis. 13:00 -> 15:00
                     : (now >= a || now < b);       // lewat tengah malam, mis. 22:00 -> 07:00
    }

    function refresh() {
        const on = enabled && inside(nowMinutes(), startMin, endMin);
        if (on !== active) {
            active = on;
            root.windowChanged(on);
        }
    }

    onEnabledChanged: refresh()
    onStartMinChanged: refresh()
    onEndMinChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 30000
        repeat: true
        running: root.enabled
        onTriggered: root.refresh()
    }
}
