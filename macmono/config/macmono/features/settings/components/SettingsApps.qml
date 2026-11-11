import QtQuick
import Quickshell
import "../../../core"
import "../../../shared/components"

Column {
    id: root

    readonly property int settingsPickMax: 8
    readonly property var svc: Sys.autostart
    spacing: 0

    property bool adding: false
    property bool showInert: false

    readonly property var liveEntries: svc.entries.filter(e => e.relevant !== false)
    readonly property var inertEntries: svc.entries.filter(e => e.relevant === false)

    readonly property var matches: {
        if (!adding) return [];
        const have = ({});
        for (const e of svc.entries) have[svc.baseName(e.userPath !== "" ? e.userPath : e.systemPath)] = true;
        const q = field.text.trim().toLowerCase();
        const out = [];
        for (const a of DesktopEntries.applications.values) {
            if (a.noDisplay || have[a.id + ".desktop"]) continue;
            if (q !== "" && !(a.name.toLowerCase().includes(q) || a.id.toLowerCase().includes(q))) continue;
            out.push(a);
        }
        out.sort((x, y) => {
            const m = x.name.toLowerCase(), n = y.name.toLowerCase();
            return m < n ? -1 : (m > n ? 1 : 0);
        });
        return out.slice(0, root.settingsPickMax);
    }

    function label(n) { return String(n).replace(/\s*\(disabled by macmono\)\s*$/i, ""); }
    function add(entry) { svc.addApp(entry.id); adding = false; }

    onVisibleChanged: { if (visible) svc.refresh(); else adding = false; }
    onAddingChanged: if (adding) { field.text = ""; Qt.callLater(() => field.forceActiveFocus()); }
    Component.onCompleted: svc.refresh()

    component CapsLabel: SettingsText {
        leftPadding: SettingsMetrics.settingsRowPadX
        color: Theme.dim
        font.pixelSize: Theme.fontXs
        font.weight: Theme.weightSemibold
        font.letterSpacing: Theme.trackCaps
    }

    component Note: SettingsText {
        width: root.width
        topPadding: Theme.space8
        bottomPadding: Theme.space4
        leftPadding: SettingsMetrics.settingsRowPadX
        rightPadding: SettingsMetrics.settingsRowPadX
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.pixelSize: Theme.fontSm
    }

    component EntryRow: SettingsRow {
        id: entryRow
        required property var modelData
        required property int index

        width: root.width
        title: root.label(modelData.name)
        separator: index > 0
        resettable: modelData.removable === true
        resetLabel: modelData.systemPath === "" ? "Remove" : "Reset"
        onResetRequested: root.svc.removeUserEntry(modelData)
        opacity: modelData.relevant === false ? Theme.opacityDim : 1

        SettingsToggle {
            checked: entryRow.modelData.enabled
            onToggled: (v) => root.svc.setEnabled(entryRow.modelData, v)
        }
    }

    Item {
        width: root.width
        height: SettingsMetrics.settingsButtonHeight

        CapsLabel {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "STARTUP APPLICATIONS"
        }
        SettingsButton {
            anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
            label: root.adding ? "Close" : "+ Add"
            onClicked: root.adding = !root.adding
        }
    }

    Column {
        visible: root.adding
        width: root.width
        spacing: Theme.space8
        topPadding: Theme.space8

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
                onAccepted: if (root.matches.length > 0) root.add(root.matches[0])
                Keys.onEscapePressed: (event) => {
                    if (text !== "") { text = ""; event.accepted = true; }
                    else if (root.adding) { root.adding = false; event.accepted = true; }
                    else event.accepted = false;
                }
                SettingsText {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !field.text
                    text: "Search installed apps"
                    color: Theme.faint
                }
            }
        }

        Repeater {
            model: root.matches
            delegate: Rectangle {
                id: res
                required property var modelData
                width: parent.width
                height: SettingsMetrics.settingsListRowHeight
                radius: Theme.radiusCard
                color: resArea.containsMouse ? Theme.tileHover : Theme.tile
                border.width: Theme.borderThin
                border.color: Theme.line
                Behavior on color { TweenColor { duration: Theme.durFast } }
                SettingsText {
                    anchors { fill: parent; leftMargin: SettingsMetrics.settingsRowPadX; rightMargin: SettingsMetrics.settingsRowPadX }
                    verticalAlignment: Text.AlignVCenter
                    text: res.modelData.name
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: resArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.add(res.modelData)
                }
            }
        }

        SettingsText {
            visible: root.matches.length === 0
            leftPadding: SettingsMetrics.settingsRowPadX
            text: field.text.trim() === "" ? "No other apps found." : "No apps match."
            color: Theme.dim
        }
    }

    Note { text: "Start automatically when you log in. Changes apply the next time you log in." }

    SettingsText {
        visible: root.svc.error !== ""
        width: root.width
        leftPadding: SettingsMetrics.settingsRowPadX
        rightPadding: SettingsMetrics.settingsRowPadX
        topPadding: Theme.space4
        wrapMode: Text.WordWrap
        text: root.svc.error
        font.pixelSize: Theme.fontSm
    }

    SettingsText {
        visible: root.liveEntries.length === 0
        width: root.width
        leftPadding: SettingsMetrics.settingsRowPadX
        topPadding: Theme.space8
        text: (root.svc.loading && root.svc.entries.length === 0) ? "Reading startup entries…" : "No startup applications for Hyprland yet."
        color: Theme.dim
    }

    Repeater {
        model: root.liveEntries
        delegate: EntryRow {}
    }

    Item {
        visible: root.inertEntries.length > 0
        width: root.width
        height: visible ? SettingsMetrics.settingsGroupSpacing + SettingsMetrics.settingsListRowHeight : 0

        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: SettingsMetrics.settingsListRowHeight

            CapsLabel {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "NOT USED ON HYPRLAND  ·  " + root.inertEntries.length
                color: inertArea.containsMouse ? Theme.text : Theme.dim
            }
            Glyph {
                anchors { right: parent.right; rightMargin: SettingsMetrics.settingsRowPadX; verticalCenter: parent.verticalCenter }
                width: Theme.iconSm
                height: Theme.iconSm
                name: "chevron"
                color: Theme.dim
                rotation: root.showInert ? 0 : -90
                Behavior on rotation { Tween { duration: Theme.durFast } }
            }
            MouseArea {
                id: inertArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showInert = !root.showInert
            }
        }
    }

    Note {
        visible: root.showInert && root.inertEntries.length > 0
        text: "These only start on other desktops, so they do nothing here."
    }

    Repeater {
        model: root.showInert ? root.inertEntries : []
        delegate: EntryRow {}
    }
}
