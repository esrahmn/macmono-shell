import QtQuick
import QtQuick.Shapes
import "../../core"

// Visualizer cava gaya "gunung": area terisi halus (spline Catmull-Rom) yang menempel
// di dasar komponen. Pakai di belakang konten (popup media, menubar).
// `levels` = array 0..maxLevel dari Sys.mediaVisualizerLevels (urutan bass -> treble, tanpa mirror).
// `cornerRadius` > 0 = sudut bawah dipotong membulat supaya pas dengan kartu/pill induknya.
//
// Digambar dengan Shape (GPU, vektor), bukan Canvas: nggak ada rasterisasi bitmap + upload
// tekstur tiap frame. Shape nggak punya clip ke bentuk bebas, jadi pembulatan sudut dihitung
// langsung di path (lihat buildPath): titik dekat sudut dijepit ke lengkung sudut.
Shape {
    id: root

    property var levels: []
    property real maxLevel: 1000
    property color fillColor: Theme.text
    property real fillOpacity: 0.08
    property real cornerRadius: 0

    preferredRendererType: Shape.CurveRenderer

    function buildPath(lv, w, h, cr) {
        const n = lv.length;
        if (n < 2 || w <= 0 || h <= 0)
            return "";

        const f = v => v.toFixed(1);
        const r = Math.max(0, Math.min(cr, w / 2, h));
        // batas bawah bentuk (sudut bawah membulat) pada posisi x
        const floorY = x => {
            const e = Math.min(x, w - x);
            return e < r ? h - r + Math.sqrt(r * r - (r - e) * (r - e)) : h;
        };

        const xs = [], ys = [];
        for (let i = 0; i < n; i++) {
            xs.push(i * w / (n - 1));
            ys.push(h - Math.max(0, Math.min(root.maxLevel, lv[i])) / root.maxLevel * h);
        }

        let d = "M" + f(xs[0]) + " " + f(Math.min(ys[0], floorY(0)));
        for (let i = 0; i < n - 1; i++) {
            const a = Math.max(0, i - 1), b = Math.min(n - 1, i + 2);
            const c1x = xs[i] + (xs[i + 1] - xs[a]) / 6, c1y = ys[i] + (ys[i + 1] - ys[a]) / 6;
            const c2x = xs[i + 1] - (xs[b] - xs[i]) / 6, c2y = ys[i + 1] - (ys[b] - ys[i]) / 6;
            if (r > 0 && (xs[i] < r || xs[i + 1] > w - r)) {
                // segmen di dekat sudut: dipecah kecil, tiap titik dijepit ke lengkung sudut
                const K = 8;
                for (let k = 1; k <= K; k++) {
                    const t = k / K, u = 1 - t;
                    const x = u * u * u * xs[i] + 3 * u * u * t * c1x + 3 * u * t * t * c2x + t * t * t * xs[i + 1];
                    const y = u * u * u * ys[i] + 3 * u * u * t * c1y + 3 * u * t * t * c2y + t * t * t * ys[i + 1];
                    d += "L" + f(x) + " " + f(Math.min(y, floorY(x)));
                }
            } else {
                d += "C" + f(c1x) + " " + f(c1y) + " " + f(c2x) + " " + f(c2y)
                   + " " + f(xs[i + 1]) + " " + f(ys[i + 1]);
            }
        }
        if (r > 0) {
            d += "L" + f(w) + " " + f(h - r)
               + "A" + f(r) + " " + f(r) + " 0 0 1 " + f(w - r) + " " + f(h)
               + "L" + f(r) + " " + f(h)
               + "A" + f(r) + " " + f(r) + " 0 0 1 0 " + f(h - r);
        } else {
            d += "L" + f(w) + " " + f(h) + "L0 " + f(h);
        }
        return d + "Z";
    }

    ShapePath {
        strokeColor: "transparent"
        strokeWidth: -1
        fillColor: Qt.alpha(root.fillColor, root.fillOpacity)
        fillRule: ShapePath.WindingFill

        PathSvg {
            // levels cuma dibaca di cabang "visible": pas disembunyiin (mis. musik berhenti,
            // popup tertutup) binding ini nggak dihitung ulang tiap update cava.
            path: root.visible ? root.buildPath(root.levels, root.width, root.height, root.cornerRadius) : ""
        }
    }
}
