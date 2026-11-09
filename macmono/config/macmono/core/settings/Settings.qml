pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property real panelOpacity: SettingsStore.v("panelOpacity", 0.60)

    readonly property bool clock24h: SettingsStore.v("clock24h", true)
    readonly property bool clockSeconds: SettingsStore.v("clockSeconds", false)
    readonly property bool clockDate: SettingsStore.v("clockDate", false)

    readonly property int menubarWorkspaceMin: SettingsStore.v("menubarWorkspaceMin", 5)
    readonly property int menubarWorkspaceMax: SettingsStore.v("menubarWorkspaceMax", 10)

    readonly property var pinnedApps: SettingsStore.v("pinnedApps", ["kitty", "google-chrome", "spotify", "org.kde.dolphin", "discord", "steam", "com.microsoft.VSCode", "com.obsproject.Studio"])

    readonly property int superTapMaxMs: SettingsStore.v("superTapMaxMs", 450)

    readonly property int launcherMaxResults: SettingsStore.v("launcherMaxResults", 9)

    readonly property int overviewRows: SettingsStore.v("overviewRows", 2)

    readonly property int overviewColumns: SettingsStore.v("overviewColumns", 5)

    readonly property real overviewScale: SettingsStore.v("overviewScale", 0.14)

    readonly property bool overviewLivePreview: SettingsStore.v("overviewLivePreview", true)

    readonly property int clipboardMaxItems: SettingsStore.v("clipboardMaxItems", 200)

    readonly property int notifDefaultTimeoutMs: SettingsStore.v("notifDefaultTimeoutMs", 5000)

    readonly property int notifHistoryMax: SettingsStore.v("notifHistoryMax", 50)

    readonly property bool dndScheduleEnabled: SettingsStore.v("dndScheduleEnabled", false)
    readonly property int dndStartMin: SettingsStore.v("dndStartMin", 1320)
    readonly property int dndEndMin: SettingsStore.v("dndEndMin", 420)

    readonly property var notifMutedApps: SettingsStore.v("notifMutedApps", [])

    readonly property int osdHideMs: SettingsStore.v("osdHideMs", 1400)

    readonly property var batteryWarnLevels: SettingsStore.v("batteryWarnLevels", [5, 10, 20])

    readonly property int batteryCriticalLevel: SettingsStore.v("batteryCriticalLevel", 10)

    readonly property int nightLightKelvin: SettingsStore.v("nightLightKelvin", 4200)

    readonly property int nightLightOffKelvin: SettingsStore.v("nightLightOffKelvin", 6500)

    readonly property bool nightLightSchedule: SettingsStore.v("nightLightSchedule", false)

    readonly property real brightnessStep: SettingsStore.v("brightnessStep", 0.05)

    readonly property int brightnessDebounceMs: SettingsStore.v("brightnessDebounceMs", 80)

    readonly property int brightnessDdcDebounceMs: SettingsStore.v("brightnessDdcDebounceMs", 250)

    readonly property int wifiStatusPollMs: SettingsStore.v("wifiStatusPollMs", 30000)

    readonly property int wifiConnectTimeoutMs: SettingsStore.v("wifiConnectTimeoutMs", 45000)

    readonly property int wifiMaxNetworks: SettingsStore.v("wifiMaxNetworks", 16)

    readonly property int btPairTimeoutSec: SettingsStore.v("btPairTimeoutSec", 30)

    readonly property int privacyPollActiveMs: SettingsStore.v("privacyPollActiveMs", 2000)

    readonly property var wallpaperDirs: SettingsStore.v("wallpaperDirs", ["~/Pictures/Wallpapers", "~/Pictures", "~/Wallpapers", "~/.local/share/backgrounds", "/usr/share/backgrounds", "/usr/share/wallpapers"])

    readonly property int wallpaperScanDepth: SettingsStore.v("wallpaperScanDepth", 2)

    readonly property int wallpaperMaxFiles: SettingsStore.v("wallpaperMaxFiles", 500)

    readonly property int panelCloseDelayMs: SettingsStore.v("panelCloseDelayMs", 380)

    readonly property int recordStartTimeoutMs: SettingsStore.v("recordStartTimeoutMs", 15000)

    readonly property int recordStartTimeoutAreaMs: SettingsStore.v("recordStartTimeoutAreaMs", 120000)

    readonly property int recordStopGraceMs: SettingsStore.v("recordStopGraceMs", 8000)

    readonly property int lyricsRequestTimeoutMs: SettingsStore.v("lyricsRequestTimeoutMs", 11000)

    readonly property int lyricsRetryDelayMs: SettingsStore.v("lyricsRetryDelayMs", 3000)

    readonly property int lyricsSyncIntervalMs: SettingsStore.v("lyricsSyncIntervalMs", 40)

    readonly property real lyricsLeadSeconds: SettingsStore.v("lyricsLeadSeconds", 0.15)

    readonly property int mediaPollIntervalMs: SettingsStore.v("mediaPollIntervalMs", 3000)

    readonly property bool visualizerEnabled: SettingsStore.v("visualizerEnabled", true)
    readonly property real visualizerGain: SettingsStore.v("visualizerGain", 1.0)
    readonly property bool visualizerInBar: SettingsStore.v("visualizerInBar", true)
    readonly property bool visualizerInPopup: SettingsStore.v("visualizerInPopup", true)

    readonly property int lockPamTimeoutMs: SettingsStore.v("lockPamTimeoutMs", 10000)

    readonly property int lockClearPasswordMs: SettingsStore.v("lockClearPasswordMs", 30000)

    readonly property int lockCapsRecheckMs: SettingsStore.v("lockCapsRecheckMs", 60)

    readonly property int powerConfirmMs: SettingsStore.v("powerConfirmMs", 3000)

    readonly property int trayReopenGuardMs: SettingsStore.v("trayReopenGuardMs", 200)

    readonly property int panelReopenGuardMs: SettingsStore.v("panelReopenGuardMs", 300)

    readonly property int focusSettleDelayMs: SettingsStore.v("focusSettleDelayMs", 120)

    readonly property int osdStartupGraceMs: SettingsStore.v("osdStartupGraceMs", 2500)

    readonly property int batteryStartupDelayMs: SettingsStore.v("batteryStartupDelayMs", 4000)

    readonly property int notifSaveDelayMs: SettingsStore.v("notifSaveDelayMs", 1000)

    readonly property int clipboardDetailDebounceMs: SettingsStore.v("clipboardDetailDebounceMs", 70)

    readonly property int wallpaperPreviewDebounceMs: SettingsStore.v("wallpaperPreviewDebounceMs", 90)

    readonly property int wallpaperReadyTimeoutMs: SettingsStore.v("wallpaperReadyTimeoutMs", 8000)

    readonly property int overviewPreviewRetryMs: SettingsStore.v("overviewPreviewRetryMs", 700)


    readonly property int launcherSectionHeaderHeight: 28

    readonly property int lockBoltIconSize: 14
    readonly property int lockAvatarSize: 56
    readonly property int lockPasswordFieldHeight: 44

    readonly property int lyricsViewLineHeight: 20

    readonly property int menuBarUnreadDotSize: 6
    readonly property int menuBarRecordDotSize: 8
    readonly property int menuBarRecordingDotSize: 9

    readonly property int notifCloseIconSize: 12

    readonly property int wallpaperPillTextMaxWidth: 380

    readonly property int wifiPasswordRowHeight: 46

    readonly property real inputSensitivity: SettingsStore.v("inputSensitivity", 0)
    readonly property int inputRepeatRate: SettingsStore.v("inputRepeatRate", 25)
    readonly property int inputRepeatDelayMs: SettingsStore.v("inputRepeatDelayMs", 600)
    readonly property bool inputNaturalScroll: SettingsStore.v("inputNaturalScroll", true)
    readonly property bool inputTapToClick: SettingsStore.v("inputTapToClick", true)
    readonly property bool inputDisableWhileTyping: SettingsStore.v("inputDisableWhileTyping", true)
    readonly property bool inputClickfinger: SettingsStore.v("inputClickfinger", false)
    readonly property real inputScrollFactor: SettingsStore.v("inputScrollFactor", 1)
    readonly property var inputKbLayouts: SettingsStore.v("inputKbLayouts", [])
    readonly property var inputKbVariants: SettingsStore.v("inputKbVariants", [])
    readonly property var inputKbOptions: SettingsStore.v("inputKbOptions", [])

    readonly property int idleLockMin: SettingsStore.v("idleLockMin", 5)
    readonly property int idleScreenOffMin: SettingsStore.v("idleScreenOffMin", 10)
    readonly property int idleSuspendMin: SettingsStore.v("idleSuspendMin", 15)

    readonly property bool eqEnabled: SettingsStore.v("eqEnabled", false)
    readonly property var eqBands: SettingsStore.v("eqBands", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

    readonly property string weatherName: SettingsStore.v("weatherName", "")
    readonly property real weatherLat: SettingsStore.v("weatherLat", 0)
    readonly property real weatherLon: SettingsStore.v("weatherLon", 0)
    readonly property string weatherUnit: SettingsStore.v("weatherUnit", "c")
    readonly property int weatherCacheMin: SettingsStore.v("weatherCacheMin", 30)
}
