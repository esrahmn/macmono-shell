import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../components"

// Super+/ : daftar shortcut macmono. Esc atau klik di mana saja untuk tutup.
Scope {
    readonly property var groups: [
        { title: "Shell", items: [
            ["Super", "Launcher & overview"], ["Super + Tab", "Overview"], ["Super + V", "Clipboard"],
            ["Super + .", "Emoji"], ["Super + N", "Control Center"], ["Super + A", "Calendar & notifications"],
            ["Super + M", "Media controls"], ["Super + /", "This cheatsheet"], ["Super + J", "Toggle bar"],
            ["Ctrl + Alt + Del", "Power menu"], ["Ctrl + Super + T", "Wallpaper picker"],
            ["Ctrl + Super + Alt + T", "Random wallpaper"], ["Ctrl + Super + R", "Restart shell"] ] },
        { title: "Capture", items: [
            ["Super + Shift + S", "Screenshot area"], ["Print", "Screenshot full screen"],
            ["Super + Shift + X", "Copy text (OCR)"],
            ["Super + Shift + C", "Color picker"] ] },
        { title: "Windows", items: [
            ["Super + Q", "Close window"], ["Super + F", "Fullscreen"], ["Super + D", "Maximize"],
            ["Super + Alt + Space", "Float / tile"], ["Super + P", "Pin"], ["Super + Arrows", "Move focus"],
            ["Super + Shift + Arrows", "Move window"], ["Super + Drag", "Move (left) / resize (right)"] ] },
        { title: "Workspaces", items: [
            ["Super + 1…0", "Go to workspace"], ["Super + Alt + 1…0", "Send window to workspace"],
            ["Ctrl + Super + ← / →", "Previous / next workspace"], ["Super + S", "Scratchpad"] ] },
        { title: "Apps & session", items: [
            ["Super + Enter", "Terminal"], ["Super + E", "Files"], ["Super + W", "Browser"],
            ["Super + C", "Code editor"], ["Super + I", "Settings"], ["Ctrl + Shift + Esc", "Task manager"],
            ["Super + L", "Lock"], ["Super + Shift + L", "Sleep"] ] },
        { title: "Media", items: [
            ["Super + Shift + P", "Play / pause"], ["Super + Shift + N", "Next track"],
            ["Super + Shift + B", "Previous track"], ["Super + Shift + M", "Mute speaker"],
            ["Super + Alt + M", "Mute microphone"] ] }
    ]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.cheatOpen && Sys.cheatScreen === modelData.name
            Reveal { id: reveal; open: win.shown }
            readonly property real anim: reveal.progress
            readonly property real closeHideThreshold: 0.03
            readonly property bool present: shown || anim > closeHideThreshold
            onShownChanged: if (shown) keys.forceActiveFocus()

            visible: present
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                color: Theme.veil
                opacity: win.anim
            }
            MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: Sys.cheatOpen = false }
            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => { Sys.cheatOpen = false; e.accepted = true; }   // tombol apa saja menutup
            }

            Rectangle {
                anchors.centerIn: parent
                width: content.width + Theme.cheatsheetCardPadding * 2
                height: content.height + Theme.cheatsheetCardPadding * 2
                radius: Theme.radiusPanel
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
                opacity: win.anim
            }

            Column {
                id: content
                anchors.centerIn: parent
                spacing: Theme.space22
                opacity: win.anim
                scale: Theme.openScaleFromModal + (1 - Theme.openScaleFromModal) * win.anim
                transform: Translate { y: -Theme.openDrop * (1 - win.anim) }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Keyboard shortcuts"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontHero; font.weight: Font.DemiBold
                }

                Grid {
                    columns: Theme.cheatsheetColumns
                    columnSpacing: Theme.cheatsheetColumnSpacing
                    rowSpacing: Theme.cheatsheetRowSpacing

                    Repeater {
                        model: groups
                        delegate: Column {
                            id: grp
                            required property var modelData
                            spacing: Theme.space8
                            width: Theme.cheatsheetGroupWidth

                            Text {
                                text: grp.modelData.title.toUpperCase()
                                color: Theme.faint
                                font.family: Theme.font; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold
                                font.letterSpacing: Theme.cheatsheetSectionLetterSpacing
                            }
                            Repeater {
                                model: grp.modelData.items
                                delegate: Item {
                                    id: row
                                    required property var modelData
                                    width: grp.width
                                    height: Theme.cheatsheetRowHeight
                                    Row {
                                        id: caps
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.space4
                                        Repeater {
                                            model: row.modelData[0].split(" + ")
                                            delegate: Rectangle {
                                                required property string modelData
                                                width: Math.max(Theme.cheatsheetKeycapMinWidth, capText.implicitWidth + Theme.cheatsheetKeycapPadding)
                                                height: Theme.cheatsheetKeycapHeight
                                                radius: Theme.radiusKey
                                                color: Theme.tileMid
                                                border.width: Theme.borderThin; border.color: Theme.lineStrong
                                                Text {
                                                    id: capText
                                                    anchors.centerIn: parent
                                                    text: parent.modelData
                                                    color: Theme.text
                                                    font.family: Theme.font; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; left: caps.right; leftMargin: Theme.space12 }
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                        text: row.modelData[1]
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontBody
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Press any key to close"
                    color: Theme.faint
                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                }
            }
        }
    }
}
