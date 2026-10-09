pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    property var _cachedOutputs: []
    property var _cachedInputs: []
    property var _cachedApps: []

    function _arraysEqual(a, b) {
        if (!a || !b) return false;
        if (a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }

    function isSerpantinumStream(node) {
        if (!node || !node.properties) return false;
        let p = node.properties;
        let appId = p["application.id"] || "";
        let appName = p["application.name"] || "";
        if (appId === "serpantinum-sfx" || appId === "serpantinum" || appId === "org.serpantinum.sfx") return true;
        if (appName === "serpantinum-sfx" || appName === "serpantinum") return true;
        let mediaFile = p["media.filename"] || p["media.name"] || "";
        if (mediaFile.indexOf("assets/sounds/") !== -1) return true;
        return false;
    }

    readonly property var outputs: {
        let arr = [];
        for (const n of Pipewire.nodes.values) {
            if (!n.isStream && n.isSink && n.audio) arr.push(n);
        }
        if (_arraysEqual(arr, _cachedOutputs)) return _cachedOutputs;
        _cachedOutputs = arr;
        return arr;
    }

    readonly property var inputs: {
        let arr = [];
        for (const n of Pipewire.nodes.values) {
            if (!n.isStream && !n.isSink && n.audio
                && n.properties?.["device.class"] !== "monitor"
                && !n.name?.endsWith(".monitor")) {
                arr.push(n);
            }
        }
        if (_arraysEqual(arr, _cachedInputs)) return _cachedInputs;
        _cachedInputs = arr;
        return arr;
    }

    readonly property var apps: {
        let arr = [];
        for (const n of Pipewire.nodes.values) {
            if (n.isStream && n.audio
                && n.properties?.["application.id"] !== "org.PulseAudio.pavucontrol"
                && !isSerpantinumStream(n)) {
                arr.push(n);
            }
        }
        if (_arraysEqual(arr, _cachedApps)) return _cachedApps;
        _cachedApps = arr;
        return arr;
    }

    readonly property PwNode defaultSink: Pipewire.defaultAudioSink
    readonly property PwNode defaultSource: Pipewire.defaultAudioSource

    function setDefaultOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultInput(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    function toggleMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted;
    }

    function setVolume(node, pct) {
        if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1.5, pct / 100.0));
    }

    function getNodeName(node) {
        if (!node) return "";
        return node.properties?.["device.description"] || node.description || node.name || "Unknown Device";
    }

    function getNodeSubDesc(node) {
        if (!node) return "";
        if (node.isStream) {
            return node.properties?.["media.name"] || node.properties?.["window.title"] || node.properties?.["media.role"] || "Audio Stream";
        }
        return node.name || "Unknown";
    }

    function getNodeAppName(node) {
        if (!node) return "";
        return node.properties?.["application.name"] || node.properties?.["application.process.binary"] || node.description || "Unknown App";
    }
}
