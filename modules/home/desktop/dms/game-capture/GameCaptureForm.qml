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
            range: "Auto",
            lat: "Ultra",
            audio: "Loopback",
            fs: "No"
        })
    property var cfg: defaults

    // Modes the ezcap401 offers per pixel format (v4l2-ctl --list-formats-ext on USB 3.2 Gen 2,
    // without the 59.94, 29.97 and 25 fps variants), so the lists never offer a mode the card
    // lacks. shortcut: this card only, redo the table if the model changes.
    readonly property var resOrder: ["3840x2160", "3440x1440", "2560x1440", "2560x1080", "1920x1080", "1280x720"]
    readonly property var modes: ({
            NV12: {
                "3840x2160": [60, 50, 30],
                "3440x1440": [60, 50, 30],
                "2560x1440": [144, 120, 60, 50, 30],
                "2560x1080": [144, 120, 60, 50, 30],
                "1920x1080": [240, 144, 120, 60, 50, 30],
                "1280x720": [240, 144, 120, 60, 50, 30]
            },
            YUYV: {
                "3840x2160": [50, 30],
                "3440x1440": [60, 50, 30],
                "2560x1440": [60, 50, 30],
                "2560x1080": [120, 60, 50, 30],
                "1920x1080": [120, 60, 50, 30],
                "1280x720": [120, 60, 50, 30]
            },
            MJPG: {
                "3840x2160": [144, 120, 60, 50, 30],
                "3440x1440": [144, 120, 60, 50, 30],
                "2560x1440": [144, 120, 60, 50, 30],
                "2560x1080": [144, 120, 60, 50, 30],
                "1920x1080": [240, 144, 120, 60, 50, 30],
                "1280x720": [240, 144, 120, 60, 50, 30]
            },
            BGR3: {
                "3840x2160": [30],
                "2560x1440": [60, 50, 30],
                "2560x1080": [120, 60, 50, 30],
                "1920x1080": [120, 60, 50, 30]
            }
        })

    spacing: Theme.spacingM

    function resList(fmt) {
        const m = modes[fmt] || modes.NV12;
        return resOrder.filter(r => m[r]);
    }

    function fpsList(fmt, res) {
        const m = (modes[fmt] || modes.NV12)[res] || [];
        return m.map(f => String(f));
    }

    // Keeps the resolution and the frame rate inside what the pixel format offers: the same
    // resolution when it exists, and the highest rate not above the one asked for.
    function fit(c) {
        const next = Object.assign({}, c);
        const ress = resList(next.fmt);
        if (ress.indexOf(next.res) < 0)
            next.res = ress[0];
        const fpss = fpsList(next.fmt, next.res);
        if (fpss.indexOf(next.fps) < 0) {
            const want = Number(next.fps);
            next.fps = fpss.find(f => Number(f) <= want) || fpss[fpss.length - 1];
        }
        return next;
    }

    onPluginIdChanged: restore()
    onPluginServiceChanged: restore()
    onVisibleChanged: {
        if (visible)
            restore();
    }

    function restore() {
        if (!pluginService || !pluginId)
            return;
        cfg = fit(Object.assign({}, defaults, pluginService.loadPluginState(pluginId, "cfg", {})));
    }

    function set(key, value) {
        const draft = Object.assign({}, cfg);
        draft[key] = value;
        const next = fit(draft);
        cfg = next;
        pluginService?.savePluginState(pluginId, "cfg", next);
    }

    function start() {
        Quickshell.execDetached(["game-capture", "run", cfg.res, cfg.fps, cfg.fmt, cfg.lat, cfg.audio, cfg.fs === "Yes" ? "TRUE" : "FALSE", cfg.range]);
        started();
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Resolution"
        currentValue: root.cfg.res
        options: root.resList(root.cfg.fmt)
        onValueChanged: value => root.set("res", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Frame rate"
        currentValue: root.cfg.fps
        options: root.fpsList(root.cfg.fmt, root.cfg.res)
        onValueChanged: value => root.set("fps", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Pixel format"
        currentValue: root.cfg.fmt
        options: ["NV12", "YUYV", "MJPG", "BGR3"]
        onValueChanged: value => root.set("fmt", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Color range"
        currentValue: root.cfg.range
        options: ["Auto", "Limited", "Full"]
        onValueChanged: value => root.set("range", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Latency"
        currentValue: root.cfg.lat
        options: ["Ultra", "Lowest", "Low", "Smooth"]
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
        text: "ezcap401 on USB 3.2 Gen 2: 4K 60 fps NV12 or 144 fps MJPG, 1440p 144 NV12, 1080p 240 NV12 or 120 YUYV.\nBGR3 (uncompressed RGB): 4K 30, 1440p 60, 1080p 120.\nColor range: Auto trusts the card (limited); Full if the console sends full range and the picture looks off.\nLatency: Ultra = Lowest plus a 1-frame GPU queue (less lag, may stutter if the GPU is busy)."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
}
