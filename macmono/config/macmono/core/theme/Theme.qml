pragma Singleton

import QtQuick
import Quickshell
import "../settings"

Singleton {
    readonly property string font: {
        const fams = Qt.fontFamilies();
        for (const f of ["Inter", "Inter Variable", "Inter Var", "Inter Display"])
            if (fams.indexOf(f) >= 0) return f;
        return "Inter";
    }
    readonly property string fontMono: "monospace"

    readonly property int fontMicro: 10
    readonly property int fontCaption: 11
    readonly property int fontSmall: 11
    readonly property int fontBody: 12
    readonly property int fontBodyLg: 13
    readonly property int fontSubtitle: 14
    readonly property int fontTitle: 15
    readonly property int fontHeading: 16
    readonly property int fontLead: 18
    readonly property int fontDisplay: 30
    readonly property int fontHeadingLg: 17
    readonly property int fontDisplaySm: 19
    readonly property int fontDisplayMd: 22
    readonly property int fontHero: 26
    readonly property int fontClock: 84
    readonly property int fontEmoji: 24

    readonly property real lineTight: 1.15
    readonly property real lineBody: 1.32
    readonly property real lineProse: 1.45

    readonly property int space0: 0
    readonly property int space1: 1
    readonly property int space2: 2
    readonly property int space3: 3
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space7: 7
    readonly property int space8: 8
    readonly property int space10: 10
    readonly property int space12: 12
    readonly property int space14: 14
    readonly property int space16: 16
    readonly property int space18: 18
    readonly property int space22: 22
    readonly property int space30: 30

    readonly property color bar: Qt.rgba(0, 0, 0, Math.max(0.25, Math.min(1, Settings.panelOpacity)))
    readonly property color panel: bar
    readonly property color popup: bar
    readonly property color raised: Qt.rgba(0.16, 0.16, 0.16, 0.95)
    readonly property color canvas: "#0b0b0b"
    readonly property color black: "#000000"
    readonly property color transparent: "transparent"

    readonly property color powerScrim: Qt.rgba(0, 0, 0, 0.55)
    readonly property color veil: Qt.rgba(0, 0, 0, 0.01)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)
    readonly property color inset: Qt.rgba(0, 0, 0, 0.30)
    readonly property color badge: Qt.rgba(0, 0, 0, 0.75)

    readonly property color tileFaint: Qt.rgba(1, 1, 1, 0.06)
    readonly property color tile: Qt.rgba(1, 1, 1, 0.08)
    readonly property color tileMid: Qt.rgba(1, 1, 1, 0.11)
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color tileStrong: Qt.rgba(1, 1, 1, 0.22)
    readonly property color selection: Qt.rgba(1, 1, 1, 0.30)

    readonly property color line: Qt.rgba(1, 1, 1, 0.08)
    readonly property color lineStrong: Qt.rgba(1, 1, 1, 0.12)
    readonly property color lineFocus: Qt.rgba(1, 1, 1, 0.35)

    readonly property color text: "#ffffff"
    readonly property color textSoft: Qt.rgba(1, 1, 1, 0.80)
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color muted: Qt.rgba(1, 1, 1, 0.40)
    readonly property color ghost: Qt.rgba(1, 1, 1, 0.10)
    readonly property color faint: Qt.rgba(1, 1, 1, 0.30)

    readonly property color inverse: "#ffffff"
    readonly property color inverseText: "#000000"
    readonly property color inverseHover: Qt.rgba(1, 1, 1, 0.85)
    readonly property color inverseDim: Qt.rgba(0, 0, 0, 0.55)
    readonly property color inverseTile: Qt.rgba(0, 0, 0, 0.08)

    readonly property color well: Qt.rgba(0, 0, 0, 0.14)
    readonly property color cardStroke: line

    readonly property int animPress: 90
    readonly property int animHover: 130
    readonly property int animFade: 160
    readonly property int animBase: 200
    readonly property int animSlow: 300
    readonly property int animPulse: 600
    readonly property int animScroll: 360
    readonly property real buttonPressedScale: 0.97

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeIn: Easing.InCubic

    readonly property real springStiff: 4.8
    readonly property real springDamp: 0.4

    readonly property real revealOpenStiff: 420
    readonly property real revealCloseStiff: 420
    readonly property real revealDamp: 1.0
    readonly property real drawerGap: 2

    readonly property int animOpen: 280
    readonly property int easeOpen: Easing.OutBack
    readonly property real openOvershoot: 1.2
    readonly property real openDrop: 24
    readonly property real openScaleFrom: 0.9
    readonly property real openScaleFromModal: 0.94

    readonly property real opacityDisabled: 0.4
    readonly property real opacityDim: 0.72
    readonly property real openFromPanel: 0.4
    readonly property real openFromModal: 0.65

    readonly property int barHeight: 39
    readonly property int barMargin: 6

    readonly property int radiusXs: 8
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusCard: 12
    readonly property int radius: 16
    readonly property int radiusLarge: 20
    readonly property int radiusPanel: 22
    readonly property int radiusXl: 22
    readonly property int radiusKey: 6
    readonly property int radiusIndicator: 2

    readonly property int borderThin: 1
    readonly property int borderStrong: 2
    readonly property int borderNone: 0


    readonly property int commandPaletteWidth: 680
    readonly property int commandPaletteMaxHeight: 620
    readonly property int commandPaletteSearchHeight: 64
    readonly property int commandPaletteCategoryHeight: 42
    readonly property int commandPaletteRowHeight: 46
    readonly property int commandPalettePadding: 20

    readonly property int cheatsheetWidth: 440
    readonly property int cheatsheetPadding: 20
    readonly property int cheatsheetGroupSpacing: 22
    readonly property int cheatsheetRowHeight: 26
    readonly property int cheatsheetKeycapHeight: 22
    readonly property int cheatsheetKeycapMinWidth: 22
    readonly property int cheatsheetKeycapPadding: 12
    readonly property real cheatsheetSectionLetterSpacing: 1.2

    readonly property int icon11: 11
    readonly property int icon13: 13
    readonly property int icon14: 14
    readonly property int icon15: 15
    readonly property int icon16: 16
    readonly property int icon17: 17
    readonly property int icon18: 18
    readonly property int icon20: 20
    readonly property int icon22: 22
    readonly property int icon30: 30

    readonly property int notifWidth: 420
    readonly property int notifPadX: 16
    readonly property int notifPadTop: 20
    readonly property int notifPadBottom: 18
    readonly property int notifMinHeight: 0
    readonly property int notifMaxHeight: 320
    readonly property int notifImageSize: 56
    readonly property int notifImageGap: 14
    readonly property int notifCloseSize: 28
    readonly property int notifActionHeight: 40
    readonly property int notifTextInset: 46
    readonly property int notifSlideFrom: 56
    readonly property int notifDismissDelay: 280

    readonly property int ccWidth: 500
    readonly property int ccCardPadding: 32
    readonly property int ccAvatarSize: 40
    readonly property int ccHeaderButtonSize: 38
    readonly property int ccProfileTileWidth: 72
    readonly property int ccToggleTileHeight: 92
    readonly property int ccNetworkTileHeight: 56
    readonly property int ccNetworkIconCircle: 36
    readonly property int ccSliderLabelWidth: 38
    readonly property int ccSliderButtonSize: 26
    readonly property int sliderHeight: 38
    readonly property int actionTileHeight: 78
    readonly property int toolsSegmentHeight: 32
    readonly property int toolsRecordHeight: 38

    readonly property int listHeaderHeight: 34
    readonly property int listSubheaderHeight: 26
    readonly property int listRowHeight: 46
    readonly property int listFooterHeight: 40
    readonly property int listActionHeight: 28
    readonly property int detailRowHeight: 44
    readonly property int wifiPasswordHeight: 32
    readonly property int wifiShowPwWidth: 28
    readonly property int wifiShowPwHeight: 24
    readonly property int wifiJoinWidth: 64
    readonly property int wifiJoinHeight: 32
    readonly property int btHeaderHeight: 36
    readonly property int btHintHeight: 64
    readonly property int btToggleHeight: 30

    readonly property int mediaPopupWidth: 500
    readonly property int mediaPopupLyricsHeight: 240
    readonly property int mediaPosterTitleSize: 24
    readonly property int mediaPosterTitleSizeCompact: 20
    readonly property int mediaArtSizeSmall: 44
    readonly property int mediaProgressHairline: 2
    readonly property int mediaProgressRow: 10

    readonly property int calendarWidth: 420
    readonly property int calendarNavSize: 32
    readonly property int calendarWeekdayHeight: 30
    readonly property int calendarDayHeight: 46
    readonly property int calendarDayCircle: 40
    readonly property int calendarSmallButton: 28
    readonly property int calendarClearHeight: 26

    readonly property int clipHeaderHeight: 62
    readonly property int clipClearHeight: 34
    readonly property int clipSearchWidth: 270
    readonly property int clipSearchHeight: 36
    readonly property int clipFooterHeight: 40
    readonly property int clipKeyHeight: 20
    readonly property int clipListWidth: 330
    readonly property int clipRowHeight: 54
    readonly property int clipTypeIconSize: 32
    readonly property int clipTrashSize: 26
    readonly property int clipPaneHeadHeight: 30
    readonly property int clipPaneChipHeight: 28

    readonly property int emojiTitleHeight: 28
    readonly property int emojiSearchHeight: 40
    readonly property int emojiCategoryHeight: 28
    readonly property int emojiCellSize: 40
    readonly property int emojiScrollbarWidth: 3
    readonly property int emojiFooterHeight: 34
    readonly property int emojiKeyHeight: 22

    readonly property int launcherSearchHeight: 62
    readonly property int launcherHintHeight: 24
    readonly property int launcherPinHeight: 108
    readonly property int launcherPinIconBox: 64
    readonly property int launcherPinIcon: 42
    readonly property int launcherSectionHeight: 16
    readonly property int launcherTagHeight: 22
    readonly property int launcherPreviewWidth: 500
    readonly property int launcherPreviewPadding: 32
    readonly property int launcherPreviewIcon: 64
    readonly property int launcherPreviewGlyph: 40
    readonly property int launcherPreviewRow: 40

    readonly property int menubarCellHeight: 16
    readonly property int menubarTrayItem: 23
    readonly property int menubarRecHeight: 22
    readonly property int menubarPrivHeight: 20
    readonly property int menubarTitleMaxWidth: 300
    readonly property int wsDotWide: 20
    readonly property int wsDotNarrow: 7
    readonly property int wsDotCompact: 8
    readonly property real opacityHover: 0.7

    readonly property int osdWidth: 240
    readonly property int osdHeight: 56
    readonly property int osdSlideFrom: 48
    readonly property int osdBottomMargin: 90
    readonly property int osdLabelWidth: 34
    readonly property int osdTrackHeight: 6

    readonly property int powerButtonSize: 84
    readonly property int powerGlyphSize: 30

    readonly property int selectorBadgeHeight: 24
    readonly property int selectorHintHeight: 34

    readonly property int trayBackHeight: 30
    readonly property int trayCheckWidth: 14

    readonly property int wpPillTop: 52
    readonly property int wpPillHeight: 40
    readonly property int wpTrayHeight: 200
    readonly property int wpTrayMargin: 24
    readonly property int wpBadgeHeight: 18
    readonly property int wpChipHeight: 28
    readonly property int wpChipDefaultHeight: 30
    readonly property int wpCloseDelay: 170

    readonly property int lockPasswordWidth: 260
    readonly property int lockDateSize: 14
    readonly property real lockDateTracking: 3.1
    readonly property real lockClockTracking: -6
    readonly property real lockClockTopRatio: 0.09
    readonly property real lockInputBottomRatio: 0.1
    readonly property real lockWallpaperDim: -0.3
    readonly property int lockShakeAmplitude: 12
    readonly property int lockShakeAmplitudeSoft: 8
    readonly property int animShakeFast: 50
    readonly property int animShakeMid: 60
    readonly property int animShakeSlow: 70

    readonly property int settingsWidth: 1100
    readonly property int settingsHeight: 900
    readonly property int settingsGutter: 16
    readonly property int settingsHeaderHeight: 64
    readonly property int settingsListRowHeight: 44
    readonly property int settingsContentMax: 720
    readonly property int settingsSideWidth: 264
    readonly property int labelCapsSize: 10
    readonly property real labelCapsTracking: 2.2
    readonly property int settingsTitleSize: 28
    readonly property int panelTitleSize: settingsTitleSize
    readonly property real panelTitleTracking: settingsTitleTracking
    readonly property real settingsTitleTracking: -0.9
    readonly property real settingsRowTracking: -0.2
    readonly property int settingsBarHeight: 44
    readonly property color settingsBarFill: Qt.rgba(0.11, 0.11, 0.11, 0.96)
    readonly property color settingsDescText: Qt.rgba(1, 1, 1, 0.62)
    readonly property color labelCapsText: Qt.rgba(1, 1, 1, 0.50)
    readonly property int aboutContentMax: 640
    readonly property int aboutHeroGap: 36
    readonly property int aboutLaptopWidth: 260
    readonly property int aboutLaptopHeight: 162
    readonly property int aboutLaptopBaseWidth: 288
    readonly property int aboutLaptopBaseHeight: 11
    readonly property int aboutLaptopBezel: 3
    readonly property int aboutLaptopCutoutWidth: 44
    readonly property int aboutLaptopCutoutHeight: 7
    readonly property int aboutLaptopNotch: 60
    readonly property int aboutLaptopNotchDepth: 3
    readonly property color aboutLaptopBezelFill: Qt.rgba(0.04, 0.04, 0.04, 0.92)
    readonly property color aboutLaptopBaseTop: Qt.rgba(1, 1, 1, 0.30)
    readonly property color aboutLaptopBaseBottom: Qt.rgba(1, 1, 1, 0.13)
    readonly property int aboutNameSize: 24
    readonly property real aboutNameTracking: -0.5
    readonly property int aboutSectionGap: 32
    readonly property int aboutStatValueSize: 18
    readonly property int aboutStatGapX: 40
    readonly property int aboutStatGapY: 20
    readonly property int aboutStatPad: 12
    readonly property int aboutLayerHeight: 40
    readonly property int aboutLayerGap: 6
    readonly property int aboutLayerGrowX: 10
    readonly property int aboutLayerGrowY: 4
    readonly property real aboutLayerSpring: 5.5
    readonly property real aboutLayerDamp: 0.5
    readonly property color aboutLayerHoverFill: Qt.rgba(1, 1, 1, 0.30)
    readonly property color aboutLayerHoverStroke: Qt.rgba(1, 1, 1, 0.34)
    readonly property int aboutStatBar: 6
    readonly property int settingsPadTop: 16
    readonly property int settingsGroupSpacing: 18
    readonly property int settingsSearchHeight: 40
    readonly property int settingsSearchWidth: 240
    readonly property int settingsButtonHeight: 32
    readonly property int settingsButtonPadX: 14
    readonly property int settingsRowPadX: 16
    readonly property int settingsRowPadY: 14
    readonly property int settingsDot: 6
    readonly property int settingsToggleWidth: 40
    readonly property int settingsToggleHeight: 24
    readonly property int settingsToggleKnob: 18
    readonly property int settingsToggleInset: 3
    readonly property int settingsSliderWidth: 260
    readonly property int settingsSliderHeight: 28
    readonly property int settingsSliderTrack: 4
    readonly property int settingsSliderKnob: 14
    readonly property int settingsSliderLabel: 60
    readonly property int settingsMeterHeight: 6
    readonly property int settingsPreviewHeight: 190
    readonly property int settingsPreviewBarHeight: 24
    readonly property int settingsPreviewPanelHeight: 84
    readonly property int settingsPreviewPanelMax: 260
    readonly property int settingsPreviewSourceWidth: 960
    readonly property int settingsHeroHeight: 220
    readonly property int settingsHeroScrimHeight: 84
    readonly property color settingsScrim: Qt.rgba(0, 0, 0, 0.65)
    readonly property int settingsThumbMin: 150
    readonly property int settingsThumbSourceWidth: 380
    readonly property real settingsThumbRatio: 0.5625
    readonly property int settingsThumbMax: 12
    readonly property int settingsMonitorHeight: 110
    readonly property int settingsMonitorMaxW: 200
    readonly property int settingsMonitorNeckW: 10
    readonly property int settingsMonitorNeckH: 8
    readonly property int settingsMonitorStandW: 56
    readonly property int settingsMonitorStandH: 5
    readonly property int settingsNightHeight: 120
    readonly property int settingsWeatherHeight: 96
    readonly property int settingsWeatherIcon: 40
    readonly property int settingsWeatherTempSize: 44
    readonly property real settingsWeatherTempTracking: -1.4
    readonly property int settingsEqAxisW: 34
    readonly property int settingsEqPlotHeight: 112
    readonly property int settingsEqBandHeight: 150
    readonly property int settingsEqBandPad: 10
    readonly property int settingsEqKnob: 16
    readonly property int settingsEqTick: 14
    readonly property real settingsEqOffOpacity: 0.55
    readonly property int settingsBackupShown: 5
    readonly property int settingsPickMax: 8
    readonly property int settingsBatBar: 10
    readonly property int settingsSegHeight: 38
    readonly property int settingsMarkSize: 10
    readonly property int settingsDemoHeight: 90
    readonly property int settingsDemoPadW: 130
    readonly property int settingsDemoPageW: 200
    readonly property int settingsDemoTravel: 40
    readonly property int settingsDemoMs: 1600
    readonly property int settingsDemoPauseMs: 700
    readonly property int settingsKeycap: 40
    readonly property int settingsNotifPreviewW: 300
    readonly property int settingsConfirmMs: 3000
    readonly property int settingsSavedMs: 1700
    readonly property real settingsSliderKnobPressed: 1.15
    readonly property int settingsSliderTickH: 10
    readonly property int settingsSliderTickW: 2
    readonly property real settingsSliderTickOpacity: 0.55
    readonly property int settingsSliderSnapPx: 6
    readonly property int settingsHoverPreviewMs: 140
    readonly property int settingsFlashHoldMs: 450
    readonly property int settingsFlashFadeMs: 700
    readonly property int settingsStepperWidth: 120
    readonly property int settingsStepperHeight: 30
    readonly property int settingsStepperButton: 32
    readonly property int settingsRepeatDelay: 380
    readonly property int settingsRepeatInterval: 70
    readonly property int settingsChipHeight: 26
    readonly property int settingsChipRemove: 18
    readonly property int settingsChipInputWidth: 150
    readonly property int settingsChipsMinWidth: 320
    readonly property int settingsScrollbarWidth: 3
    readonly property int settingsScrollbarInset: 7
    readonly property int settingsScrollbarMin: 24
}
