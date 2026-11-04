import QtQuick
import "../core"

// Visualizer cava gaya "gunung": area terisi halus (spline Catmull-Rom) yang menempel
// di dasar komponen. Pakai di belakang konten (popup media, menubar).
// `levels` = array 0..maxLevel dari Sys.mediaVisualizerLevels (urutan bass -> treble, tanpa mirror).
// `cornerRadius` > 0 = sudut bawah dipotong membulat supaya pas dengan kartu/pill induknya.
Canvas {
    id: root

    property var levels: []
    property real maxLevel: 1000
    property color fillColor: Theme.text
    property real fillOpacity: 0.08
    property real cornerRadius: 0

    onLevelsChanged: if (visible) requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const n = levels.length;
        const w = width, h = height;
        if (n < 2 || w <= 0 || h <= 0)
            return;

        if (cornerRadius > 0) {
            const r = Math.min(cornerRadius, w / 2, h);
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h - r);
            ctx.arcTo(w, h, w - r, h, r);
            ctx.lineTo(r, h);
            ctx.arcTo(0, h, 0, h - r, r);
            ctx.closePath();
            ctx.clip();
        }

        const xs = [], ys = [];
        for (let i = 0; i < n; i++) {
            xs.push(i * w / (n - 1));
            ys.push(h - Math.max(0, Math.min(maxLevel, levels[i])) / maxLevel * h);
        }

        ctx.beginPath();
        ctx.moveTo(0, h);
        ctx.lineTo(xs[0], ys[0]);
        for (let i = 0; i < n - 1; i++) {
            const a = Math.max(0, i - 1), b = Math.min(n - 1, i + 2);
            ctx.bezierCurveTo(
                xs[i] + (xs[i + 1] - xs[a]) / 6, ys[i] + (ys[i + 1] - ys[a]) / 6,
                xs[i + 1] - (xs[b] - xs[i]) / 6, ys[i + 1] - (ys[b] - ys[i]) / 6,
                xs[i + 1], ys[i + 1]);
        }
        ctx.lineTo(w, h);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(fillColor, fillOpacity);
        ctx.fill();
    }
}
