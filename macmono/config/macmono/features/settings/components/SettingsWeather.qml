import QtQuick
import "../../../core"

Column {
    id: root
    readonly property var svc: Sys.weather
    spacing: SettingsMetrics.settingsGroupSpacing

    function pick(r) {
        SettingsStore.apply({ weatherName: r.label, weatherLat: r.lat, weatherLon: r.lon }, []);
        svc.results = [];
        field.text = "";
    }

    SettingsText {
        text: "LOCATION"
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
        leftPadding: SettingsMetrics.settingsRowPadX
    }

    Rectangle {
        width: parent.width
        height: locRow.height + SettingsMetrics.settingsRowPadY * 2
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.line
        Row {
            id: locRow
            x: SettingsMetrics.settingsRowPadX
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space12
            SettingsText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.parent.width - SettingsMetrics.settingsRowPadX * 2 - (clearBtn.visible ? clearBtn.width + Theme.space12 : 0)
                text: root.svc.hasLocation ? root.svc.placeName : "No location set. Weather is off."
                color: root.svc.hasLocation ? Theme.text : Theme.dim
                elide: Text.ElideRight
            }
            SettingsButton {
                id: clearBtn
                visible: root.svc.hasLocation
                anchors.verticalCenter: parent.verticalCenter
                label: "Remove"
                onClicked: SettingsStore.apply({}, ["weatherName", "weatherLat", "weatherLon"])
            }
        }
    }

    Rectangle {
        width: parent.width
        height: SettingsMetrics.settingsSearchHeight
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: field.activeFocus ? Theme.line : Theme.line
        TextInput {
            id: field
            anchors { fill: parent; leftMargin: SettingsMetrics.settingsRowPadX; rightMargin: SettingsMetrics.settingsRowPadX }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontMd
            selectionColor: Theme.tileHover
            selectedTextColor: Theme.text
            clip: true
            onAccepted: root.svc.search(text)
            Keys.onEscapePressed: (event) => { if (text !== "") { text = ""; root.svc.results = []; event.accepted = true; } else event.accepted = false; }
            SettingsText {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: !field.text
                text: "City name, then press Enter"
                color: Theme.faint
            }
        }
    }

    SettingsText {
        visible: root.svc.searching || root.svc.searchError !== ""
        leftPadding: SettingsMetrics.settingsRowPadX
        text: root.svc.searching ? "Searching…" : root.svc.searchError
        color: Theme.dim
    }

    Column {
        visible: root.svc.results.length > 0
        width: parent.width
        spacing: Theme.space8
        Repeater {
            model: root.svc.results
            delegate: Rectangle {
                id: res
                required property var modelData
                width: parent.width
                height: SettingsMetrics.settingsListRowHeight
                radius: Theme.radiusCard
                color: resArea.containsMouse ? Theme.tileHover : Theme.tile
                border.width: Theme.borderThin
                border.color: Theme.line
                SettingsText {
                    anchors { fill: parent; leftMargin: SettingsMetrics.settingsRowPadX; rightMargin: SettingsMetrics.settingsRowPadX }
                    verticalAlignment: Text.AlignVCenter
                    text: res.modelData.label
                    elide: Text.ElideRight
                }
                MouseArea { id: resArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pick(res.modelData) }
            }
        }
    }

    SettingsText {
        text: "UNITS"
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
        leftPadding: SettingsMetrics.settingsRowPadX
    }
    Row {
        x: SettingsMetrics.settingsRowPadX
        spacing: Theme.space8
        SettingsChoice { label: "Celsius (°C)"; on: root.svc.unit === "c"; onPicked: SettingsStore.apply({ weatherUnit: "c" }, []) }
        SettingsChoice { label: "Fahrenheit (°F)"; on: root.svc.unit === "f"; onPicked: SettingsStore.apply({ weatherUnit: "f" }, []) }
    }

    SettingsText {
        width: parent.width
        leftPadding: SettingsMetrics.settingsRowPadX
        rightPadding: SettingsMetrics.settingsRowPadX
        wrapMode: Text.Wrap
        text: "Privacy: searching and weather updates contact open-meteo.com. Only the city name you type and its coordinates are sent.\nData refreshes when the calendar or this page opens. Weather data by Open-Meteo.com."
        color: SettingsMetrics.settingsDescText
        font.pixelSize: Theme.fontSm
    }
}
