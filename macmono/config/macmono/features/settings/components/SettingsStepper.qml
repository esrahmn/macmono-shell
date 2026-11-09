import QtQuick
import "../../../core"

Rectangle {
    id: root
    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real step: 1
    property int pad: 0
    signal moved(real v)

    implicitWidth: Theme.settingsStepperWidth
    implicitHeight: Theme.settingsStepperHeight
    radius: Theme.radiusXs

    activeFocusOnTab: true
    Keys.onLeftPressed: nudge(-1)
    Keys.onRightPressed: nudge(1)
    color: Theme.inset
    border.width: Theme.borderThin
    border.color: Theme.line

    function nudge(dir) {
        const v = Math.max(minValue, Math.min(maxValue, value + dir * step));
        if (v !== value) moved(v);
    }

    component StepButton: Rectangle {
        id: btn
        property int dir: 1
        readonly property bool atLimit: dir > 0 ? root.value >= root.maxValue : root.value <= root.minValue

        width: Theme.settingsStepperButton
        height: root.height - Theme.borderThin * 2
        radius: Theme.radiusXs - 1
        color: !atLimit && area.containsMouse ? Theme.tileMid : Theme.transparent
        opacity: atLimit ? Theme.opacityDisabled : 1
        Behavior on color { ColorAnimation { duration: Theme.animHover } }

        Rectangle {
            anchors.centerIn: parent
            width: Theme.space12
            height: Theme.space2
            radius: 1
            color: Theme.textSoft
        }
        Rectangle {
            visible: btn.dir > 0
            anchors.centerIn: parent
            width: Theme.space2
            height: Theme.space12
            radius: 1
            color: Theme.textSoft
        }

        Timer {
            id: holdDelay
            interval: Theme.settingsRepeatDelay
            onTriggered: repeat.start()
        }
        Timer {
            id: repeat
            interval: Theme.settingsRepeatInterval
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
        anchors.margins: -Theme.space3
        radius: Theme.radiusXs + Theme.space3
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.lineFocus
        visible: root.activeFocus
    }

    SettingsText {
        anchors.centerIn: parent
        text: root.pad > 0 ? String(Math.round(root.value)).padStart(root.pad, "0")
                           : String(Math.round(root.value))
        font.pixelSize: Theme.fontTitle
        font.weight: Font.Medium
        font.features: ({ "tnum": 1 })
    }
}
