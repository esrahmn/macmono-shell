import QtQuick
import "../../core"

Item {
    id: root
    visible: false

    property bool open: false

    property real openStiff: Theme.revealOpenStiff
    property real closeStiff: Theme.revealCloseStiff
    property real openDamp: Theme.revealOpenDamp
    property real closeDamp: Theme.revealCloseDamp

    property real value: 0
    property real velocity: 0
    // travel: unclamped spring value (may exceed 1 while bouncing), for translate/scale.
    // progress: clamped 0..1, for opacity and visibility.
    readonly property real travel: value
    readonly property real progress: Math.max(0, Math.min(1, value))
    readonly property bool animating: frames.running
    readonly property bool present: open || (value > 0.006 && value !== 0)

    // Stagger without extra animations: sub-progress for the [from, to] slice of one spring.
    // span: clamped 0..1 (opacity). spanTravel: follows the bounce (position/scale).
    function span(from, to) {
        return Math.max(0, Math.min(1, (root.value - from) / (to - from)));
    }
    function spanTravel(from, to) {
        return root.value > 1 ? root.value : span(from, to);
    }

    // Emitted when the spring comes to rest on its target (isOpen = open/close target).
    signal settled(bool isOpen)

    onOpenChanged: frames.running = true
    Component.onCompleted: if (open) frames.running = true

    FrameAnimation {
        id: frames
        onTriggered: {
            const target = root.open ? 1 : 0;
            const k = root.open ? root.openStiff : root.closeStiff;
            const c = 2 * (root.open ? root.openDamp : root.closeDamp) * Math.sqrt(k);

            const dt = Math.min(frames.frameTime, 0.05);

            const n = Math.max(1, Math.ceil(dt / 0.003));
            const h = dt / n;
            let x = root.value, v = root.velocity;
            let settle = false;

            for (let i = 0; i < n; i++) {
                v += (-k * (x - target) - c * v) * h;
                x += v * h;
            }

            if (Math.abs(x - target) < 0.001 && Math.abs(v) < 0.01) {
                x = target;
                v = 0;
                frames.running = false;
                settle = true;
            }

            root.value = x;
            root.velocity = v;
            if (settle) root.settled(root.open);
        }
    }

}
