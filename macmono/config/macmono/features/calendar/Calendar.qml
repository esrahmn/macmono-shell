import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.calendarOpen && Sys.calendarScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
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
            function ago(t) {
                const s = Math.max(0, Math.floor((Sys.now.getTime() - t) / 1000));
                if (s < 60) return "now";
                if (s < 3600) return Math.floor(s / 60) + "m";
                if (s < 86400) return Math.floor(s / 3600) + "h";
                return Math.floor(s / 86400) + "d";
            }

            Item {
                id: body
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Theme.drawerGap }
                width: Theme.calendarWidth
                height: card.height
                transform: Translate { y: -(body.height + Theme.drawerGap) * (1 - Math.min(1, win.anim)) }

                Rectangle {
                    id: card
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.min(col.implicitHeight + 32, win.height - Theme.space8)
                    radius: Theme.radiusPanel
                    color: Theme.panel
                    border.width: Theme.borderThin
                    border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                }

                Flickable {
                    id: flick
                    anchors { top: card.top; left: card.left; right: card.right; bottom: card.bottom; margins: Theme.space16 }
                    opacity: win.anim
                    contentHeight: col.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: Theme.space14

                        ColumnLayout {
                            spacing: Theme.space0
                            Text {
                                text: Qt.formatDate(win.selectedDate, "dddd")
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.Medium
                            }
                            Text {
                                text: Qt.formatDate(win.selectedDate, "d MMMM yyyy")
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.panelTitleSize; font.weight: Font.DemiBold; font.letterSpacing: Theme.panelTitleTracking
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
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space14 }
                                spacing: Theme.space10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.space12
                                    Glyph {
                                        visible: Sys.weather.available
                                        Layout.preferredWidth: Theme.icon30; Layout.preferredHeight: Theme.icon30
                                        name: Sys.weather.available ? Sys.weather.iconFor(Sys.weather.current.code, Sys.weather.current.isDay) : ""
                                        color: Theme.text
                                    }
                                    Text {
                                        text: Sys.weather.available ? Math.round(Sys.weather.current.temp) + "°" : "–"
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontDisplay; font.weight: Font.DemiBold
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.space0
                                        Text {
                                            Layout.fillWidth: true
                                            text: Sys.weather.available ? Sys.weather.describe(Sys.weather.current.code)
                                                : (Sys.weather.loading ? "Updating…" : (Sys.weather.error !== "" ? Sys.weather.error : "No data yet"))
                                            color: Theme.text
                                            font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: Sys.weather.placeName + (Sys.weather.available ? "  ·  Feels like " + Math.round(Sys.weather.current.feels) + "°" : "")
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontBody
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
                                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                            }
                                            Glyph {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Theme.icon20; height: Theme.icon20
                                                name: Sys.weather.iconFor(wxDay.modelData.code, true)
                                                color: Theme.text
                                            }
                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: Math.round(wxDay.modelData.max) + "°"
                                                color: Theme.text
                                                font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.Medium
                                            }
                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: Math.round(wxDay.modelData.min) + "°"
                                                color: Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Weather data by Open-Meteo.com"
                                    color: Theme.muted
                                    font.family: Theme.font; font.pixelSize: Theme.fontSmall
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
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space14 }
                                spacing: Theme.space10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: Qt.formatDate(new Date(win.viewYear, win.viewMonth, 1), "MMMM yyyy")
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
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
                                            Layout.preferredWidth: Theme.calendarNavSize; Layout.preferredHeight: Theme.calendarNavSize
                                            hoverEnabled: true
                                            onClicked: win.shiftMonth(modelData)
                                            Rectangle { anchors.fill: parent; radius: Theme.radiusXs; color: nav.containsMouse ? Theme.tileHover : Theme.transparent }
                                            Glyph {
                                                anchors.centerIn: parent
                                                width: Theme.icon15; height: Theme.icon15
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
                                            width: grid.cw; height: Theme.calendarWeekdayHeight
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData
                                            color: Theme.faint
                                            font.family: Theme.font; font.pixelSize: Theme.fontBody; font.weight: Font.Medium
                                        }
                                    }
                                    Repeater {
                                        model: win.cells
                                        delegate: Item {
                                            id: dayCell
                                            required property var modelData
                                            width: grid.cw; height: Theme.calendarDayHeight
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Theme.calendarDayCircle; height: Theme.calendarDayCircle; radius: Math.min(width, height) / 2
                                                color: dayArea.containsMouse && !isSelected ? Theme.tileHover : (isSelected ? Theme.inverse : Theme.transparent)
                                                border.width: modelData.today && !isSelected ? 1 : 0
                                                border.color: Theme.dim
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day
                                                color: isSelected ? Theme.inverseText : (modelData.inMonth ? Theme.text : Theme.faint)
                                                font.family: Theme.font; font.pixelSize: Theme.fontTitle
                                                font.weight: isSelected || modelData.today ? Font.DemiBold : Font.Normal
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

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "NOTIFICATIONS"
                                color: Theme.labelCapsText
                                font.family: Theme.font; font.pixelSize: Theme.labelCapsSize; font.weight: Font.DemiBold
                                font.letterSpacing: Theme.labelCapsTracking
                            }
                            MouseArea {
                                id: dndBtn
                                Layout.preferredWidth: Theme.calendarSmallButton; Layout.preferredHeight: Theme.calendarSmallButton
                                hoverEnabled: true
                                onClicked: Sys.dnd = !Sys.dnd
                                Rectangle {
                                    anchors.fill: parent; radius: Math.min(width, height) / 2
                                    color: Sys.dnd ? Theme.inverse : (dndBtn.containsMouse ? Theme.tileHover : Theme.transparent)
                                }
                                Glyph {
                                    anchors.centerIn: parent; width: Theme.icon14; height: Theme.icon14
                                    name: "moon"
                                    color: Sys.dnd ? Theme.inverseText : Theme.text
                                }
                            }
                            MouseArea {
                                id: clearBtn
                                visible: Sys.notifHistory.length > 0
                                Layout.preferredWidth: clearText.implicitWidth + 18; Layout.preferredHeight: Theme.calendarClearHeight
                                hoverEnabled: true
                                onClicked: Sys.clearNotifs()
                                Rectangle { anchors.fill: parent; radius: Math.min(width, height) / 2; color: clearBtn.containsMouse ? Theme.tileHover : Theme.tile }
                                Text {
                                    id: clearText
                                    anchors.centerIn: parent
                                    text: "Clear all"
                                    color: Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                }
                            }
                        }

                        Text {
                            visible: Sys.notifHistory.length === 0
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space6; Layout.bottomMargin: Theme.space10
                            horizontalAlignment: Text.AlignHCenter
                            text: Sys.dnd ? "Do Not Disturb is on" : "No notifications"
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontBody
                        }

                        Repeater {
                            model: Sys.notifHistory
                            delegate: Rectangle {
                                id: nrow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: ncol.implicitHeight + 20
                                radius: Theme.radiusCard
                                color: nArea.containsMouse ? Theme.tileHover : Theme.tile

                                ColumnLayout {
                                    id: ncol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space10; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                                    spacing: Theme.space2
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: nrow.modelData.app || "Notification"
                                            color: Theme.dim
                                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                        }
                                        Text {
                                            text: nArea.containsMouse ? "✕" : win.ago(nrow.modelData.time)
                                            color: Theme.faint
                                            font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: nrow.modelData.summary
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg; font.weight: Font.DemiBold
                                    }
                                    Text {
                                        visible: text !== ""
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        text: nrow.modelData.body
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                                    }
                                }
                                MouseArea {
                                    id: nArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Sys.removeNotif(nrow.modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
