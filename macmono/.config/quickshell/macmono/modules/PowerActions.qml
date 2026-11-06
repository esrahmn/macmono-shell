import QtQuick
import QtQuick.Layouts
import "../core"
import "../components"

Rectangle {
    id: root

    property bool open: false
    property string armed: ""
    readonly property var labels: ({ logout: "log out", restart: "restart", shutdown: "shut down" })

    Layout.fillWidth: true
    implicitHeight: open ? powerCol.implicitHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animBase; easing.type: Theme.easeOut } }
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFade } }
    visible: implicitHeight > 0.5
    color: Theme.transparent
    clip: true
    onOpenChanged: armed = ""

    Timer { id: disarmTimer; interval: Settings.powerConfirmMs; onTriggered: root.armed = "" }

    ColumnLayout {
        id: powerCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Theme.space4

        GridLayout {
            Layout.fillWidth: true
            columns: 6
            columnSpacing: Theme.space4; rowSpacing: Theme.space4
            Repeater {
                model: [
                    { act: "lock", label: "Lock", glyph: "lock", confirm: false, span: 2 },
                    { act: "sleep", label: "Sleep", glyph: "sleep", confirm: false, span: 2 },
                    { act: "logout", label: "Log Out", glyph: "logout", confirm: true, span: 2 },
                    { act: "restart", label: "Restart", glyph: "restart", confirm: true, span: 3 },
                    { act: "shutdown", label: "Shut Down", glyph: "power", confirm: true, span: 3 }
                ]
                delegate: ActionTile {
                    required property var modelData
                    Layout.columnSpan: modelData.span
                    Layout.fillWidth: true
                    Layout.preferredWidth: modelData.span
                    glyph: modelData.glyph
                    label: root.armed === modelData.act ? "Confirm" : modelData.label
                    hot: root.armed === modelData.act
                    onClicked: {
                        if (modelData.confirm && root.armed !== modelData.act) {
                            root.armed = modelData.act;
                            disarmTimer.restart();
                            return;
                        }
                        root.armed = "";
                        Sys.power(modelData.act);
                    }
                }
            }
        }
        Text {
            visible: root.armed !== ""
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.space2
            horizontalAlignment: Text.AlignHCenter
            text: "Click again to " + (root.labels[root.armed] ?? "")
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontSmall
        }
    }
}
