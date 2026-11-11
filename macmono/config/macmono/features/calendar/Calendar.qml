import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root
    readonly property int weatherIconSize: 30

    readonly property int calendarWidth: 370
    readonly property int calendarNavSize: 32
    readonly property int calendarWeekdayHeight: 30
    readonly property int calendarDayHeight: 40
    readonly property int calendarDayCircle: 40
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.calendarOpen && Sys.calendarScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real travel: reveal.travel
            readonly property bool present: reveal.present
            property var selectedDate: new Date()
            onShownChanged: {
                if (!shown) return;
                Sys.weather.ensureFresh();
                const d = new Date();
                viewYear = d.getFullYear(); viewMonth = d.getMonth();
                selectedDate = d;
            }

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight }
            mask: win.shown ? null : cardMask
            Region { id: cardMask; item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:calendar"
            WlrLayershell.layer: WlrLayer.Overlay

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                enabled: win.shown && !Sys.capturing
                onPressed: Sys.calendarOpen = false
            }

            property int viewYear: new Date().getFullYear()
            property int viewMonth: new Date().getMonth()
            function shiftMonth(n) {
                let m = viewMonth + n, y = viewYear;
                while (m < 0) { m += 12; y--; }
                while (m > 11) { m -= 12; y++; }
                viewMonth = m; viewYear = y;
            }
            readonly property var cells: {
                const first = new Date(viewYear, viewMonth, 1);
                const offset = (first.getDay() + 6) % 7;
                const out = [];
                const today = Sys.now;
                for (let i = 0; i < 42; i++) {
                    const d = new Date(viewYear, viewMonth, 1 - offset + i);
                    out.push({
                        date: d,
                        day: d.getDate(),
                        inMonth: d.getMonth() === viewMonth,
                        today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
                    });
                }
                return out;
            }
            function selectDate(date) {
                selectedDate = date;
                if (date.getFullYear() !== viewYear || date.getMonth() !== viewMonth) {
                    viewYear = date.getFullYear();
                    viewMonth = date.getMonth();
                }
            }
            Panel {
                id: card
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Theme.drawerGap }
                width: root.calendarWidth
                height: Math.min(col.implicitHeight + card.padding * 2, win.height - Theme.space8)
                travel: win.travel
                progress: win.anim

                Flickable {
                    id: flick
                    anchors.fill: parent
                    contentHeight: col.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: Theme.space16

                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Qt.formatDate(win.selectedDate, "dddd")
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightMedium
                            }
                            Text {
                                text: Qt.formatDate(win.selectedDate, "d MMMM yyyy")
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.font2xl; font.weight: Theme.weightSemibold; font.letterSpacing: Theme.trackTight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: Sys.weather.hasLocation
                            implicitHeight: wxCol.implicitHeight + 28
                            radius: Theme.radiusCard
                            color: Theme.tile

                            ColumnLayout {
                                id: wxCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
                                spacing: Theme.space12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.space12
                                    Glyph {
                                        visible: Sys.weather.available
                                        Layout.preferredWidth: root.weatherIconSize; Layout.preferredHeight: root.weatherIconSize
                                        name: Sys.weather.available ? Sys.weather.iconFor(Sys.weather.current.code, Sys.weather.current.isDay) : ""
                                        color: Theme.text
                                    }
                                    Text {
                                        text: Sys.weather.available ? Math.round(Sys.weather.current.temp) + "°" : "–"
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.font2xl; font.weight: Theme.weightSemibold
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: Sys.weather.available ? Sys.weather.describe(Sys.weather.current.code)
                                                : (Sys.weather.loading ? "Updating…" : (Sys.weather.error !== "" ? Sys.weather.error : "No data yet"))
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightMedium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: Sys.weather.placeName + (Sys.weather.available ? "  ·  Feels like " + Math.round(Sys.weather.current.feels) + "°" : "")
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontSm
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Row {
                                    id: wxRow
                                    Layout.fillWidth: true
                                    visible: Sys.weather.daily.length > 0
                                    readonly property real cw: width / Math.max(1, Sys.weather.daily.length)
                                    Repeater {
                                        model: Sys.weather.daily
                                        delegate: Column {
                                            id: wxDay
                                            required property var modelData
                                            width: wxRow.cw
                                            spacing: Theme.space4
                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: Qt.formatDate(new Date(wxDay.modelData.date + "T00:00:00"), "ddd")
                                                color: Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontXs
                                            }
                                            Glyph {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Theme.iconLg; height: Theme.iconLg
                                                name: Sys.weather.iconFor(wxDay.modelData.code, true)
                                                color: Theme.text
                                            }
                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: Math.round(wxDay.modelData.max) + "°"
                                                color: Theme.text
                                                font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightMedium
                                            }
                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: Math.round(wxDay.modelData.min) + "°"
                                                color: Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontSm
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Weather data by Open-Meteo.com"
                                    color: Theme.faint
                                    font.family: Theme.font; font.pixelSize: Theme.fontXs
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: calCol.implicitHeight + 28
                            radius: Theme.radiusCard
                            color: Theme.tile

                            ColumnLayout {
                                id: calCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
                                spacing: Theme.space12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: Qt.formatDate(new Date(win.viewYear, win.viewMonth, 1), "MMMM yyyy")
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                const d = new Date();
                                                win.viewYear = d.getFullYear();
                                                win.viewMonth = d.getMonth();
                                                win.selectedDate = d;
                                            }
                                        }
                                    }
                                    Repeater {
                                        model: [-1, 1]
                                        delegate: MouseArea {
                                            id: nav
                                            required property int modelData
                                            Layout.preferredWidth: root.calendarNavSize; Layout.preferredHeight: root.calendarNavSize
                                            hoverEnabled: true
                                            onClicked: win.shiftMonth(modelData)
                                            Rectangle { anchors.fill: parent; radius: Theme.radiusControl; color: nav.containsMouse ? Theme.tileHover : Theme.transparent }
                                            Glyph {
                                                anchors.centerIn: parent
                                                width: Theme.iconMd; height: Theme.iconMd
                                                name: "chevron"
                                                rotation: nav.modelData < 0 ? 90 : -90
                                                color: Theme.text
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    id: grid
                                    Layout.preferredWidth: calCol.width
                                    columns: 7
                                    readonly property real cw: calCol.width / 7
                                    Repeater {
                                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                        delegate: Text {
                                            required property string modelData
                                            width: grid.cw; height: root.calendarWeekdayHeight
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData
                                            color: Theme.faint
                                            font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightMedium
                                        }
                                    }
                                    Repeater {
                                        model: win.cells
                                        delegate: Item {
                                            id: dayCell
                                            required property var modelData
                                            width: grid.cw; height: root.calendarDayHeight
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: root.calendarDayCircle; height: root.calendarDayCircle; radius: Math.min(width, height) / 2
                                                color: dayArea.containsMouse && !isSelected ? Theme.tileHover : (isSelected ? Theme.accent : Theme.transparent)
                                                border.width: modelData.today && !isSelected ? 1 : 0
                                                border.color: Theme.dim
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day
                                                color: isSelected ? Theme.textOnAccent : (modelData.inMonth ? Theme.text : Theme.faint)
                                                font.family: Theme.font; font.pixelSize: Theme.fontLg
                                                font.weight: isSelected || modelData.today ? Theme.weightSemibold : Theme.weightRegular
                                            }
                                            readonly property bool isSelected: modelData.date.getFullYear() === win.selectedDate.getFullYear()
                                                && modelData.date.getMonth() === win.selectedDate.getMonth()
                                                && modelData.date.getDate() === win.selectedDate.getDate()
                                            MouseArea {
                                                id: dayArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: win.selectDate(dayCell.modelData.date)
                                            }
                                        }
                                    }
                                }
                            }
                        }


                    }
                }
            }
        }
    }
}
