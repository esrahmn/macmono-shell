import QtQuick
import "../core"

// Progres buka/tutup panel (0..1): SATU gerakan untuk semua panel laci
// (control center, kalender, media, tray menu, launcher, clipboard, emoji).
//
// Pegas fisik bermassa 1, diintegrasikan tiap frame (pola Spring.qml di IridumShell):
//     a = -k (x - target) - c v,    c = 2 ζ √k
// Redaman kritis (ζ = 1): mulus, mulai pelan lalu melambat halus, tanpa pantulan.
// Buka lebih lembut dari tutup. Kalau dibalik di tengah jalan (buka lalu langsung tutup),
// kecepatannya dipertahankan, jadi nggak ada loncatan.
//
// Pakai:
//     Reveal { id: rv; open: win.shown }
//     visible: rv.present          // window perlu tampil selama buka, terbuka, atau masih menutup
//     ... rv.progress ...          // 0 = tertutup, 1 = terbuka
// Kekakuan & redaman diatur di Theme (revealOpenStiff / revealCloseStiff / revealDamp).
Item {
    id: root
    visible: false

    property bool open: false

    property real value: 0       // posisi pegas mentah
    property real velocity: 0
    readonly property real progress: Math.max(0, Math.min(1, value))
    // Ekor pegas kecil banget (<0.6%) sudah nggak kelihatan; window dilepas lebih awal.
    readonly property bool present: open || value > 0.006

    onOpenChanged: frames.running = true

    FrameAnimation {
        id: frames
        onTriggered: {
            const target = root.open ? 1 : 0;
            const k = root.open ? Theme.revealOpenStiff : Theme.revealCloseStiff;
            const c = 2 * Theme.revealDamp * Math.sqrt(k);
            // sub-step kecil supaya integrasinya stabil walau ada frame yang telat
            const dt = Math.min(frameTime, 0.05);
            const n = Math.max(1, Math.ceil(dt / 0.003));
            const h = dt / n;
            let x = root.value, v = root.velocity;
            for (let i = 0; i < n; i++) {
                v += (-k * (x - target) - c * v) * h;
                x += v * h;
            }
            if (Math.abs(x - target) < 0.001 && Math.abs(v) < 0.01) {
                x = target; v = 0;
                running = false;
            }
            root.value = x;
            root.velocity = v;
        }
    }
}
