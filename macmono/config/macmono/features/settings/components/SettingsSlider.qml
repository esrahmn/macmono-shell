import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: root

    readonly property int settingsSliderWidth: 260
    readonly property int settingsSliderKnob: 14
    readonly property int settingsSliderTickH: 10
    readonly property int settingsSliderTickW: 2
    readonly property real settingsSliderTickOpacity: 0.55
    readonly property int settingsSliderSnapPx: 6
    property real value: 0
    property real minValue: 0
    property real maxValue: 1
    property real step: 0.01
    property string valueText: ""
    property bool showValue: true
    property real defaultValue: NaN
    signal moved(real v)

    implicitWidth: root.settingsSliderWidth
    implicitHeight: SettingsMetrics.settingsSliderHeight
    activeFocusOnTab: true

    readonly property int decimals: Math.max(0, -Math.floor(Math.log10(step)))
    readonly property real ratio: maxValue > minValue ? Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue))) : 0
    readonly property bool hasDefault: !isNaN(defaultValue) && maxValue > minValue
    readonly property real defaultRatio: hasDefault ? Math.max(0, Math.min(1, (defaultValue - minValue) / (maxValue - minValue))) : 0
    readonly property real trackWidth: showValue ? width - label.width - Theme.space16 : width

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
            height: SettingsMetrics.settingsSliderTrack
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.tileHover

            Rectangle {
                width: knob.x + knob.width / 2
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Rectangle {
            visible: root.hasDefault && root.value !== root.defaultValue
            width: root.settingsSliderTickW
            height: root.settingsSliderTickH
            radius: width / 2
            x: knob.width / 2 + root.defaultRatio * (track.width - knob.width) - width / 2
            y: (parent.height - height) / 2
            color: Theme.text
            opacity: root.settingsSliderTickOpacity
        }

        Rectangle {
            id: knob
            width: root.settingsSliderKnob
            height: root.settingsSliderKnob
            radius: height / 2
            y: (parent.height - height) / 2
            x: root.ratio * (track.width - width)
            color: Theme.accent
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            preventStealing: true
            function update(mx) {
                root.forceActiveFocus();
                const span = track.width - knob.width;
                let r = (mx - knob.width / 2) / span;
                if (root.hasDefault && span > 0 && Math.abs(r - root.defaultRatio) * span <= root.settingsSliderSnapPx)
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
        width: SettingsMetrics.settingsSliderLabel
        horizontalAlignment: Text.AlignRight
        text: root.valueText
        font.pixelSize: Theme.fontLg
        font.features: ({ "tnum": 1 })
        color: Theme.text
    }

}
