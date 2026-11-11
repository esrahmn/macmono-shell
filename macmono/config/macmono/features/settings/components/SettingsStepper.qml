import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    readonly property int settingsStepperWidth: 120
    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real step: 1
    property int pad: 0
    signal moved(real v)

    implicitWidth: root.settingsStepperWidth
    implicitHeight: SettingsMetrics.settingsStepperHeight
    radius: Theme.radiusControl

    activeFocusOnTab: true
    Keys.onLeftPressed: nudge(-1)
    Keys.onRightPressed: nudge(1)
    color: Theme.scrim
    border.width: Theme.borderThin
    border.color: Theme.line

    function nudge(dir) {
        const v = Math.max(minValue, Math.min(maxValue, value + dir * step));
        if (v !== value) moved(v);
    }

    component StepButton: Rectangle {
        readonly property int settingsRepeatDelay: 380
        readonly property int settingsRepeatInterval: 70
        readonly property int settingsStepperButton: 32
        id: btn
        property int dir: 1
        readonly property bool atLimit: dir > 0 ? root.value >= root.maxValue : root.value <= root.minValue

        width: settingsStepperButton
        height: root.height - Theme.borderThin * 2
        radius: Theme.radiusControl - 1
        color: !atLimit && area.containsMouse ? Theme.tile : Theme.transparent
        opacity: atLimit ? Theme.opacityDisabled : 1
        Behavior on color { TweenColor { duration: Theme.durFast } }

        Rectangle {
            anchors.centerIn: parent
            width: Theme.space12
            height: Theme.space2
            radius: 1
            color: Theme.text
        }
        Rectangle {
            visible: btn.dir > 0
            anchors.centerIn: parent
            width: Theme.space2
            height: Theme.space12
            radius: 1
            color: Theme.text
        }

        Timer {
            id: holdDelay
            interval: settingsRepeatDelay
            onTriggered: repeat.start()
        }
        Timer {
            id: repeat
            interval: settingsRepeatInterval
            repeat: true
            onTriggered: root.nudge(btn.dir)
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: { root.forceActiveFocus(); root.nudge(btn.dir); holdDelay.restart(); }
            onReleased: { holdDelay.stop(); repeat.stop(); }
            onCanceled: { holdDelay.stop(); repeat.stop(); }
        }
    }

    StepButton { id: minus; x: Theme.borderThin; y: Theme.borderThin; dir: -1 }
    StepButton { id: plus; x: root.width - width - Theme.borderThin; y: Theme.borderThin; dir: 1 }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.space2
        radius: Theme.radiusControl + Theme.space2
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.lineFocus
        visible: root.activeFocus
    }

    SettingsText {
        anchors.centerIn: parent
        text: root.pad > 0 ? String(Math.round(root.value)).padStart(root.pad, "0")
                           : String(Math.round(root.value))
        font.pixelSize: Theme.fontLg
        font.weight: Theme.weightMedium
        font.features: ({ "tnum": 1 })
    }
}
