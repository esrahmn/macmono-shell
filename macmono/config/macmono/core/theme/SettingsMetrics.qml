pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Sizes shared by several files in features/settings (DESIGN.md section 2, layer 3).
    readonly property int settingsListRowHeight: 44
    readonly property color settingsDescText: Qt.rgba(1, 1, 1, 0.62)
    readonly property int aboutLaptopBezel: 3
    readonly property color aboutLaptopBezelFill: Qt.rgba(0.04, 0.04, 0.04, 0.92)
    readonly property color aboutLaptopBaseTop: Qt.rgba(1, 1, 1, 0.30)
    readonly property color aboutLaptopBaseBottom: Qt.rgba(1, 1, 1, 0.13)
    readonly property int settingsGroupSpacing: 18
    readonly property int settingsSearchHeight: 40
    readonly property int settingsButtonHeight: 32
    readonly property int settingsButtonPadX: 14
    readonly property int settingsRowPadX: 16
    readonly property int settingsRowPadY: 14
    readonly property int settingsDot: 6
    readonly property int settingsSliderHeight: 28
    readonly property int settingsSliderTrack: 4
    readonly property int settingsSliderLabel: 60
    readonly property int settingsPreviewHeight: 170
    readonly property int settingsBatBar: 10
    readonly property int settingsMarkSize: 10
    readonly property int settingsDemoHeight: 90
    readonly property int settingsDemoPadW: 130
    readonly property int settingsDemoPageW: 200
    readonly property int settingsDemoMs: 1600
    readonly property int settingsDemoPauseMs: 700
    readonly property int settingsConfirmMs: 3000
    readonly property int settingsStepperHeight: 30
    readonly property int settingsChipHeight: 26
}
