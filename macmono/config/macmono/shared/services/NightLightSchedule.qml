import QtQuick
import Quickshell

Scope {
    id: root

    property bool enabled: false
    property real lat: 0
    property real lon: 0

    property bool valid: false
    property int sunriseMin: -1
    property int sunsetMin: -1
    property bool active: false

    signal windowChanged(bool active)

    function dayOfYear(d) {
        const start = new Date(d.getFullYear(), 0, 0);
        return Math.floor((d - start) / 86400000);
    }

    function computeSun(d) {
        const la = Number(lat), lo = Number(lon);
        valid = false;
        sunriseMin = -1;
        sunsetMin = -1;

        if (!isFinite(la) || !isFinite(lo) || (Math.abs(la) < 0.0001 && Math.abs(lo) < 0.0001))
            return;

        const rad = Math.PI / 180;
        const n = dayOfYear(d);
        const B = (360 / 364) * (n - 81) * rad;
        const eot = 9.87 * Math.sin(2 * B) - 7.53 * Math.cos(B) - 1.5 * Math.sin(B);
        const decl = 23.44 * rad * Math.sin(2 * Math.PI * (284 + n) / 365);
        const cosW = (Math.sin(-0.833 * rad) - Math.sin(la * rad) * Math.sin(decl))
                   / (Math.cos(la * rad) * Math.cos(decl));
        if (!isFinite(cosW) || cosW >= 1 || cosW <= -1)
            return;

        const half = Math.acos(cosW) / rad * 4;
        const noonUtc = 720 - 4 * lo - eot;
        const tz = -d.getTimezoneOffset();
        sunriseMin = Math.round((noonUtc - half + tz + 1440) % 1440);
        sunsetMin = Math.round((noonUtc + half + tz + 1440) % 1440);
        valid = true;
    }

    function refresh() {
        const d = new Date();
        computeSun(d);

        if (!valid) {
            if (active) {
                active = false;
                root.windowChanged(false);
            }
            return;
        }

        const now = d.getHours() * 60 + d.getMinutes();
        const on = enabled && (now >= sunsetMin || now < sunriseMin);
        if (on !== active) {
            active = on;
            root.windowChanged(on);
        }
    }

    onEnabledChanged: refresh()
    onLatChanged: refresh()
    onLonChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        repeat: true
        running: root.enabled
        onTriggered: root.refresh()
    }
}
