import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../core"
import "../../shared/components"

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
    id: root

    readonly property int trayBackHeight: 30
    readonly property int trayCheckWidth: 14
    required property var modelData
    screen: modelData

    readonly property bool shown: Sys.trayMenuOpen && Sys.trayMenuScreen === modelData.name
    property var stack: []
    readonly property var currentHandle: stack.length > 0 ? stack[stack.length - 1] : (Sys.trayMenuItem ? Sys.trayMenuItem.menu : null)

    visible: present
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.transparent
    WlrLayershell.namespace: "macmono:traymenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Reveal { id: reveal; open: root.shown }
    readonly property real anim: reveal.progress
    readonly property real travel: reveal.travel
    readonly property bool present: reveal.present
    onShownChanged: {
        if (shown) { stack = []; keys.forceActiveFocus(); }
    }
    function close() { Sys.trayMenuOpen = false; }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: root.close()
    }
    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: root.close()
    }

    QsMenuOpener { id: opener; menu: root.currentHandle }

    Item {
        x: 0
        y: Theme.barMargin + Theme.barHeight
        width: root.width
        height: root.height - y
        clip: true

        Rectangle {
            width: Math.max(190, Math.min(420, list.implicitWidth + 16))
            height: list.implicitHeight + 16
            y: Theme.drawerGap + 2 + Theme.drawerOffset(height + Theme.drawerGap + 2, root.travel)
            x: Math.max(8, Math.min(root.width - width - 8, Sys.trayMenuX - width + 18))
            radius: Theme.radiusCard
            color: Theme.panel
            border.width: Theme.borderThin
            border.color: Theme.line
            clip: true

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            ColumnLayout {
                id: list
                anchors { fill: parent; margins: Theme.space8 }
                spacing: Theme.space2

                Rectangle {
                    visible: root.stack.length > 0
                    Layout.fillWidth: true; implicitHeight: root.trayBackHeight; radius: Theme.radiusControl
                    color: backMa.containsMouse ? Theme.tileHover : Theme.transparent
                    Text {
                        anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                        text: "‹  Back"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontMd
                    }
                    MouseArea {
                        id: backMa
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: root.stack = root.stack.slice(0, -1)
                    }
                }

                Repeater {
                    model: opener.children || []
                    delegate: Item {
                        id: row
                        required property var modelData
                        readonly property bool sep: modelData.isSeparator
                        Layout.fillWidth: true
                        implicitHeight: sep ? 9 : 30
                        implicitWidth: sep ? 0 : (lbl.implicitWidth + 64)

                        Rectangle {
                            visible: row.sep
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.space8; rightMargin: Theme.space8 }
                            height: Theme.borderThin
                            color: Theme.tile
                        }

                        Rectangle {
                            visible: !row.sep
                            anchors.fill: parent
                            radius: Theme.radiusControl
                            color: (ma.containsMouse && row.modelData.enabled) ? Theme.tileHover : Theme.transparent

                            Text {
                                id: chk
                                anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                width: root.trayCheckWidth
                                text: row.modelData.buttonType === QsMenuButtonType.None ? ""
                                    : (row.modelData.checkState === Qt.Checked ? (row.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓") : "")
                                color: Theme.text
                                font.pixelSize: Theme.fontSm
                            }
                            IconImage {
                                id: ico
                                visible: row.modelData.icon !== ""
                                anchors { left: chk.right; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                                width: Theme.iconMd; height: Theme.iconMd
                                source: row.modelData.icon
                            }
                            Text {
                                id: lbl
                                anchors { left: ico.visible ? ico.right : chk.right; leftMargin: Theme.space8; right: parent.right; rightMargin: Theme.space32; verticalCenter: parent.verticalCenter }
                                text: row.modelData.text
                                elide: Text.ElideRight
                                color: row.modelData.enabled ? Theme.text : Theme.faint
                                font.family: Theme.font; font.pixelSize: Theme.fontMd
                            }
                            Text {
                                visible: row.modelData.hasChildren
                                anchors { right: parent.right; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                                text: "›"
                                color: Theme.dim
                                font.pixelSize: Theme.fontLg
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (!row.modelData.enabled) return;
                                    if (row.modelData.hasChildren) { root.stack = root.stack.concat([row.modelData]); return; }
                                    row.modelData.triggered();
                                    root.close();
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
