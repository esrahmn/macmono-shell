import QtQuick
import QtQuick.Shapes
import "../../../core"
import "../../../shared/components"

Column {
    id: root
    spacing: 0

    readonly property var freqs: Sys.eq.freqs
    readonly property int n: freqs.length
    readonly property real range: 12
    readonly property real stepDb: 0.5

    readonly property var presets: [
        { label: "Flat",            gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { label: "Bass boost",      gains: [5, 4.5, 3.5, 1.5, 0, 0, 0, 0, 0, 0] },
        { label: "Vocal",           gains: [-2, -2, -1, 0, 1.5, 3, 3.5, 2.5, 0, -1] },
        { label: "Treble boost",    gains: [0, 0, 0, 0, 0, 0, 1.5, 3, 4.5, 5] },
        { label: "Laptop speakers", gains: [-6, -4, 0, 1.5, 2, 1, 1.5, 2.5, 3, 2] }
    ]

    property var gains: normalized(Settings.eqBands)
    property bool dragging: false

    readonly property bool isCustom: !presets.some(pr => sameAs(pr.gains))
    property var customGains: null
    Component.onCompleted: if (isCustom) customGains = gains.slice()

    function normalized(list) {
        const out = [];
        for (let i = 0; i < n; i++) out.push(Number(list && list[i] !== undefined ? list[i] : 0));
        return out;
    }
    Connections {
        target: Settings
        function onEqBandsChanged() { if (!root.dragging) root.gains = root.normalized(Settings.eqBands); }
    }

    function sameAs(list) {
        for (let i = 0; i < n; i++) if (Math.abs(gains[i] - list[i]) > 0.001) return false;
        return true;
    }
    function setBand(i, v) {
        const g = gains.slice();
        g[i] = v;
        gains = g;
    }
    function commit(list) {
        gains = list.slice();
        SettingsStore.apply({ eqBands: gains }, []);
        if (Settings.eqEnabled) Sys.eq.apply(true, gains);
        if (isCustom) customGains = gains.slice();
    }
    function pickPreset(list) {
        if (isCustom) customGains = gains.slice();
        commit(list);
    }
    function setEnabled(v) {
        SettingsStore.apply({ eqEnabled: v }, []);
        Sys.eq.apply(v, gains);
    }
    function fmtDb(v) {
        if (v === 0) return "0";
        return (v > 0 ? "+" : "−") + (Math.abs(v) % 1 === 0 ? String(Math.abs(v)) : Math.abs(v).toFixed(1));
    }
    function fmtHz(f) { return f >= 1000 ? (f / 1000) + "k" : String(f); }

    function responseDb(f) {
        const fs = 48000;
        const w = 2 * Math.PI * f / fs;
        const c1 = Math.cos(w), s1 = Math.sin(w), c2 = Math.cos(2 * w), s2 = Math.sin(2 * w);
        let db = 0;
        for (let i = 0; i < n; i++) {
            const g = gains[i];
            if (g === 0) continue;
            const A = Math.pow(10, g / 40);
            const w0 = 2 * Math.PI * freqs[i] / fs;
            const alpha = Math.sin(w0) / (2 * Sys.eq.q);
            const b0 = 1 + alpha * A, b1 = -2 * Math.cos(w0), b2 = 1 - alpha * A;
            const a0 = 1 + alpha / A, a1 = b1, a2 = 1 - alpha / A;
            const nr = b0 + b1 * c1 + b2 * c2, ni = -(b1 * s1 + b2 * s2);
            const dr = a0 + a1 * c1 + a2 * c2, di = -(a1 * s1 + a2 * s2);
            db += 10 * Math.log10((nr * nr + ni * ni) / (dr * dr + di * di));
        }
        return db;
    }
    function curvePath(w, h) {
        if (w <= 0 || h <= 0) return "";
        const N = 96, f0 = freqs[0] / Math.SQRT2;
        let d = "";
        for (let k = 0; k < N; k++) {
            const x = k / (N - 1) * w;
            const db = Math.max(-range, Math.min(range, responseDb(f0 * Math.pow(2, k / (N - 1) * n))));
            d += (k === 0 ? "M" : "L") + x.toFixed(1) + " " + (h / 2 - db / range * (h / 2)).toFixed(1);
        }
        return d;
    }
    function areaPath(w, h) {
        const c = curvePath(w, h);
        return c === "" ? "" : c + "L" + w.toFixed(1) + " " + (h / 2).toFixed(1) + "L0 " + (h / 2).toFixed(1) + "Z";
    }

    component SectionLabel: SettingsText {
        property bool first: false
        topPadding: first ? 0 : Theme.settingsGroupSpacing
        bottomPadding: Theme.space8
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }

    Rectangle {
        id: hero
        width: root.width
        height: heroText.height + Theme.settingsRowPadY * 2
        radius: Theme.radiusCard
        color: heroArea.containsMouse ? Theme.tileHover : Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        Behavior on color { ColorAnimation { duration: Theme.animHover } }

        readonly property bool failed: Settings.eqEnabled && !Sys.eq.ok
        readonly property string statusText: !Settings.eqEnabled
            ? "Off. Turning on replaces the output preset loaded in Easy Effects."
            : (Sys.eq.status !== "" ? Sys.eq.status : "On. Using Easy Effects.")

        MouseArea {
            id: heroArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setEnabled(!Settings.eqEnabled)
        }

        Column {
            id: heroText
            x: Theme.settingsRowPadX
            y: Theme.settingsRowPadY
            width: parent.width - Theme.settingsRowPadX * 2 - heroToggle.width - Theme.space18
            spacing: Theme.space3
            SettingsText {
                text: "Enable equalizer"
                font.pixelSize: Theme.fontHeading
                font.weight: Font.Medium
                font.letterSpacing: Theme.settingsRowTracking
            }
            SettingsText {
                width: parent.width
                wrapMode: Text.Wrap
                text: hero.statusText
                color: hero.failed ? Theme.text : Theme.settingsDescText
                font.pixelSize: Theme.fontBody
            }
        }

        SettingsToggle {
            id: heroToggle
            anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
            checked: Settings.eqEnabled
            onToggled: (v) => root.setEnabled(v)
        }
    }

    SectionLabel { text: "PRESET" }

    Item {
        width: root.width
        height: presetFlow.height

        Flow {
            id: presetFlow
            x: Theme.settingsRowPadX
            width: parent.width - Theme.settingsRowPadX * 2
            spacing: Theme.space6

            Repeater {
                model: root.presets
                delegate: SettingsChoice {
                    required property var modelData
                    label: modelData.label
                    on: root.sameAs(modelData.gains)
                    onPicked: root.pickPreset(modelData.gains)
                }
            }

            SettingsChoice {
                visible: root.isCustom || root.customGains !== null
                label: "Custom"
                on: root.isCustom
                onPicked: if (!root.isCustom && root.customGains) root.commit(root.customGains)
            }
        }
    }

    SectionLabel { text: "BANDS" }

    Rectangle {
        id: card
        width: root.width
        height: body.height + Theme.space16 * 2
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        opacity: Settings.eqEnabled ? 1 : Theme.settingsEqOffOpacity
        Behavior on opacity { NumberAnimation { duration: Theme.animBase } }

        readonly property real axisW: Theme.settingsEqAxisW
        readonly property real plotW: width - Theme.space16 * 2 - axisW
        readonly property real cw: plotW / root.n

        Column {
            id: body
            x: Theme.space16
            y: Theme.space16
            width: parent.width - Theme.space16 * 2
            spacing: Theme.space8

            Item {
                id: plot
                width: parent.width
                height: Theme.settingsEqPlotHeight

                Repeater {
                    model: [12, 6, 0, -6, -12]
                    delegate: Rectangle {
                        required property int modelData
                        x: card.axisW
                        width: card.plotW
                        height: Theme.borderThin
                        y: plot.height / 2 - modelData / root.range * (plot.height / 2)
                        color: modelData === 0 ? Theme.lineStrong : Theme.line
                    }
                }
                Repeater {
                    model: [12, 0, -12]
                    delegate: SettingsText {
                        required property int modelData
                        width: card.axisW - Theme.space8
                        horizontalAlignment: Text.AlignRight
                        y: plot.height / 2 - modelData / root.range * (plot.height / 2) - height / 2
                        text: root.fmtDb(modelData)
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                        font.features: ({ "tnum": 1 })
                    }
                }

                Shape {
                    x: card.axisW
                    width: card.plotW
                    height: plot.height
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: Theme.transparent
                        fillColor: Theme.tile
                        PathSvg { path: root.areaPath(card.plotW, plot.height) }
                    }
                    ShapePath {
                        strokeColor: Theme.text
                        strokeWidth: Theme.borderStrong
                        fillColor: Theme.transparent
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: root.curvePath(card.plotW, plot.height) }
                    }
                }
            }

            Row {
                x: card.axisW
                Repeater {
                    model: root.n
                    delegate: SettingsText {
                        required property int index
                        width: card.cw
                        horizontalAlignment: Text.AlignHCenter
                        text: root.fmtDb(root.gains[index])
                        color: root.gains[index] === 0 ? Theme.dim : Theme.text
                        font.pixelSize: Theme.fontSmall
                        font.features: ({ "tnum": 1 })
                    }
                }
            }

            Row {
                x: card.axisW
                Repeater {
                    model: root.n
                    delegate: Item {
                        id: band
                        required property int index
                        readonly property real padV: Theme.settingsEqBandPad
                        readonly property real railH: height - padV * 2
                        readonly property real g: root.gains[index]
                        function yFor(v) { return padV + (root.range - v) / (2 * root.range) * railH; }

                        width: card.cw
                        height: Theme.settingsEqBandHeight

                        Rectangle {
                            id: rail
                            x: (parent.width - width) / 2
                            y: band.padV
                            width: Theme.settingsSliderTrack
                            height: band.railH
                            radius: width / 2
                            color: Theme.tileHover
                        }
                        Rectangle {
                            x: (parent.width - width) / 2
                            y: band.yFor(0)
                            width: Theme.settingsEqTick
                            height: Theme.borderThin
                            color: Theme.lineStrong
                        }
                        Rectangle {
                            x: rail.x
                            width: rail.width
                            radius: width / 2
                            y: Math.min(band.yFor(0), band.yFor(band.g))
                            height: Math.abs(band.yFor(0) - band.yFor(band.g))
                            color: Theme.inverse
                        }
                        Rectangle {
                            id: knob
                            width: Theme.settingsEqKnob
                            height: width
                            radius: width / 2
                            x: (parent.width - width) / 2
                            y: band.yFor(band.g) - height / 2
                            color: Theme.inverse
                            scale: area.pressed ? Theme.settingsSliderKnobPressed : 1
                            Behavior on scale { NumberAnimation { duration: Theme.animPress } }
                        }

                        Accessible.role: Accessible.Slider
                        Accessible.name: root.fmtHz(root.freqs[band.index]) + " Hz " + root.fmtDb(band.g) + " dB"

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            cursorShape: Qt.SizeVerCursor
                            function setFromY(y) {
                                const t = Math.max(0, Math.min(1, (y - band.padV) / band.railH));
                                const raw = root.range - t * 2 * root.range;
                                root.setBand(band.index, Math.max(-root.range, Math.min(root.range, Math.round(raw / root.stepDb) * root.stepDb)));
                            }
                            onPressed: (m) => { root.dragging = true; setFromY(m.y); }
                            onPositionChanged: (m) => { if (pressed) setFromY(m.y); }
                            onReleased: { root.dragging = false; root.commit(root.gains); }
                            onCanceled: { root.dragging = false; root.commit(root.gains); }
                            onDoubleClicked: { root.setBand(band.index, 0); root.dragging = false; root.commit(root.gains); }
                        }
                    }
                }
            }

            Row {
                SettingsText {
                    width: card.axisW
                    rightPadding: Theme.space8
                    horizontalAlignment: Text.AlignRight
                    text: "Hz"
                    color: Theme.dim
                    font.pixelSize: Theme.fontSmall
                }
                Repeater {
                    model: root.n
                    delegate: SettingsText {
                        required property int index
                        width: card.cw
                        horizontalAlignment: Text.AlignHCenter
                        text: root.fmtHz(root.freqs[index])
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
