import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: row

    readonly property int settingsFlashHoldMs: 450
    readonly property int settingsFlashFadeMs: 700
    property string title: ""
    property string valueText: ""
    property bool modified: false
    property bool resettable: false
    property string resetLabel: "Reset"
    property bool stacked: false
    property bool separator: false
    property bool titleLink: false
    signal resetRequested()
    signal titleClicked()

    function pulse() { flashAnim.restart(); }

    default property alias content: slot.data

    readonly property int padX: SettingsMetrics.settingsRowPadX
    readonly property int padY: SettingsMetrics.settingsRowPadY
    readonly property int padBottom: padY
    readonly property int bodyHeight: stacked ? texts.height + Theme.space12 + slot.height : Math.max(texts.height, slot.height)

    implicitHeight: padY + bodyHeight + padBottom

    Rectangle {
        id: flashRect
        z: -1
        anchors.fill: parent
        radius: Theme.radiusControl
        color: Theme.tileHover
        opacity: 0
    }
    SequentialAnimation {
        id: flashAnim
        Tween { target: flashRect; property: "opacity"; to: 1 }
        PauseAnimation { duration: row.settingsFlashHoldMs }
        Tween { target: flashRect; property: "opacity"; to: 0; duration: row.settingsFlashFadeMs }
    }

    Rectangle {
        visible: row.separator
        z: 2
        x: row.padX
        width: row.width - row.padX * 2
        height: Theme.borderThin
        color: Theme.line
    }

    Column {
        id: texts
        x: row.padX
        y: row.stacked ? row.padY : row.padY + (row.bodyHeight - height) / 2
        width: row.stacked ? row.width - row.padX * 2 : row.width - row.padX * 2 - slot.width - Theme.space16
        spacing: Theme.space2

        Item {
            width: parent.width
            height: titleText.height

            Row {
                spacing: Theme.space8

                SettingsText {
                    id: titleText
                    text: row.title
                    font.pixelSize: Theme.fontLg
                    font.weight: Theme.weightMedium
                    font.underline: row.titleLink && titleArea.containsMouse

                    MouseArea {
                        id: titleArea
                        anchors.fill: parent
                        enabled: row.titleLink
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.titleClicked()
                    }
                }

                Item {
                    visible: row.modified
                    width: SettingsMetrics.settingsDot
                    height: titleText.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: SettingsMetrics.settingsDot
                        height: SettingsMetrics.settingsDot
                        radius: height / 2
                        color: Theme.accent
                    }
                }

                Item {
                    visible: row.resettable
                    width: resetText.implicitWidth
                    height: titleText.height

                    SettingsText {
                        id: resetText
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.resetLabel
                        font.pixelSize: Theme.fontMd
                        color: resetArea.containsMouse ? Theme.text : Theme.faint
                        font.underline: resetArea.containsMouse
                    }
                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        anchors.margins: -Theme.space4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.resetRequested()
                    }
                }
            }

            SettingsText {
                visible: row.valueText !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.valueText
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.features: ({ "tnum": 1 })
            }
        }

    }

    Item {
        id: slot
        x: row.stacked ? row.padX : row.width - row.padX - width
        y: row.stacked ? row.padY + texts.height + Theme.space12 : row.padY + (row.bodyHeight - height) / 2
        width: row.stacked ? row.width - row.padX * 2 : childrenRect.width
        height: childrenRect.height
    }
}
