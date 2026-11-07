import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"

// Pemilih area screenshot:
//  1. grim ngambil layar penuh dulu (Sys.startCapture) -> panel yang kebuka ikut kerekam
//  2. gambar beku ditampilkan di sini, user drag area / klik window / klik panel
//  3. hasil di-crop dari gambar beku pakai magick (Sys.finishCapture)
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: Sys.capturing && Sys.captureScreen === modelData.name
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.black
            WlrLayershell.namespace: "macmono:selector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property real monScale: Hyprland.monitorFor(modelData)?.scale ?? 1

            // ---------------- target klik: panel macmono & window di workspace aktif ----------------
            readonly property var targets: {
                const t = Sys.captureTargets;
                const mon = (t.monitors || []).find(m => m.name === modelData.name);
                if (!mon) return [];
                const mw = mon.width / mon.scale, mh = mon.height / mon.scale;
                const out = [];

                // layer top & overlay (control center, menubar, notifikasi, dll)
                const levels = t.layers?.[mon.name]?.levels ?? {};
                for (const lv of ["3", "2"]) {
                    for (const l of (levels[lv] || [])) {
                        if (l.namespace === "macmono:selector") continue;
                        if (l.w >= mw - 1 && l.h >= mh - 1) continue;   // layer fullscreen (launcher/picker) dilewati
                        if (l.w < 8 || l.h < 8) continue;
                        out.push({ x: l.x - mon.x, y: l.y - mon.y, w: l.w, h: l.h });
                    }
                }

                // window: yang floating & paling baru difokus duluan
                const wsIds = [mon.activeWorkspace?.id, mon.specialWorkspace?.id].filter(i => i);
                const clients = (t.clients || [])
                    .filter(c => c.mapped && !c.hidden && wsIds.includes(c.workspace?.id))
                    .sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID));
                for (const c of clients)
                    out.push({ x: c.at[0] - mon.x, y: c.at[1] - mon.y, w: c.size[0], h: c.size[1] });
                return out;
            }

            function targetAt(px, py) {
                for (const r of targets)
                    if (px >= r.x && px <= r.x + r.w && py >= r.y && py <= r.y + r.h) return r;
                return null;
            }

            // ---------------- state seleksi ----------------
            property bool dragging: false
            property real sx: 0
            property real sy: 0
            property real ex: 0
            property real ey: 0
            property var hovered: null
            readonly property bool dragged: Math.abs(ex - sx) > 4 || Math.abs(ey - sy) > 4

            // kotak yang lagi disorot: hasil drag, atau window/panel di bawah kursor
            readonly property var sel: (dragging && dragged)
                ? { x: Math.min(sx, ex), y: Math.min(sy, ey), w: Math.abs(ex - sx), h: Math.abs(ey - sy) }
                : hovered

            function commit(r) {
                // clamp ke layar, lalu ubah ke piksel fisik
                const x = Math.max(0, r.x), y = Math.max(0, r.y);
                const w = Math.min(width - x, r.w - (x - r.x)), h = Math.min(height - y, r.h - (y - r.y));
                Sys.finishCapture(x * monScale, y * monScale, w * monScale, h * monScale);
            }

            onVisibleChanged: {
                if (visible) {
                    dragging = false; hovered = null;
                    keys.forceActiveFocus();
                }
            }

            // gambar beku
            Image {
                anchors.fill: parent
                source: win.visible ? "file://" + Sys.captureFile : ""
                cache: false
                asynchronous: false
                fillMode: Image.Stretch
            }

            // peredup di luar seleksi (4 kotak di sekeliling)
            Item {
                anchors.fill: parent
                readonly property color shade: Theme.scrim
                readonly property var r: win.sel ?? { x: 0, y: 0, w: 0, h: 0 }
                Rectangle { color: parent.shade; x: 0; y: 0; width: parent.width; height: win.sel ? parent.r.y : parent.height }
                Rectangle { visible: !!win.sel; color: parent.shade; x: 0; y: parent.r.y + parent.r.h; width: parent.width; height: parent.height - y }
                Rectangle { visible: !!win.sel; color: parent.shade; x: 0; y: parent.r.y; width: parent.r.x; height: parent.r.h }
                Rectangle { visible: !!win.sel; color: parent.shade; x: parent.r.x + parent.r.w; y: parent.r.y; width: parent.width - x; height: parent.r.h }
            }

            // bingkai seleksi + ukuran
            Rectangle {
                visible: !!win.sel
                x: (win.sel?.x ?? 0) - 1
                y: (win.sel?.y ?? 0) - 1
                width: (win.sel?.w ?? 0) + 2
                height: (win.sel?.h ?? 0) + 2
                color: Theme.transparent
                radius: Theme.radiusIndicator
                border.width: Theme.borderStrong
                border.color: Theme.text

                Rectangle {
                    readonly property bool below: parent.y + parent.height + 34 < win.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: below ? parent.height + 8 : -height - 8
                    width: sizeText.implicitWidth + 16
                    height: Theme.selectorBadgeHeight
                    radius: Math.min(width, height) / 2
                    color: Theme.badge
                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: Math.round((win.sel?.w ?? 0) * win.monScale) + " × " + Math.round((win.sel?.h ?? 0) * win.monScale)
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                    }
                }
            }

            // petunjuk di bawah
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.space30 }
                visible: !win.dragging
                width: hint.implicitWidth + 28
                height: Theme.selectorHintHeight
                radius: Math.min(width, height) / 2
                color: Theme.badge
                border.width: Theme.borderThin
                border.color: Theme.line
                Text {
                    id: hint
                    anchors.centerIn: parent
                    text: (Sys.captureMode === "ocr" ? "OCR · " : "") + "Drag untuk pilih area  ·  Klik window/panel  ·  Klik kosong = layar penuh  ·  Esc batal"
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                }
            }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) { Sys.cancelCapture(); e.accepted = true; }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        win.commit({ x: 0, y: 0, w: win.width, h: win.height }); e.accepted = true;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPositionChanged: (m) => {
                    if (win.dragging) { win.ex = m.x; win.ey = m.y; }
                    else win.hovered = win.targetAt(m.x, m.y);
                }
                onPressed: (m) => {
                    if (m.button === Qt.RightButton) { Sys.cancelCapture(); return; }
                    win.sx = win.ex = m.x;
                    win.sy = win.ey = m.y;
                    win.dragging = true;
                }
                onReleased: (m) => {
                    if (m.button !== Qt.LeftButton || !win.dragging) return;
                    win.dragging = false;
                    if (win.dragged)
                        win.commit({ x: Math.min(win.sx, win.ex), y: Math.min(win.sy, win.ey), w: Math.abs(win.ex - win.sx), h: Math.abs(win.ey - win.sy) });
                    else
                        win.commit(win.targetAt(m.x, m.y) ?? { x: 0, y: 0, w: win.width, h: win.height });
                }
            }
        }
    }
}
