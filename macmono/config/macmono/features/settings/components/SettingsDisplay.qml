import QtQuick
import "../../../core"
import "../../../shared/components"

Column {
    id: root
    readonly property var svc: Sys.display
    spacing: Theme.settingsGroupSpacing

    onVisibleChanged: if (visible) svc.refresh()
    Component.onCompleted: svc.refresh()

    readonly property var rotations: [
        { label: "Normal", v: 0 }, { label: "90°", v: 1 }, { label: "180°", v: 2 }, { label: "270°", v: 3 }
    ]

    function clock(min) {
        const m = Math.max(0, Math.round(Number(min) || 0)) % 1440;
        return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
    }

    SettingsText {
        text: "MONITORS"
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }

    Rectangle {
        visible: root.svc.confirmLeft > 0
        width: parent.width
        height: confirmRow.height + Theme.settingsRowPadY * 2
        radius: Theme.radiusCard
        color: Theme.tileMid
        border.width: Theme.borderThin
        border.color: Theme.lineStrong
        Row {
            id: confirmRow
            x: Theme.settingsRowPadX
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space12
            SettingsText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.parent.width - Theme.settingsRowPadX * 2 - keepBtn.width - revertBtn.width - Theme.space12 * 2
                text: "Keep these display settings? Reverting in " + root.svc.confirmLeft + " s"
                wrapMode: Text.Wrap
            }
            SettingsButton { id: keepBtn; anchors.verticalCenter: parent.verticalCenter; label: "Keep"; primary: true; onClicked: root.svc.keep() }
            SettingsButton { id: revertBtn; anchors.verticalCenter: parent.verticalCenter; label: "Revert"; onClicked: root.svc.revert() }
        }
    }

    SettingsText {
        visible: root.svc.error !== ""
        width: parent.width
        leftPadding: Theme.settingsRowPadX
        text: "Not applied: " + root.svc.error
        color: Theme.dim
        wrapMode: Text.Wrap
    }

    SettingsText {
        visible: root.svc.monitors.length === 0
        leftPadding: Theme.settingsRowPadX
        text: "No monitors found."
        color: Theme.dim
    }

    Repeater {
        model: root.svc.monitors
        delegate: Rectangle {
            id: card
            required property var modelData
            readonly property var v: root.svc.value(modelData)
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
                width: card.width - Theme.settingsRowPadX * 2
                spacing: Theme.space10

                Row {
                    width: parent.width
                    spacing: Theme.space22

                    SettingsMonitorPreview {
                        id: monPreview
                        resW: parseInt(String(card.v.res).split("x")[0]) || 0
                        resH: parseInt(String(card.v.res).split("x")[1]) || 0
                        transformV: card.v.transform
                    }

                    Column {
                        width: parent.width - monPreview.width - Theme.space22
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space4

                        SettingsText { text: card.modelData.name; color: Theme.dim; font.pixelSize: Theme.fontBody }
                        SettingsText {
                            text: String(card.v.res).replace("x", " × ")
                            font.pixelSize: Theme.fontDisplayMd
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.settingsRowTracking
                        }
                        SettingsText {
                            text: Math.round(Number(card.v.rate)) + " Hz  ·  " + Math.round(card.v.scale * 100) + "% scale"
                                  + (card.v.transform === 0 ? "" : "  ·  rotated")
                            color: Theme.settingsDescText
                            font.pixelSize: Theme.fontBody
                        }
                        SettingsText {
                            visible: Math.abs(card.v.scale - 1) > 0.001 && monPreview.resW > 0
                            text: "Looks like " + Math.round((monPreview.swapped ? monPreview.resH : monPreview.resW) / card.v.scale)
                                  + " × " + Math.round((monPreview.swapped ? monPreview.resW : monPreview.resH) / card.v.scale)
                            color: Theme.dim
                            font.pixelSize: Theme.fontBody
                        }
                        SettingsText {
                            width: parent.width
                            text: card.modelData.description
                            color: Theme.dim
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }
                    }
                }

                SettingsText { text: "Resolution"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
                Flow {
                    width: parent.width; spacing: Theme.space6
                    Repeater {
                        model: root.svc.resList(card.modelData)
                        delegate: SettingsChoice { required property string modelData; label: modelData; on: card.v.res === modelData; onPicked: root.svc.setField(card.modelData, "res", modelData) }
                    }
                }

                SettingsText { text: "Refresh rate"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
                Flow {
                    width: parent.width; spacing: Theme.space6
                    Repeater {
                        model: root.svc.rateList(card.modelData, card.v.res)
                        delegate: SettingsChoice { required property string modelData; label: Math.round(Number(modelData)) + " Hz"; on: card.v.rate === modelData; onPicked: root.svc.setField(card.modelData, "rate", modelData) }
                    }
                }

                SettingsText { text: "Scale"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
                Flow {
                    width: parent.width; spacing: Theme.space6
                    Repeater {
                        model: root.svc.validScales(card.modelData, card.v.res)
                        delegate: SettingsChoice { required property real modelData; label: Math.round(modelData * 100) + "%"; on: Math.abs(card.v.scale - modelData) < 0.001; onPicked: root.svc.setField(card.modelData, "scale", modelData) }
                    }
                }

                SettingsText { text: "Rotation"; color: Theme.settingsDescText; font.pixelSize: Theme.fontBody }
                Flow {
                    width: parent.width; spacing: Theme.space6
                    Repeater {
                        model: root.rotations
                        delegate: SettingsChoice { required property var modelData; label: modelData.label; on: card.v.transform === modelData.v; onPicked: root.svc.setField(card.modelData, "transform", modelData.v) }
                    }
                }
            }
        }
    }

    Row {
        visible: root.svc.dirty && root.svc.confirmLeft === 0
        spacing: Theme.space8
        x: Theme.settingsRowPadX
        SettingsButton { label: root.svc.busy ? "Applying…" : "Apply display changes"; primary: true; enabled: !root.svc.busy; onClicked: root.svc.apply() }
        SettingsButton { label: "Reset"; onClicked: root.svc.reset() }
    }

    SettingsText {
        text: "NIGHT LIGHT SCHEDULE"
        color: Theme.labelCapsText
        font.pixelSize: Theme.labelCapsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.labelCapsTracking
        leftPadding: Theme.settingsRowPadX
    }

    SettingsRow {
        width: root.width
        title: "Follow sunset and sunrise"
        valueText: !Settings.nightLightSchedule ? ""
                 : Sys.sunTimesValid
                    ? root.clock(Sys.sunsetMin) + " – " + root.clock(Sys.sunriseMin)
                    : "No location set"
        SettingsToggle {
            checked: Settings.nightLightSchedule
            onToggled: (v) => SettingsStore.apply({ nightLightSchedule: v }, [])
        }
    }
}
