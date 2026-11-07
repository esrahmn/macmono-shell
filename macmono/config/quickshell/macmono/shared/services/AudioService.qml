import Quickshell
import Quickshell.Services.Pipewire

// Subsistem audio macmono (PipeWire). UI nggak memakai ini langsung:
// Sys.qml membuka fasadnya (Sys.volume, Sys.setVolume, Sys.outputDevices, ...).
// Pakai Scope (bukan QtObject) karena Scope punya default property `children`,
// jadi boleh berisi PwObjectTracker dkk.
Scope {
    // Tracker wajib supaya properti .audio dan metadata node terisi.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property var outputDevices: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMic() {
        if (source?.audio) source.audio.muted = !source.audio.muted;
    }

    function nodeLabel(n) {
        return n.nickname || n.description || n.name || "Unknown";
    }

    function setOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
}
