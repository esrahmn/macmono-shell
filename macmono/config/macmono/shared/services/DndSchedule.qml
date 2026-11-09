import QtQuick
import Quickshell

Scope {
    id: root

    property bool enabled: false
    property int startMin: 1320
    property int endMin: 420
    property bool active: false

    signal windowChanged(bool active)

    function clampMin(v) { return Math.max(0, Math.min(24 * 60 - 1, Math.round(Number(v) || 0))); }
    function nowMinutes() { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); }

    function inside(now, from, to) {
        const a = clampMin(from), b = clampMin(to);
        if (a === b) return false;
        return a < b ? (now >= a && now < b)
                     : (now >= a || now < b);
    }

    function refresh() {
        const on = enabled && inside(nowMinutes(), startMin, endMin);
        if (on !== active) {
            active = on;
            root.windowChanged(on);
        }
    }

    onEnabledChanged: refresh()
    onStartMinChanged: refresh()
    onEndMinChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 30000
        repeat: true
        running: root.enabled
        onTriggered: root.refresh()
    }
}
