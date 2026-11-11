pragma Singleton

import QtQuick
import Quickshell
import "../settings"

// macmono design tokens (DESIGN.md). Three layers: scale, role, component.
// Layer 3 (component-specific sizes) lives in the component's own file, not here.
Singleton {
    // ---- Typography (DESIGN.md 4)
    readonly property string font: {
        const fams = Qt.fontFamilies();
        for (const f of ["Inter", "Inter Variable", "Inter Var", "Inter Display"])
            if (fams.indexOf(f) >= 0) return f;
        return "Inter";
    }
    readonly property string fontMono: "monospace"

    readonly property int fontXs: 11
    readonly property int fontSm: 12
    readonly property int fontMd: 14
    readonly property int fontLg: 16
    readonly property int fontXl: 22
    readonly property int font2xl: 28

    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightSemibold: Font.DemiBold

    readonly property real trackTight: -0.9   // font2xl
    readonly property real trackSnug: -0.2    // fontLg / fontXl
    readonly property real trackCaps: 2.2     // UPPERCASE labels, fontXs semibold, dim color
    readonly property real lineProse: 1.45

    // ---- Spacing, 4 grid (DESIGN.md 5.1)
    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32

    // ---- Shape and icons (DESIGN.md 5.2, 5.3). Pill = height / 2.
    readonly property int radiusPanel: 22
    readonly property int radiusCard: 12
    readonly property int radiusControl: 8
    readonly property int borderThin: 1
    readonly property int borderStrong: 2

    readonly property int iconSm: 14
    readonly property int iconMd: 16
    readonly property int iconLg: 20
    readonly property int iconXl: 24

    // ---- Surfaces and lines (DESIGN.md 3.1)
    readonly property color panel: Qt.rgba(0, 0, 0, Math.max(0.25, Math.min(1, Settings.panelOpacity)))
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)
    readonly property color transparent: "transparent"
    readonly property color tile: Qt.rgba(1, 1, 1, 0.08)
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color tilePress: Qt.rgba(1, 1, 1, 0.22)
    readonly property color line: Qt.rgba(1, 1, 1, 0.08)
    readonly property color lineFocus: Qt.alpha(accent, 0.45)

    // ---- Text: three levels (DESIGN.md 3.2)
    readonly property color text: "#ffffff"
    readonly property color dim: Qt.rgba(1, 1, 1, 0.60)
    readonly property color faint: Qt.rgba(1, 1, 1, 0.40)

    // ---- Accent (DESIGN.md 3.3): single entry point. Change the color on the `accent` line only.
    readonly property color accent: "#E8E8E6"
    readonly property color accentHover: Qt.alpha(accent, 0.85)
    readonly property color textOnAccent: "#000000"
    // Recorded exception: the Lock primary button (LockMedia) stays pure white.
    readonly property color inverse: "#ffffff"
    readonly property color inverseText: "#000000"

    readonly property real opacityDisabled: 0.4
    readonly property real opacityDim: 0.72
    readonly property real opacityHover: 0.7

    // ---- Motion (DESIGN.md 6)
    readonly property int durFast: 110
    readonly property int durBase: 180
    readonly property int durSlow: 300
    readonly property int durPulse: 600
    readonly property real pressScale: 0.97

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeIn: Easing.InCubic
    readonly property int easeInOut: Easing.InOutCubic

    readonly property real revealOpenStiff: 420
    readonly property real revealCloseStiff: 420
    readonly property real revealOpenDamp: 0.78   // ~2% bounce on open (DESIGN.md 6.1)
    readonly property real revealCloseDamp: 1.0   // clean on close
    // Full-screen scenes (Power, Lock): slower so the stagger between elements reads
    readonly property real revealSceneOpenStiff: 190
    readonly property real revealSceneCloseStiff: 300
    readonly property real drawerGap: 2
    readonly property real revealOvershootMax: 8   // px cap on the bounce past the resting position

    // Wallpaper change (WallMotion, DESIGN.md 6.4)
    readonly property int wallpaperFadeMs: 700
    readonly property real wallZoomIn: 0.08
    readonly property real wallZoomOut: 0.03
    readonly property real wallSlide: 0.04
    readonly property real wallDip: 0.28

    // ---- Layout shared across features
    readonly property int barHeight: 32
    readonly property int barMargin: 5

    readonly property int cheatsheetKeycapHeight: 22
    readonly property int cheatsheetKeycapMinWidth: 22
    readonly property int cheatsheetKeycapPadding: 12

    readonly property int listHeaderHeight: 34
    readonly property int listSubheaderHeight: 26
    readonly property int listRowHeight: 46
    readonly property int listFooterHeight: 40
    readonly property int listActionHeight: 28

    // Offset in px for a surface that slides in from `distance` px away. While bouncing (travel > 1)
    // the overshoot is capped in px, so tall and short panels bounce the same amount.
    function drawerOffset(distance, travel) {
        if (travel <= 1) return -distance * (1 - travel);
        return Math.min(distance * (travel - 1), revealOvershootMax);
    }
}
