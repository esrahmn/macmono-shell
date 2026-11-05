import QtQuick
import Quickshell            // wajib: root pakai Scope (tipe dari Quickshell, bukan QtQuick)
import Quickshell.Bluetooth

// Bluetooth: adapter, daftar perangkat, scan, dan state machine pairing.
// UI tetap memakai fasad Sys.bt* / Sys.toggleBt() / Sys.pairBt().
// Membuka settings (kcmshell/blueman/bluetoothctl) tetap di Sys karena butuh termScript
// dan closeCCQuiet().
Scope {
    id: root

    readonly property bool btAvailable: Bluetooth.adapters.values.length > 0
    readonly property bool btOn: Bluetooth.defaultAdapter?.enabled ?? false

    // perangkat yang sudah di-pair / tersambung; yang tersambung tampil duluan
    readonly property var btDevices: (Bluetooth.defaultAdapter?.devices.values ?? [])
        .filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    // perangkat baru yang ketemu saat scan (punya nama, belum di-pair)
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

    // pair perangkat baru -> setelah ter-pair: trust + connect otomatis
    property var pairing: null
    property int pairTicks: 0

    function pair(d) {
        pairing = d;
        pairTicks = 0;
        d.trusted = true;
        d.pair();
    }

    // Batas 30 detik: kalau perangkat tidak pernah melapor paired, batalkan supaya
    // baris "Pairing…" di UI tidak macet selamanya.
    Timer {
        interval: 1000; repeat: true
        running: root.pairing !== null
        onTriggered: {
            const d = root.pairing;
            if (!d) return;
            if (d.paired) { d.trusted = true; d.connect(); root.pairing = null; return; }
            if (++root.pairTicks > 30) { d.cancelPair(); root.pairing = null; }
        }
    }
}
