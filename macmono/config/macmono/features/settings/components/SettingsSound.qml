import QtQuick
import "../../../core"
import "../../../shared/components"

Column {
    id: root
    spacing: 0


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

    component MuteButton: Rectangle {
        id: mb
        property bool muted: false
        property string onGlyph: "volume"
        property string offGlyph: "mute"
        property string label: "Mute"
        signal clicked()

        width: Theme.settingsSliderHeight
        height: Theme.settingsSliderHeight
        radius: Theme.radiusXs
        color: mbArea.containsMouse ? Theme.tileHover : Theme.transparent
        Behavior on color { ColorAnimation { duration: Theme.animHover } }

        Accessible.role: Accessible.Button
        Accessible.name: (mb.muted ? "Unmute " : "Mute ") + mb.label

        Glyph {
            anchors.centerIn: parent
            name: mb.muted ? mb.offGlyph : mb.onGlyph
            color: mb.muted ? Theme.dim : Theme.text
            width: Theme.icon16
            height: Theme.icon16
        }

        MouseArea {
            id: mbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.clicked()
        }
    }

    component Card: Rectangle {
        default property alias content: body.data
        width: root.width
        height: body.height + Theme.settingsRowPadY * 2
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        Column {
            id: body
            x: Theme.settingsRowPadX
            y: Theme.settingsRowPadY
            width: parent.width - Theme.settingsRowPadX * 2
            spacing: Theme.space12
        }
    }

    component VolumeBlock: Column {
        id: vb
        property string title: ""
        property real volume: 0
        property bool muted: false
        property string onGlyph: "volume"
        property string offGlyph: "mute"
        property string label: ""
        signal volumeMoved(real v)
        signal muteClicked()
        width: parent.width
        spacing: Theme.space6

        Item {
            width: parent.width
            height: Theme.settingsSliderHeight
            SettingsText {
                anchors { left: parent.left; right: pctRow.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                text: vb.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Row {
                id: pctRow
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Theme.space10
                SettingsText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.settingsSliderLabel
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(vb.volume * 100) + "%"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    opacity: vb.muted ? Theme.opacityDim : 1
                }
                MuteButton {
                    muted: vb.muted
                    onGlyph: vb.onGlyph
                    offGlyph: vb.offGlyph
                    label: vb.label
                    onClicked: vb.muteClicked()
                }
            }
        }
        SettingsSlider {
            width: parent.width
            showValue: false
            opacity: vb.muted ? Theme.opacityDim : 1
            value: Math.max(0, Math.min(1, vb.volume))
            valueText: Math.round(vb.volume * 100) + "%"
            onMoved: (v) => vb.volumeMoved(v)
        }
    }

    component DeviceList: Column {
        id: dl
        property var devices: []
        property var current: null
        signal picked(var node)
        visible: devices.length > 1
        width: parent.width
        spacing: Theme.space2

        Rectangle { width: parent.width; height: Theme.borderThin; color: Theme.line }
        SettingsText {
            topPadding: Theme.space6
            bottomPadding: Theme.space4
            text: "Switch device"
            color: Theme.dim
            font.pixelSize: Theme.fontCaption
        }
        Repeater {
            model: dl.devices
            delegate: Rectangle {
                id: dr
                required property var modelData
                readonly property bool active: modelData === dl.current
                width: dl.width
                height: Theme.settingsListRowHeight - Theme.space8
                radius: Theme.radiusXs
                color: active ? Theme.tileMid : (drArea.containsMouse ? Theme.tileFaint : Theme.transparent)
                Behavior on color { ColorAnimation { duration: Theme.animHover } }

                SettingsText {
                    anchors { left: parent.left; leftMargin: Theme.space10; right: parent.right; rightMargin: Theme.space30; verticalCenter: parent.verticalCenter }
                    text: Sys.nodeLabel(dr.modelData)
                    font.weight: dr.active ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }
                Glyph {
                    visible: dr.active
                    anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    name: "check"
                    color: Theme.text
                    width: Theme.icon14
                    height: Theme.icon14
                }
                MouseArea {
                    id: drArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dl.picked(dr.modelData)
                }
            }
        }
    }

    component Note: SettingsText {
        width: root.width
        topPadding: Theme.space8
        bottomPadding: Theme.settingsRowPadY
        leftPadding: Theme.settingsRowPadX
        rightPadding: Theme.settingsRowPadX
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.pixelSize: Theme.fontBody
    }

    function setVis(key, value) { SettingsStore.apply(({ [key]: value }), []); }


    SectionLabel { first: true; text: "OUTPUT" }

    Card {
        VolumeBlock {
            title: Sys.sink ? Sys.nodeLabel(Sys.sink) : "No output device"
            volume: Sys.volume
            muted: Sys.muted
            label: "output"
            onVolumeMoved: (v) => Sys.setVolume(v)
            onMuteClicked: Sys.setMuted(!Sys.muted)
        }
        DeviceList {
            devices: Sys.outputDevices
            current: Sys.sink
            onPicked: (node) => Sys.setOutput(node)
        }

        Column {
            width: parent.width
            spacing: Theme.space6

            Rectangle { width: parent.width; height: Theme.borderThin; color: Theme.line }

            Item {
                width: parent.width
                height: Theme.settingsSliderHeight
                SettingsText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Test sound"
                    font.weight: Font.DemiBold
                }
                SettingsButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    label: Sys.testSoundRunning ? "Stop" : "Play"
                    primary: Sys.testSoundRunning
                    onClicked: Sys.toggleTestSound()
                }
            }

            SettingsText {
                visible: Sys.testSoundStatus === "failed"
                width: parent.width
                text: "Could not play a test sound."
                color: Theme.settingsDescText
                font.pixelSize: Theme.fontBody
                wrapMode: Text.Wrap
            }
        }
    }


    SectionLabel { text: "INPUT" }

    Binding { target: Sys; property: "soundMeterActive"; value: root.visible && Sys.settingsOpen }

    Card {
        VolumeBlock {
            title: Sys.source ? Sys.nodeLabel(Sys.source) : "No input device"
            volume: Sys.sourceVolume
            muted: Sys.micMuted
            onGlyph: "mic"
            offGlyph: "mic-off"
            label: "microphone"
            onVolumeMoved: (v) => Sys.setSourceVolume(v)
            onMuteClicked: Sys.setSourceMuted(!Sys.micMuted)
        }

        Column {
            visible: Sys.inputMeterAvailable
            width: parent.width
            spacing: Theme.space6

            Rectangle { width: parent.width; height: Theme.borderThin; color: Theme.line }

            Item {
                width: parent.width
                height: Theme.settingsSliderHeight
                SettingsText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Input level"
                    font.weight: Font.DemiBold
                }
                SettingsText {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: Math.round(Sys.inputLevel * 100) + "%"
                    color: Theme.settingsDescText
                    font.pixelSize: Theme.fontBody
                    font.features: ({ "tnum": 1 })
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.settingsMeterHeight
                radius: height / 2
                color: Theme.inset

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, Sys.inputLevel * parent.width))
                    height: parent.height
                    radius: height / 2
                    color: Theme.text
                    Behavior on width { NumberAnimation { duration: Theme.animHover } }
                }
            }
        }

        DeviceList {
            devices: Sys.inputDevices
            current: Sys.source
            onPicked: (node) => Sys.setSource(node)
        }
    }


    SectionLabel { text: "APPLICATIONS" }

    Card {
        SettingsText {
            visible: Sys.streams.length === 0
            width: parent.width
            text: "No app is playing sound right now."
            color: Theme.dim
            font.pixelSize: Theme.fontBody
        }

        Column {
            width: parent.width
            spacing: 0
            Repeater {
                model: Sys.streams
                delegate: Item {
                    id: app
                    required property var modelData
                    required property int index
                    readonly property real vol: Math.max(0, Math.min(1, modelData.audio?.volume ?? 0))
                    readonly property bool isMuted: modelData.audio?.muted === true
                    width: parent.width
                    height: Theme.settingsListRowHeight

                    Rectangle { visible: app.index > 0; width: parent.width; height: Theme.borderThin; color: Theme.line }

                    SettingsText {
                        id: appName
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: parent.width * 0.28
                        text: Sys.streamName(app.modelData)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    MuteButton {
                        id: appMute
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        muted: app.isMuted
                        label: Sys.streamName(app.modelData)
                        onClicked: Sys.setStreamMuted(app.modelData, !app.isMuted)
                    }
                    SettingsText {
                        id: appPct
                        anchors { right: appMute.left; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        width: Theme.settingsSliderLabel - Theme.space14
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(app.vol * 100) + "%"
                        color: Theme.settingsDescText
                        font.pixelSize: Theme.fontBody
                    }
                    SettingsSlider {
                        anchors { left: appName.right; leftMargin: Theme.space12; right: appPct.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                        showValue: false
                        opacity: app.isMuted ? Theme.opacityDim : 1
                        value: app.vol
                        valueText: Math.round(app.vol * 100) + "%"
                        onMoved: (v) => Sys.setStreamVolume(app.modelData, v)
                    }
                }
            }
        }
    }


    SectionLabel { text: "MUSIC VISUALIZER" }

    Binding { target: Sys; property: "visualizerPreview"; value: root.visible && Sys.settingsOpen }

    Rectangle {
        id: preview
        width: root.width
        height: 112
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.cardStroke
        clip: true

        readonly property bool quiet: Math.max.apply(null, Sys.mediaVisualizerLevels) < 8

        CavaWave {
            anchors { fill: parent; margins: Theme.borderThin }
            visible: Settings.visualizerEnabled
            levels: Sys.mediaVisualizerLevels
            fillOpacity: 0.30
            cornerRadius: preview.radius - Theme.borderThin
        }

        SettingsText {
            anchors.centerIn: parent
            visible: !Settings.visualizerEnabled || preview.quiet
            text: Settings.visualizerEnabled ? "Play some sound and it moves here" : "Visualizer is off"
            color: Theme.dim
        }
    }

    SettingsRow {
        width: root.width
        title: "Show visualizer"
        SettingsToggle {
            checked: Settings.visualizerEnabled
            onToggled: (v) => root.setVis("visualizerEnabled", v)
        }
    }

    SettingsRow {
        width: root.width
        title: "Wave height"
        stacked: true
        separator: true
        opacity: Settings.visualizerEnabled ? 1 : 0.4
        valueText: Number(Settings.visualizerGain).toFixed(1) + "×"
        SettingsSlider {
            width: parent.width
            showValue: false
            enabled: Settings.visualizerEnabled
            minValue: 0.5
            maxValue: 2
            step: 0.1
            value: Settings.visualizerGain
            valueText: Number(Settings.visualizerGain).toFixed(1) + "×"
            onMoved: (v) => root.setVis("visualizerGain", v)
        }
    }

    SettingsRow {
        width: root.width
        title: "Show in top bar"
        separator: true
        opacity: Settings.visualizerEnabled ? 1 : 0.4
        SettingsToggle {
            enabled: Settings.visualizerEnabled
            checked: Settings.visualizerInBar
            onToggled: (v) => root.setVis("visualizerInBar", v)
        }
    }

    SettingsRow {
        width: root.width
        title: "Show in music popup"
        separator: true
        opacity: Settings.visualizerEnabled ? 1 : 0.4
        SettingsToggle {
            enabled: Settings.visualizerEnabled
            checked: Settings.visualizerInPopup
            onToggled: (v) => root.setVis("visualizerInPopup", v)
        }
    }

    Note { text: "Turning the visualizer off also stops the audio analyzer, which saves battery. 1.0× is the normal wave height." }
}
