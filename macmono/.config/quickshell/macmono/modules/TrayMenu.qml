import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../core"
import "../components"

// Menu klik-kanan ikon tray (Discord, Steam, dll.), baca langsung dari dbusmenu lewat QsMenuOpener.
// Mendukung separator, checkbox/radio, ikon, submenu (dengan tombol Back), dan item disabled.
Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property bool shown: Sys.trayMenuOpen && Sys.trayMenuScreen === modelData.name
    property var stack: []                  // tumpukan handle submenu
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
    readonly property bool present: reveal.present
    onShownChanged: {
        if (shown) { stack = []; keys.forceActiveFocus(); }
    }
    function close() { Sys.trayMenuOpen = false; }

    // klik di mana pun di luar kartu (kiri/kanan) = tutup. Klik ikon tray lagi juga menutup.
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

    // area klip mulai di tepi bawah bar: kartu keluar seperti laci dari bar
    Item {
        x: 0
        y: Theme.barMargin + Theme.barHeight
        width: root.width
        height: root.height - y
        clip: true

        Rectangle {
            width: Math.max(190, Math.min(420, list.implicitWidth + 16))
            height: list.implicitHeight + 16
            y: Theme.drawerGap + 2 - (height + Theme.drawerGap + 2) * (1 - Math.min(1, root.anim))
            x: Math.max(8, Math.min(root.width - width - 8, Sys.trayMenuX - width + 18))
            radius: Theme.radiusCard
            color: Theme.popup
            border.width: Theme.borderThin
            border.color: Theme.lineStrong
            clip: true

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // klik di kartu jangan menutup

            ColumnLayout {
                id: list
                anchors { fill: parent; margins: Theme.space8 }
                spacing: Theme.space1

                // tombol kembali (hanya di dalam submenu)
                Rectangle {
                    visible: root.stack.length > 0
                    Layout.fillWidth: true; implicitHeight: Theme.trayBackHeight; radius: Theme.radiusXs
                    color: backMa.containsMouse ? Theme.tileHover : Theme.transparent
                    Text {
                        anchors { left: parent.left; leftMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                        text: "‹  Back"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
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
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.space6; rightMargin: Theme.space6 }
                            height: Theme.borderThin
                            color: Theme.tileMid
                        }

                        Rectangle {
                            visible: !row.sep
                            anchors.fill: parent
                            radius: Theme.radiusXs
                            color: (ma.containsMouse && row.modelData.enabled) ? Theme.tileHover : Theme.transparent

                            // checkbox / radio
                            Text {
                                id: chk
                                anchors { left: parent.left; leftMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                width: Theme.trayCheckWidth
                                text: row.modelData.buttonType === QsMenuButtonType.None ? ""
                                    : (row.modelData.checkState === Qt.Checked ? (row.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓") : "")
                                color: Theme.text
                                font.pixelSize: Theme.fontBody
                            }
                            IconImage {
                                id: ico
                                visible: row.modelData.icon !== ""
                                anchors { left: chk.right; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                                width: Theme.icon16; height: Theme.icon16
                                source: row.modelData.icon
                            }
                            Text {
                                id: lbl
                                anchors { left: ico.visible ? ico.right : chk.right; leftMargin: Theme.space8; right: parent.right; rightMargin: Theme.space30; verticalCenter: parent.verticalCenter }
                                text: row.modelData.text
                                elide: Text.ElideRight
                                color: row.modelData.enabled ? Theme.text : Theme.faint
                                font.family: Theme.font; font.pixelSize: Theme.fontBodyLg
                            }
                            Text {
                                visible: row.modelData.hasChildren
                                anchors { right: parent.right; rightMargin: Theme.space10; verticalCenter: parent.verticalCenter }
                                text: "›"
                                color: Theme.dim
                                font.pixelSize: Theme.fontHeading
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
