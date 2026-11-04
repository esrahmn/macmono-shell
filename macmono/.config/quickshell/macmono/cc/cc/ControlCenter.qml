import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "../core"
import "../ui"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.ccOpen && Sys.ccScreen === modelData.name
            property real anim: 0
            NumberAnimation { id: openAnim; target: win; property: "anim"; from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
            onShownChanged: { if (shown) openAnim.restart(); else { openAnim.stop(); anim = 0; } }

            // Buka: animasi di QML. Tutup: langsung hilang (bersih, tanpa sisa blur),
            // sama seperti overview end4. Animasi layer Hyprland dimatiin lewat no_anim.
            visible: shown
            anchors { top: true; right: true }
            margins { top: Theme.barMargin + Theme.barHeight + 8; right: Theme.space8 }
            implicitWidth: 500
            // Tinggi window TETAP (nggak di-resize tiap frame, itu yang bikin animasi patah-patah).
            // Yang berubah tingginya cuma kartu di dalamnya; area transparan di luar kartu tembus klik.
            implicitHeight: modelData.height - (Theme.barMargin + Theme.barHeight + 8) - 8
            mask: Region { item: card }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:cc"
            WlrLayershell.layer: WlrLayer.Overlay
            // Ikuti pola sidebar end4: fokus on-demand saat terbuka, exclusive saat mengetik password.
            WlrLayershell.keyboardFocus: !shown ? WlrKeyboardFocus.None
                : wifiList.typing ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.OnDemand

            property string expanded: ""   // "", "wifi", "bt", "sound", "tools", "power", "profile"
            function toggleExpand(name) {
                expanded = expanded === name ? "" : name;
                if (expanded === "wifi") Sys.scanWifi();
            }
            onVisibleChanged: if (!visible) expanded = ""

            // Selama ngetik password / nyambung Wi-Fi, grab dilepas dulu: ganti keyboardFocus ke
            // Exclusive bikin Hyprland refocus (grab ke-clear), dan nmcli bisa munculin dialog
            // secret agent yang nyolong fokus. Dua-duanya dulu bikin CC langsung nutup.
            readonly property bool holdOpen: wifiList.typing || Sys.wifiConnecting !== ""

            // Grab dimatiin selama screenshot, biar CC nggak nutup pas pemilih area muncul
            HyprlandFocusGrab {
                windows: [win]
                active: win.shown && !Sys.capturing && !win.holdOpen
                onCleared: if (!Sys.capturing && !win.holdOpen && !win.active) Sys.closeCC()
            }

            // Pemain yang sedang diputar dipilih dulu; tombol media dapat menggantinya.
            property int playerIndex: -1
            readonly property var player: Sys.mediaPlayer(Mpris.players.values, playerIndex)

            // Panel turun sedikit + mengecil dari pojok kanan atas. Latar nggak di-fade sampai 0
            // (alpha minimal ~0.25 > ignore_alpha 0.2), jadi blur Hyprland nggak ketinggalan.
            Item {
                id: body
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: card.height
                transformOrigin: Item.TopRight
                scale: 0.95 + 0.05 * win.anim
                opacity: Theme.openFromPanel + (1 - Theme.openFromPanel) * win.anim
                transform: Translate { y: -8 * (1 - win.anim) }

            Rectangle {
                id: card
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: Math.min(col.implicitHeight + 32, win.height)
                Behavior on height {
                    NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut }
                }
                radius: Theme.radiusXl
                color: Theme.panel
                border.width: Theme.borderThin
                border.color: Theme.line
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
                    spacing: Theme.space12

                    // ============ header: profil + tools + power ============
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space6

                        // profil: lingkaran inisial + nama + tanggal
                        Rectangle {
                            implicitWidth: 40; implicitHeight: 40; radius: Math.min(width, height) / 2
                            color: Theme.tile
                            border.width: Theme.borderThin; border.color: Theme.line
                            Image {
                                id: avatarImg
                                anchors.fill: parent
                                source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 72; sourceSize.height: 72
                                asynchronous: true
                                visible: false
                            }
                            Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                            MultiEffect {
                                anchors.fill: parent
                                visible: avatarImg.status === Image.Ready
                                source: avatarImg
                                maskEnabled: true
                                maskSource: avatarMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                            Text {
                                visible: avatarImg.status !== Image.Ready
                                anchors.centerIn: parent
                                text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontHeading; font.weight: Font.DemiBold
                            }
                        }
                        ColumnLayout {
                            spacing: Theme.space0
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: Quickshell.env("USER") || "user"
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                            }
                        }

                        // tombol ⋯ (tools) dan power: dua lingkaran sama besar
                        Repeater {
                            model: [ { key: "tools", glyph: "more" }, { key: "power", glyph: "power" } ]
                            delegate: Rectangle {
                                id: hb
                                required property var modelData
                                readonly property bool on: win.expanded === modelData.key
                                implicitWidth: 38; implicitHeight: 38
                                radius: Math.min(width, height) / 2
                                scale: hbArea.pressed ? Theme.buttonPressedScale : 1
                                color: on ? Theme.inverse : (hbArea.containsMouse ? Theme.tileHover : Theme.tile)
                                Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                Glyph {
                                    anchors.centerIn: parent; width: 18; height: 18
                                    name: hb.modelData.glyph
                                    color: hb.on ? Theme.inverseText : Theme.text
                                }
                                MouseArea {
                                    id: hbArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.toggleExpand(hb.modelData.key)
                                }
                            }
                        }
                    }

                    ToolsPanel { open: win.expanded === "tools" }
                    PowerActions { open: win.expanded === "power" }

                    // ============ toggle: kartu jaringan (kiri) + Focus / Night / Mic (kanan) ============
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12; rowSpacing: 12

                        // kiri: Wi-Fi, Bluetooth, Keep Awake sebagai baris. Ikon bulat = toggle, sisa baris = buka daftar.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            implicitHeight: netCol.implicitHeight + 16
                            radius: Theme.radiusLarge
                            color: Theme.tile

                            Column {
                                id: netCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }
                                spacing: Theme.space2
                                Repeater {
                                    model: [
                                        { key: "wifi", glyph: "wifi",      title: "Wi-Fi",
                                          on: Sys.wifiOn, sub: Sys.wifiOn ? (Sys.wifiName || "On") : "Off", list: true },
                                        { key: "bt",   glyph: "bluetooth", title: "Bluetooth",
                                          on: Sys.btOn, sub: !Sys.btAvailable ? "Unavailable" : (Sys.btOn ? (Sys.btConnected ? Sys.btConnected.name : "On") : "Off"), list: true },
                                        { key: "awake", glyph: "coffee",   title: "Keep Awake",
                                          on: Sys.keepAwake, sub: Sys.keepAwake ? "On" : "Off", list: false }
                                    ]
                                    delegate: Rectangle {
                                        id: nr
                                        required property var modelData
                                        readonly property bool open: win.expanded === modelData.key
                                        width: netCol.width
                                        height: 56
                                        radius: Theme.radiusCard
                                        scale: rowArea.pressed ? Theme.buttonPressedScale : 1
                                        color: open ? Theme.tileMid : (rowArea.containsMouse ? Theme.tileFaint : Theme.transparent)
                                        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                        Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }

                                        function toggle() {
                                            if (modelData.key === "wifi") Sys.toggleWifi();
                                            else if (modelData.key === "bt") Sys.toggleBt();
                                            else Sys.keepAwake = !Sys.keepAwake;
                                        }

                                        MouseArea {   // seluruh baris: buka daftar (Wi-Fi/BT) atau toggle (Keep Awake)
                                            id: rowArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: nr.modelData.list ? win.toggleExpand(nr.modelData.key) : nr.toggle()
                                        }
                                        Rectangle {   // ikon bulat = tombol on/off
                                            id: dot
                                            anchors { left: parent.left; leftMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                            width: 36; height: 36; radius: Math.min(width, height) / 2
                                            scale: dotArea.pressed ? Theme.buttonPressedScale : 1
                                            color: nr.modelData.on ? Theme.inverse : (dotArea.containsMouse ? Theme.tileStrong : Theme.tileMid)
                                            Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                            Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                            Glyph {
                                                anchors.centerIn: parent
                                                width: 18; height: 18
                                                name: nr.modelData.glyph
                                                color: nr.modelData.on ? Theme.inverseText : Theme.text
                                            }
                                            MouseArea { id: dotArea; anchors.fill: parent; hoverEnabled: true; onClicked: nr.toggle() }
                                        }
                                        Column {
                                            anchors { left: dot.right; leftMargin: Theme.space12; right: chev.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                                            Text {
                                                width: parent.width; elide: Text.ElideRight
                                                text: nr.modelData.title
                                                color: Theme.text
                                                font.family: Theme.font; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold
                                            }
                                            Text {
                                                width: parent.width; elide: Text.ElideRight
                                                text: nr.modelData.sub
                                                color: Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                                            }
                                        }
                                        Glyph {
                                            id: chev
                                            visible: nr.modelData.list
                                            anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                            width: visible ? 13 : 0; height: 13
                                            name: "chevron"
                                            rotation: nr.open ? 180 : -90
                                            color: Theme.dim
                                            Behavior on rotation { NumberAnimation { duration: Theme.animBase } }
                                        }
                                    }
                                }
                            }
                        }

                        // kanan: Focus ringkas + power profile, lalu Night Light & Mic
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            spacing: Theme.space12

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Theme.space8

                                Rectangle {
                                    Layout.preferredWidth: 72
                                    Layout.fillHeight: true
                                    radius: Theme.radiusLarge
                                    scale: focusArea.pressed ? Theme.buttonPressedScale : 1
                                    color: Sys.dnd ? Theme.inverse : (focusArea.containsMouse ? Theme.tileHover : Theme.tile)
                                    Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                    Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                    MouseArea {
                                        id: focusArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Sys.dnd = !Sys.dnd
                                    }
                                    Glyph {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        name: "moon"
                                        color: Sys.dnd ? Theme.inverseText : Theme.text
                                    }
                                }

                                Rectangle {
                                    id: profileButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Theme.radiusLarge
                                    readonly property bool active: Sys.profile !== PowerProfile.PowerSaver
                                    scale: profileArea.pressed ? Theme.buttonPressedScale : 1
                                    color: active ? Theme.inverse : (profileArea.containsMouse ? Theme.tileHover : Theme.tile)
                                    Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                    Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                    Row {
                                        anchors { left: parent.left; right: parent.right; leftMargin: Theme.space12; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                        spacing: Theme.space10
                                        Glyph {
                                            id: profileGlyph
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 18; height: 18
                                            name: Sys.profileGlyph
                                            color: profileButton.active ? Theme.inverseText : Theme.text
                                            onNameChanged: profileGlyphAnimation.restart()
                                            SequentialAnimation {
                                                id: profileGlyphAnimation
                                                NumberAnimation { target: profileGlyph; property: "opacity"; to: 0; duration: Theme.animPress }
                                                NumberAnimation { target: profileGlyph; property: "opacity"; to: 1; duration: Theme.animHover }
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.space2
                                            Text {
                                                text: "Power profile"
                                                color: profileButton.active ? Theme.inverseDim : Theme.dim
                                                font.family: Theme.font; font.pixelSize: Theme.fontSmall
                                            }
                                            Text {
                                                id: profileLabel
                                                text: Sys.profileLabel
                                                color: profileButton.active ? Theme.inverseText : Theme.text
                                                font.family: Theme.font; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold
                                                onTextChanged: profileLabelAnimation.restart()
                                                SequentialAnimation {
                                                    id: profileLabelAnimation
                                                    NumberAnimation { target: profileLabel; property: "opacity"; to: 0; duration: Theme.animPress }
                                                    NumberAnimation { target: profileLabel; property: "opacity"; to: 1; duration: Theme.animHover }
                                                }
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: profileArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Sys.cycleProfile()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space12
                                Repeater {
                                    model: [
                                        { key: "night", glyph: "sunhalf", label: "Night", on: Sys.nightLight },
                                        { key: "mic", glyph: Sys.micMuted ? "mic-off" : "mic", label: "Mic", on: !Sys.micMuted }
                                    ]
                                    delegate: Rectangle {
                                        id: sq
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 92
                                        radius: Theme.radiusLarge
                                        scale: sqArea.pressed ? Theme.buttonPressedScale : 1
                                        color: modelData.on ? Theme.inverse : (sqArea.containsMouse ? Theme.tileHover : Theme.tile)
                                        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                        Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: Theme.space6
                                            Glyph {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 22; height: 22
                                                name: sq.modelData.glyph
                                                color: sq.modelData.on ? Theme.inverseText : Theme.text
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: sq.modelData.label
                                                color: sq.modelData.on ? Theme.inverseText : Theme.textSoft
                                                font.family: Theme.font; font.pixelSize: Theme.fontBody
                                                font.weight: sq.modelData.on ? Font.DemiBold : Font.Normal
                                            }
                                        }
                                        MouseArea {
                                            id: sqArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: sq.modelData.key === "night" ? Sys.toggleNightLight() : Sys.toggleMic()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    WifiList {
                        id: wifiList
                        open: win.expanded === "wifi"
                        Layout.fillWidth: true
                    }
                    BtList {
                        open: win.expanded === "bt"
                        Layout.fillWidth: true
                    }

                    // ============ slider: kecerahan + volume dalam satu kartu ============
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: sliderCol.implicitHeight + 24
                        radius: Theme.radiusLarge
                        color: Theme.tile

                        ColumnLayout {
                            id: sliderCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
                            spacing: Theme.space10

                            RowLayout {
                                visible: Sys.brightnessOk
                                Layout.fillWidth: true
                                spacing: Theme.space10
                                SliderBar {
                                    Layout.fillWidth: true
                                    icon: "sun"
                                    value: Sys.brightness
                                    onMoved: (v) => Sys.setBrightness(v)
                                }
                                Text {
                                    Layout.preferredWidth: 38
                                    horizontalAlignment: Text.AlignRight
                                    text: Math.round(Sys.brightness * 100) + "%"
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                                }
                                Item { Layout.preferredWidth: 26 }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space10
                                SliderBar {
                                    Layout.fillWidth: true
                                    icon: Sys.muted ? "mute" : "volume"
                                    value: Sys.muted ? 0 : Sys.volume
                                    onMoved: (v) => Sys.setVolume(v)
                                }
                                Text {
                                    Layout.preferredWidth: 38
                                    horizontalAlignment: Text.AlignRight
                                    text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
                                    color: Theme.dim
                                    font.family: Theme.font; font.pixelSize: Theme.fontBody
                                }
                                MouseArea {   // pilih output suara
                                    id: outBtn
                                    Layout.preferredWidth: 26; Layout.preferredHeight: 26
                                    hoverEnabled: true
                                    onClicked: win.toggleExpand("sound")
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.min(width, height) / 2
                                        scale: outBtn.pressed ? Theme.buttonPressedScale : 1
                                        color: outBtn.containsMouse || win.expanded === "sound" ? Theme.tileMid : Theme.transparent
                                        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Theme.easeOut } }
                                        Behavior on scale { NumberAnimation { duration: Theme.animPress; easing.type: Theme.easeOut } }
                                    }
                                    Glyph {
                                        anchors.centerIn: parent
                                        width: 13; height: 13
                                        name: "chevron"
                                        rotation: win.expanded === "sound" ? 180 : -90
                                        color: Theme.text
                                        Behavior on rotation { NumberAnimation { duration: Theme.animBase } }
                                    }
                                }
                            }
                            DetailList {
                                open: win.expanded === "sound"
                                Layout.fillWidth: true
                                color: Theme.tileFaint
                                emptyText: "No output devices"
                                items: Sys.outputDevices.map(n => ({
                                    label: Sys.nodeLabel(n),
                                    sub: "",
                                    on: n === Sys.sink,
                                    ref: n
                                }))
                                onPicked: (item) => Sys.setOutput(item.ref)
                            }
                        }
                    }

                    MediaCard {
                        player: win.player
                        players: Mpris.players.values
                        panelShown: win.shown
                        onPlayerChangeRequested: (index) => win.playerIndex = index
                    }

                    BatteryStatus {}
                }
            }
            } // body
        }
    }
}
