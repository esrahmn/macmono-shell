import QtQuick
import Quickshell
import Quickshell.Bluetooth

Scope {
    id: root

    property int pairTimeoutSec: 30

    readonly property bool btAvailable: Bluetooth.adapters.values.length > 0
    readonly property bool btOn: Bluetooth.defaultAdapter?.enabled ?? false

    readonly property var btDevices: (Bluetooth.defaultAdapter?.devices.values ?? [])
        .filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    readonly property var btNew: (Bluetooth.defaultAdapter?.devices.values ?? [])
        .filter(d => !d.paired && !d.connected && d.deviceName !== "" && d.name !== d.address.replace(/:/g, "-"))
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var btConnected: btDevices.find(d => d.connected) ?? null
    readonly property bool btScanning: Bluetooth.defaultAdapter?.discovering ?? false

    function toggle() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }

    function setScan(on) {
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
            Bluetooth.defaultAdapter.discovering = on;
    }

    property var pairing: null
    property int pairTicks: 0

    function pair(d) {
        pairing = d;
        pairTicks = 0;
        d.trusted = true;
        d.pair();
    }

    Timer {
        interval: 1000; repeat: true
        running: root.pairing !== null
        onTriggered: {
            const d = root.pairing;
            if (!d) return;
            if (d.paired) { d.trusted = true; d.connect(); root.pairing = null; return; }
            if (++root.pairTicks > root.pairTimeoutSec) { d.cancelPair(); root.pairing = null; }
        }
    }
}
