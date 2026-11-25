import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Widgets

// The pickers of `game-capture run`, shared by the overlay, the window and the dash tab. The
// choices are kept as plugin state ("cfg"), so every surface opens with the last ones.
Column {
    id: root

    property string pluginId: ""
    property var pluginService: null
    property var transientSurfaceTracker: null

    signal started

    readonly property var defaults: ({
            res: "3840x2160",
            fps: "60",
            fmt: "NV12",
            lat: "Lowest",
            audio: "Loopback",
            fs: "No"
        })
    property var cfg: defaults

    spacing: Theme.spacingM

    onPluginIdChanged: restore()
    onPluginServiceChanged: restore()
    onVisibleChanged: {
        if (visible)
            restore();
    }

    function restore() {
        if (!pluginService || !pluginId)
            return;
        cfg = Object.assign({}, defaults, pluginService.loadPluginState(pluginId, "cfg", {}));
    }

    function set(key, value) {
        const next = Object.assign({}, cfg);
        next[key] = value;
        cfg = next;
        pluginService?.savePluginState(pluginId, "cfg", next);
    }

    function start() {
        Quickshell.execDetached(["game-capture", "run", cfg.res, cfg.fps, cfg.fmt, cfg.lat, cfg.audio, cfg.fs === "Yes" ? "TRUE" : "FALSE"]);
        started();
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Resolution"
        currentValue: root.cfg.res
        options: ["3840x2160", "2560x1440", "2560x1080", "1920x1080", "1280x720"]
        onValueChanged: value => root.set("res", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Frame rate"
        currentValue: root.cfg.fps
        options: ["30", "60", "120", "144", "240"]
        onValueChanged: value => root.set("fps", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Pixel format"
        currentValue: root.cfg.fmt
        options: ["NV12", "YUYV", "MJPG"]
        onValueChanged: value => root.set("fmt", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Latency"
        currentValue: root.cfg.lat
        options: ["Lowest", "Low", "Smooth"]
        onValueChanged: value => root.set("lat", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Audio"
        currentValue: root.cfg.audio
        options: ["Loopback", "Off"]
        onValueChanged: value => root.set("audio", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Fullscreen"
        currentValue: root.cfg.fs
        options: ["No", "Yes"]
        onValueChanged: value => root.set("fs", value)
    }

    StyledText {
        width: root.width
        wrapMode: Text.WordWrap
        text: "ezcap401 on USB 3.2 Gen 2: 4K 60 fps NV12 or 144 fps MJPG, 1440p 144 NV12, 1080p 240 NV12 or 120 YUYV."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
}
