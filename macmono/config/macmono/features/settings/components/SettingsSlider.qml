import QtQuick
import "../../../core"

Item {
    id: root
    property real value: 0
    property real minValue: 0
    property real maxValue: 1
    property real step: 0.01
    property string valueText: ""
    property bool showValue: true
    property real defaultValue: NaN
    signal moved(real v)

    implicitWidth: Theme.settingsSliderWidth
    implicitHeight: Theme.settingsSliderHeight
    activeFocusOnTab: true

    readonly property int decimals: Math.max(0, -Math.floor(Math.log10(step)))
    readonly property real ratio: maxValue > minValue ? Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue))) : 0
    readonly property bool hasDefault: !isNaN(defaultValue) && maxValue > minValue
    readonly property real defaultRatio: hasDefault ? Math.max(0, Math.min(1, (defaultValue - minValue) / (maxValue - minValue))) : 0
    readonly property real trackWidth: showValue ? width - label.width - Theme.space14 : width

    function snap(r) {
        const raw = minValue + Math.max(0, Math.min(1, r)) * (maxValue - minValue);
        const snapped = Math.round((raw - minValue) / step) * step + minValue;
        return Number(Math.max(minValue, Math.min(maxValue, snapped)).toFixed(decimals));
    }
    function emit(v) { if (v !== value) moved(v); }

    Keys.onLeftPressed: emit(Math.max(minValue, Number((value - step).toFixed(decimals))))
    Keys.onRightPressed: emit(Math.min(maxValue, Number((value + step).toFixed(decimals))))

    Accessible.role: Accessible.Slider
    Accessible.name: valueText

    Item {
        id: track
        width: root.trackWidth
        height: parent.height

        Rectangle {
            id: rail
            width: parent.width
            height: Theme.settingsSliderTrack
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.tileHover

            Rectangle {
                width: knob.x + knob.width / 2
                height: parent.height
                radius: parent.radius
                color: Theme.inverse
            }
        }

        Rectangle {
            visible: root.hasDefault && root.value !== root.defaultValue
            width: Theme.settingsSliderTickW
            height: Theme.settingsSliderTickH
            radius: width / 2
            x: knob.width / 2 + root.defaultRatio * (track.width - knob.width) - width / 2
            y: (parent.height - height) / 2
            color: Theme.text
            opacity: Theme.settingsSliderTickOpacity
        }

        Rectangle {
            id: knob
            width: Theme.settingsSliderKnob
            height: Theme.settingsSliderKnob
            radius: height / 2
            y: (parent.height - height) / 2
            x: root.ratio * (track.width - width)
            color: Theme.inverse
            scale: drag.pressed ? Theme.settingsSliderKnobPressed : 1
            Behavior on scale { NumberAnimation { duration: Theme.animPress } }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            function update(mx) {
                root.forceActiveFocus();
                const span = track.width - knob.width;
                let r = (mx - knob.width / 2) / span;
                if (root.hasDefault && span > 0 && Math.abs(r - root.defaultRatio) * span <= Theme.settingsSliderSnapPx)
                    r = root.defaultRatio;
                root.emit(root.snap(r));
            }
            onPressed: mouse => update(mouse.x)
            onPositionChanged: mouse => { if (pressed) update(mouse.x); }
        }
    }

    SettingsText {
        id: label
        visible: root.showValue
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsSliderLabel
        horizontalAlignment: Text.AlignRight
        text: root.valueText
        font.pixelSize: Theme.fontTitle
        font.features: ({ "tnum": 1 })
        color: Theme.textSoft
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.space3
        radius: Theme.radiusSmall
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.lineFocus
        visible: root.activeFocus
    }
}
