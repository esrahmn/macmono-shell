import QtQuick
import "../../core"

Canvas {
    id: root
    property string name: ""
    property color color: Theme.text
    property real thickness: 1.8
    property bool customReady: false

    function ensureCustomImage() {
        if (customReady)
            return;
        const candidates = [
            "image://theme/custom",
            Qt.resolvedUrl("../assets/custom.png"),
            Qt.resolvedUrl("../assets/custom.png")
        ];
        for (let i = 0; i < candidates.length; i++) {
            if (root.loadImage(candidates[i])) {
                customReady = true;
                break;
            }
        }
    }

    onImageLoaded: requestPaint()

    implicitWidth: Theme.iconMd
    implicitHeight: Theme.iconMd

    onNameChanged: {
        if (name === "enso")
            ensureCustomImage();
        requestPaint();
    }
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: if (name === "enso") ensureCustomImage()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const s = Math.min(width, height) / 24;
        ctx.scale(s, s);
        const c = root.color;
        const css = "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")";
        ctx.strokeStyle = css;
        ctx.fillStyle = css;
        ctx.lineWidth = root.thickness;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        const PI = Math.PI;

        const cloudPath = () => {
            ctx.beginPath();
            ctx.moveTo(7, 18);
            ctx.arc(7, 14, 4, PI / 2, PI * 1.5);
            ctx.arc(12, 9, 5, 2.945, 2 * PI);
            ctx.lineTo(17, 10);
            ctx.arc(17, 14, 4, -PI / 2, PI / 2);
            ctx.closePath();
        };
        const drawCloud = (tx, ty, k, knock) => {
            ctx.save();
            ctx.translate(tx, ty);
            ctx.scale(k, k);
            if (knock) {
                ctx.globalCompositeOperation = "destination-out";
                ctx.lineWidth = (root.thickness + 2.2) / k;
                cloudPath(); ctx.fill(); ctx.stroke();
                ctx.globalCompositeOperation = "source-over";
            }
            ctx.lineWidth = root.thickness / k;
            cloudPath(); ctx.stroke();
            ctx.restore();
        };
        switch (root.name) {
        case "volume":
        case "volume-low":
        case "volume-zero":
        case "mute":
            ctx.beginPath();
            ctx.moveTo(3, 9); ctx.lineTo(7, 9); ctx.lineTo(12, 5); ctx.lineTo(12, 19); ctx.lineTo(7, 15); ctx.lineTo(3, 15);
            ctx.closePath();
            ctx.fill();
            if (root.name !== "mute") {
                if (root.name !== "volume-zero") { ctx.beginPath(); ctx.arc(12, 12, 5, -0.9, 0.9); ctx.stroke(); }
                if (root.name === "volume") { ctx.beginPath(); ctx.arc(12, 12, 9, -0.9, 0.9); ctx.stroke(); }
            } else {
                ctx.beginPath();
                ctx.moveTo(16, 9); ctx.lineTo(21, 15);
                ctx.moveTo(21, 9); ctx.lineTo(16, 15);
                ctx.stroke();
            }
            break;
        case "sun":
            ctx.beginPath(); ctx.arc(12, 12, 4, 0, 2 * PI); ctx.stroke();
            for (let i = 0; i < 8; i++) {
                const a = i * PI / 4;
                ctx.beginPath();
                ctx.moveTo(12 + 7.5 * Math.cos(a), 12 + 7.5 * Math.sin(a));
                ctx.lineTo(12 + 10 * Math.cos(a), 12 + 10 * Math.sin(a));
                ctx.stroke();
            }
            break;
        case "wifi":
        case "wifi-2":
        case "wifi-1":
        case "wifi-none":
        case "wifi-off": {
            const lit = root.name === "wifi" ? 3 : root.name === "wifi-2" ? 2 : root.name === "wifi-1" ? 1 : 0;
            for (let i = 1; i <= 3; i++) {
                ctx.globalAlpha = i <= lit ? 1 : 0.3;
                ctx.beginPath(); ctx.arc(12, 19, i * 4, -PI * 0.75, -PI * 0.25); ctx.stroke();
            }
            ctx.globalAlpha = lit > 0 ? 1 : 0.3;
            ctx.beginPath(); ctx.arc(12, 19, 1.4, 0, 2 * PI); ctx.fill();
            ctx.globalAlpha = 1;
            if (root.name === "wifi-off") { ctx.beginPath(); ctx.moveTo(4, 4); ctx.lineTo(20, 20); ctx.stroke(); }
            break;
        }
        case "bluetooth":
            ctx.beginPath();
            ctx.moveTo(7, 8); ctx.lineTo(17, 16); ctx.lineTo(12, 20); ctx.lineTo(12, 4); ctx.lineTo(17, 8); ctx.lineTo(7, 16);
            ctx.stroke();
            break;
        case "lock":
            ctx.beginPath();
            ctx.moveTo(8, 11); ctx.lineTo(8, 8); ctx.arc(12, 8, 4, PI, 0); ctx.lineTo(16, 11);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(7.5, 10.5); ctx.lineTo(16.5, 10.5);
            ctx.arcTo(19, 10.5, 19, 13, 2.5); ctx.lineTo(19, 18);
            ctx.arcTo(19, 20.5, 16.5, 20.5, 2.5); ctx.lineTo(7.5, 20.5);
            ctx.arcTo(5, 20.5, 5, 18, 2.5); ctx.lineTo(5, 13);
            ctx.arcTo(5, 10.5, 7.5, 10.5, 2.5);
            ctx.closePath(); ctx.fill();
            break;
        case "moon":
            ctx.beginPath(); ctx.arc(12, 12, 8, 0, 2 * PI); ctx.fill();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath(); ctx.arc(16.5, 8.5, 7, 0, 2 * PI); ctx.fill();
            break;
        case "restart":
            ctx.beginPath(); ctx.arc(12, 12, 7.5, -1.2, 4.4); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(15.5, 2.5); ctx.lineTo(15.5, 6.8); ctx.lineTo(11.2, 6.8); ctx.stroke();
            break;
        case "power":
            ctx.beginPath(); ctx.arc(12, 13, 7.5, -PI / 2 + 0.7, -PI / 2 - 0.7 + 2 * PI); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(12, 3); ctx.lineTo(12, 12); ctx.stroke();
            break;
        case "play":
            ctx.beginPath(); ctx.moveTo(8, 5); ctx.lineTo(19, 12); ctx.lineTo(8, 19); ctx.closePath(); ctx.fill();
            break;
        case "music":
            ctx.beginPath();
            ctx.moveTo(10, 5); ctx.lineTo(20, 3); ctx.lineTo(20, 15);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(7, 17, 2.5, 0, 2 * PI);
            ctx.arc(17, 15, 2.5, 0, 2 * PI);
            ctx.fill();
            break;
        case "pause":
            ctx.fillRect(6.5, 5, 4, 14);
            ctx.fillRect(13.5, 5, 4, 14);
            break;
        case "next":
            ctx.beginPath(); ctx.moveTo(5, 5); ctx.lineTo(15, 12); ctx.lineTo(5, 19); ctx.closePath(); ctx.fill();
            ctx.fillRect(17, 5, 2.5, 14);
            break;
        case "prev":
            ctx.beginPath(); ctx.moveTo(19, 5); ctx.lineTo(9, 12); ctx.lineTo(19, 19); ctx.closePath(); ctx.fill();
            ctx.fillRect(4.5, 5, 2.5, 14);
            break;
        case "bolt":
            ctx.beginPath();
            ctx.moveTo(13.5, 2); ctx.lineTo(5, 13.5); ctx.lineTo(11, 13.5); ctx.lineTo(10, 22); ctx.lineTo(19, 10); ctx.lineTo(13, 10);
            ctx.closePath(); ctx.fill();
            break;
        case "leaf":
            ctx.beginPath();
            ctx.moveTo(5, 19);
            ctx.bezierCurveTo(4, 9, 9, 4, 20, 4);
            ctx.bezierCurveTo(20, 14, 15, 20, 5, 19);
            ctx.stroke();
            ctx.beginPath(); ctx.moveTo(5, 19); ctx.quadraticCurveTo(10, 13, 17, 7); ctx.stroke();
            break;
        case "balance":
            ctx.beginPath();
            ctx.moveTo(12, 4); ctx.lineTo(12, 19);
            ctx.moveTo(7, 20); ctx.lineTo(17, 20);
            ctx.moveTo(5, 8); ctx.lineTo(19, 8);
            ctx.moveTo(7, 8); ctx.lineTo(4, 15); ctx.lineTo(10, 15); ctx.closePath();
            ctx.moveTo(17, 8); ctx.lineTo(14, 15); ctx.lineTo(20, 15); ctx.closePath();
            ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 5, 1.5, 0, 2 * PI); ctx.fill();
            break;
        case "grid":
            for (let i = 0; i < 3; i++)
                for (let j = 0; j < 3; j++)
                    ctx.fillRect(4 + i * 6.5, 4 + j * 6.5, 4.5, 4.5);
            break;
        case "sliders":
            ctx.beginPath();
            ctx.moveTo(4, 8); ctx.lineTo(20, 8);
            ctx.moveTo(4, 16); ctx.lineTo(20, 16);
            ctx.stroke();
            ctx.beginPath(); ctx.arc(9, 8, 2.6, 0, 2 * PI); ctx.fill();
            ctx.beginPath(); ctx.arc(15, 16, 2.6, 0, 2 * PI); ctx.fill();
            break;
        case "clock":
            ctx.beginPath();
            ctx.arc(12, 12, 8.25, 0, 2 * PI);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(12, 6.75); ctx.lineTo(12, 12.4); ctx.lineTo(15.6, 14.2);
            ctx.stroke();
            break;
        case "bell":
        case "bell-off":
            ctx.beginPath();
            ctx.arc(12, 10, 6, PI, 0);
            ctx.lineTo(18, 16); ctx.lineTo(19.5, 17.5); ctx.lineTo(4.5, 17.5); ctx.lineTo(6, 16);
            ctx.closePath(); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 20.5, 1.5, 0, 2 * PI); ctx.fill();
            if (root.name === "bell-off") { ctx.beginPath(); ctx.moveTo(4, 4); ctx.lineTo(20, 20); ctx.stroke(); }
            break;
        case "coffee":
            ctx.beginPath();
            ctx.moveTo(4.5, 9.5); ctx.lineTo(4.5, 15); ctx.quadraticCurveTo(4.5, 18.5, 8, 18.5);
            ctx.lineTo(12, 18.5); ctx.quadraticCurveTo(15.5, 18.5, 15.5, 15); ctx.lineTo(15.5, 9.5); ctx.closePath();
            ctx.stroke();
            ctx.beginPath(); ctx.arc(16.5, 12.5, 2.5, -PI / 2, PI / 2); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(8, 3.5); ctx.lineTo(8, 6.5); ctx.moveTo(12, 3.5); ctx.lineTo(12, 6.5); ctx.stroke();
            break;
        case "mic":
        case "mic-off":
            ctx.beginPath();
            ctx.arc(12, 8, 3.5, PI, 0); ctx.lineTo(15.5, 12); ctx.arc(12, 12, 3.5, 0, PI); ctx.closePath();
            ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 12, 6.8, 0.15, PI - 0.15); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(12, 19); ctx.lineTo(12, 22); ctx.stroke();
            if (root.name === "mic-off") { ctx.beginPath(); ctx.moveTo(4, 4); ctx.lineTo(20, 20); ctx.stroke(); }
            break;
        case "mic-fill":
            ctx.beginPath();
            ctx.arc(12, 6.5, 3.5, PI, 0); ctx.lineTo(15.5, 11.5); ctx.arc(12, 11.5, 3.5, 0, PI); ctx.closePath();
            ctx.fill();
            ctx.beginPath(); ctx.arc(12, 11.5, 6.8, 0.2, PI - 0.2); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(12, 18.3); ctx.lineTo(12, 21.5); ctx.stroke();
            break;
        case "sunhalf":
            ctx.beginPath(); ctx.arc(12, 12, 8, 0, 2 * PI); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 12, 8, PI / 2, PI * 1.5); ctx.fill();
            break;
        case "image":
            ctx.strokeRect(4, 5, 16, 14);
            ctx.beginPath(); ctx.arc(9, 10, 1.7, 0, 2 * PI); ctx.fill();
            ctx.beginPath(); ctx.moveTo(4, 17.5); ctx.lineTo(10, 12.5); ctx.lineTo(14, 16); ctx.lineTo(16.5, 13.5); ctx.lineTo(20, 17); ctx.stroke();
            break;
        case "camera":
            ctx.strokeRect(3.5, 7.5, 17, 12);
            ctx.beginPath(); ctx.moveTo(8, 7.5); ctx.lineTo(9.5, 4.5); ctx.lineTo(14.5, 4.5); ctx.lineTo(16, 7.5); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 13.5, 3.5, 0, 2 * PI); ctx.stroke();
            break;
        case "chevron":
            ctx.beginPath(); ctx.moveTo(6.5, 9.5); ctx.lineTo(12, 15); ctx.lineTo(17.5, 9.5); ctx.stroke();
            break;
        case "close":
            ctx.beginPath(); ctx.moveTo(7, 7); ctx.lineTo(17, 17); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(17, 7); ctx.lineTo(7, 17); ctx.stroke();
            break;
        case "plus":
            ctx.beginPath(); ctx.moveTo(12, 6); ctx.lineTo(12, 18); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(6, 12); ctx.lineTo(18, 12); ctx.stroke();
            break;
        case "minus":
            ctx.beginPath(); ctx.moveTo(6, 12); ctx.lineTo(18, 12); ctx.stroke();
            break;
        case "search":
            ctx.beginPath(); ctx.arc(10.5, 10.5, 6, 0, 2 * PI); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(15, 15); ctx.lineTo(20, 20); ctx.stroke();
            break;
        case "check":
            ctx.beginPath(); ctx.moveTo(5, 12.5); ctx.lineTo(10, 17.5); ctx.lineTo(19, 7); ctx.stroke();
            break;
        case "more":
            for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.arc(5.5 + i * 6.5, 12, 1.9, 0, 2 * PI); ctx.fill(); }
            break;
        case "record":
            ctx.beginPath(); ctx.arc(12, 12, 8.5, 0, 2 * PI); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 12, 4.5, 0, 2 * PI); ctx.fill();
            break;
        case "stop":
            ctx.beginPath();
            ctx.moveTo(8, 6); ctx.lineTo(16, 6); ctx.arcTo(18, 6, 18, 8, 2); ctx.lineTo(18, 16); ctx.arcTo(18, 18, 16, 18, 2);
            ctx.lineTo(8, 18); ctx.arcTo(6, 18, 6, 16, 2); ctx.lineTo(6, 8); ctx.arcTo(6, 6, 8, 6, 2);
            ctx.closePath(); ctx.fill();
            break;
        case "sleep":
            ctx.beginPath(); ctx.moveTo(6, 6); ctx.lineTo(14, 6); ctx.lineTo(6, 14); ctx.lineTo(14, 14); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(14, 12); ctx.lineTo(19, 12); ctx.lineTo(14, 19); ctx.lineTo(19, 19); ctx.stroke();
            break;
        case "calc":
            ctx.strokeRect(5, 3.5, 14, 17);
            ctx.strokeRect(7.5, 6, 9, 3.5);
            ctx.beginPath(); ctx.arc(9, 13, 0.9, 0, 2 * PI); ctx.arc(12, 13, 0.9, 0, 2 * PI); ctx.arc(15, 13, 0.9, 0, 2 * PI);
            ctx.arc(9, 17, 0.9, 0, 2 * PI); ctx.arc(12, 17, 0.9, 0, 2 * PI); ctx.arc(15, 17, 0.9, 0, 2 * PI); ctx.fill();
            break;
        case "window":
            ctx.strokeRect(3.5, 5, 17, 14);
            ctx.beginPath(); ctx.moveTo(3.5, 9); ctx.lineTo(20.5, 9); ctx.stroke();
            ctx.beginPath(); ctx.arc(6.2, 7, 0.8, 0, 2 * PI); ctx.arc(8.8, 7, 0.8, 0, 2 * PI); ctx.fill();
            break;
        case "text":
            ctx.beginPath();
            ctx.moveTo(5, 6.5); ctx.lineTo(19, 6.5);
            ctx.moveTo(5, 10.5); ctx.lineTo(19, 10.5);
            ctx.moveTo(5, 14.5); ctx.lineTo(19, 14.5);
            ctx.moveTo(5, 18.5); ctx.lineTo(13, 18.5);
            ctx.stroke();
            break;
        case "link":
            ctx.beginPath(); ctx.arc(8.5, 15.5, 3.5, 0, PI * 1.5, false); ctx.stroke();
            ctx.beginPath(); ctx.arc(15.5, 8.5, 3.5, PI, PI * 2.5, false); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(9.5, 14.5); ctx.lineTo(14.5, 9.5); ctx.stroke();
            break;
        case "trash":
            ctx.beginPath(); ctx.moveTo(4.5, 6.5); ctx.lineTo(19.5, 6.5); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(9.5, 6.5); ctx.lineTo(9.5, 4); ctx.lineTo(14.5, 4); ctx.lineTo(14.5, 6.5); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(6.5, 6.5); ctx.lineTo(7.5, 20); ctx.lineTo(16.5, 20); ctx.lineTo(17.5, 6.5); ctx.stroke();
            break;
        case "clipboard":
            ctx.strokeRect(5.5, 5, 13, 16);
            ctx.strokeRect(9, 3, 6, 3.5);
            ctx.beginPath(); ctx.moveTo(8.5, 11); ctx.lineTo(15.5, 11); ctx.moveTo(8.5, 15); ctx.lineTo(13.5, 15); ctx.stroke();
            break;
        case "logout":
            ctx.beginPath(); ctx.moveTo(10, 4.5); ctx.lineTo(5, 4.5); ctx.lineTo(5, 19.5); ctx.lineTo(10, 19.5); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(10.5, 12); ctx.lineTo(20, 12); ctx.moveTo(16.5, 8.5); ctx.lineTo(20, 12); ctx.lineTo(16.5, 15.5); ctx.stroke();
            break;

        case "enso": {
            ctx.save();
            ctx.resetTransform();
            const src = Qt.resolvedUrl("../assets/custom.png");
            if (root.isImageLoaded(src))
                ctx.drawImage(src, -1, -1, width + 3, height + 3);
            else if (root.isImageLoaded("image://theme/custom"))
                ctx.drawImage("image://theme/custom", -1, -1, width + 3, height + 3);
            ctx.restore();
            break;
        }

        case "cloud":
            drawCloud(0, 0, 1, false);
            break;
        case "cloud-sun":
        case "cloud-moon":
            if (root.name === "cloud-sun") {
                ctx.beginPath(); ctx.arc(8.5, 8.5, 3, 0, 2 * PI); ctx.stroke();
                for (let i = 0; i < 8; i++) {
                    const a = i * PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(8.5 + 5 * Math.cos(a), 8.5 + 5 * Math.sin(a));
                    ctx.lineTo(8.5 + 6.6 * Math.cos(a), 8.5 + 6.6 * Math.sin(a));
                    ctx.stroke();
                }
            } else {
                ctx.beginPath(); ctx.arc(8.5, 8.5, 5.2, 0, 2 * PI); ctx.fill();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath(); ctx.arc(11.2, 6.2, 4.4, 0, 2 * PI); ctx.fill();
                ctx.globalCompositeOperation = "source-over";
            }
            drawCloud(5, 7, 0.72, true);
            break;
        case "rain":
        case "drizzle":
        case "snow":
        case "storm":
            drawCloud(1.5, -1, 0.78, false);
            if (root.name === "rain") {
                for (let i = 0; i < 3; i++) {
                    ctx.beginPath(); ctx.moveTo(8.5 + i * 3.5, 16.5); ctx.lineTo(7.5 + i * 3.5, 20.5); ctx.stroke();
                }
            } else if (root.name === "drizzle") {
                for (let i = 0; i < 3; i++) {
                    ctx.beginPath(); ctx.moveTo(8.5 + i * 3.5, 17.5); ctx.lineTo(8 + i * 3.5, 19); ctx.stroke();
                }
            } else if (root.name === "snow") {
                for (let i = 0; i < 3; i++) {
                    ctx.beginPath(); ctx.arc(8.5 + i * 3.5, 18.5 + (i % 2) * 1.8, 1.1, 0, 2 * PI); ctx.fill();
                }
            } else {
                ctx.beginPath();
                ctx.moveTo(13, 15.5); ctx.lineTo(10, 19.2); ctx.lineTo(13.2, 19.2); ctx.lineTo(11, 22.5);
                ctx.stroke();
            }
            break;
        case "fog":
            ctx.beginPath(); ctx.moveTo(4, 8); ctx.lineTo(20, 8); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(7, 12); ctx.lineTo(22, 12); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(2, 16); ctx.lineTo(17, 16); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(6, 20); ctx.lineTo(19, 20); ctx.stroke();
            break;

        case "keyboard":
            ctx.strokeRect(3, 6.5, 18, 11);
            for (let i = 0; i < 4; i++) { ctx.beginPath(); ctx.arc(6.8 + i * 3.5, 10, 0.9, 0, 2 * PI); ctx.fill(); }
            ctx.beginPath(); ctx.moveTo(8, 14); ctx.lineTo(16, 14); ctx.stroke();
            break;
        case "monitor":
            ctx.strokeRect(3.5, 4.5, 17, 11.5);
            ctx.beginPath(); ctx.moveTo(12, 16); ctx.lineTo(12, 19.5); ctx.moveTo(8, 19.5); ctx.lineTo(16, 19.5); ctx.stroke();
            break;
        case "pin":
            ctx.beginPath();
            ctx.moveTo(12, 21);
            ctx.bezierCurveTo(12, 21, 5.5, 14.5, 5.5, 10);
            ctx.arc(12, 10, 6.5, PI, 0);
            ctx.bezierCurveTo(18.5, 14.5, 12, 21, 12, 21);
            ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 10, 2.2, 0, 2 * PI); ctx.stroke();
            break;
        case "apps":
            ctx.strokeRect(4, 4, 6.5, 6.5); ctx.strokeRect(13.5, 4, 6.5, 6.5);
            ctx.strokeRect(4, 13.5, 6.5, 6.5); ctx.strokeRect(13.5, 13.5, 6.5, 6.5);
            break;
        case "command":
            ctx.strokeRect(9, 9, 6, 6);
            for (const sx of [1, -1]) for (const sy of [1, -1]) {
                ctx.save();
                ctx.translate(12, 12); ctx.scale(sx, sy); ctx.translate(-12, -12);
                ctx.beginPath(); ctx.moveTo(9, 9); ctx.lineTo(9, 6.5); ctx.arc(6.5, 6.5, 2.5, 0, PI / 2, true); ctx.lineTo(9, 9);
                ctx.stroke();
                ctx.restore();
            }
            break;
        case "archive":
            ctx.strokeRect(4, 4.5, 16, 4.5);
            ctx.beginPath(); ctx.moveTo(5.5, 9); ctx.lineTo(5.5, 19.5); ctx.lineTo(18.5, 19.5); ctx.lineTo(18.5, 9); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(10, 13); ctx.lineTo(14, 13); ctx.stroke();
            break;

        case "eq": {
            const ex = [6, 12, 18], ek = [14.5, 8.5, 16];
            for (let i = 0; i < 3; i++) {
                ctx.beginPath();
                ctx.moveTo(ex[i], 4); ctx.lineTo(ex[i], ek[i] - 2.6);
                ctx.moveTo(ex[i], ek[i] + 2.6); ctx.lineTo(ex[i], 20);
                ctx.stroke();
                ctx.beginPath(); ctx.arc(ex[i], ek[i], 2.2, 0, 2 * PI); ctx.stroke();
            }
            break;
        }
        case "action":
            ctx.beginPath(); ctx.moveTo(13.5, 3); ctx.lineTo(5, 13.5); ctx.lineTo(11, 13.5); ctx.lineTo(10.5, 21); ctx.lineTo(19, 10.5); ctx.lineTo(13, 10.5); ctx.closePath(); ctx.stroke();
            break;
        }
    }
}
