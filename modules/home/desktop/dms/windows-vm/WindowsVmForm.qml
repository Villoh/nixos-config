import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.DCommon.Widgets
import qs.Widgets

// The controls of `windows-vm`, shared by the overlay, the window and the dash tab. The choices are
// kept as plugin state ("cfg"), so every surface opens with the last ones. Restore and delete are
// confirmed here with a DMS dialog, so the script gets --yes (its own yad dialog is only for the
// desktop actions, which have no form).
Column {
    id: root

    property string pluginId: ""
    property var pluginService: null
    property var transientSurfaceTracker: null

    signal started

    readonly property var defaults: ({
            keepAlive: "No",
            checkpoint: ""
        })
    property var cfg: defaults
    property string vmState: "..."
    property var checkpoints: []
    // Never empty while a checkpoint exists: the saved one, or the first.
    readonly property string selected: checkpoints.indexOf(cfg.checkpoint) >= 0 ? cfg.checkpoint : (checkpoints[0] ?? "")

    spacing: Theme.spacingM

    onPluginIdChanged: restore()
    onPluginServiceChanged: restore()
    // The form is already visible when it is created, so onVisibleChanged never fires the first time.
    Component.onCompleted: refresh()
    onVisibleChanged: {
        if (visible) {
            restore();
            refresh();
        }
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

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;
        if (!listProcess.running)
            listProcess.running = true;
    }

    function run(args) {
        Quickshell.execDetached(["windows-vm"].concat(args));
        // Checkpoints take a while; the timer below keeps the state fresh meanwhile.
        refresh();
    }

    // Asks in a DMS confirm dialog (stacked over the form), then runs windows-vm with --yes.
    function ask(title, message, confirmText, args) {
        confirmModal.showWithOptions({
            title: title,
            message: message,
            confirmText: confirmText,
            danger: true,
            onConfirm: () => root.run(args)
        });
    }

    function start() {
        run(["launch"].concat(cfg.keepAlive === "Yes" ? ["--keep-alive"] : []));
        started();
    }

    ConfirmModal {
        id: confirmModal
    }

    Process {
        id: statusProcess

        command: ["windows-vm", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.vmState = text.trim() || "unknown"
        }
    }

    Process {
        id: listProcess

        command: ["windows-vm", "snapshots"]
        stdout: StdioCollector {
            onStreamFinished: root.checkpoints = text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
        }
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    StyledText {
        width: root.width
        text: "State: " + root.vmState
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceText
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Keep running after the window closes"
        currentValue: root.cfg.keepAlive
        options: ["No", "Yes"]
        onValueChanged: value => root.set("keepAlive", value)
    }

    DDropdown {
        width: root.width
        dropdownWidth: 220
        transientSurfaceTracker: root.transientSurfaceTracker
        text: "Checkpoint"
        currentValue: root.selected
        options: root.checkpoints
        onValueChanged: value => root.set("checkpoint", value)
    }

    Row {
        spacing: Theme.spacingS

        DButton {
            text: "Restore"
            iconName: "restore"
            enabled: root.selected !== ""
            onClicked: root.ask("Restore checkpoint", "Replace the current Windows disk with '" + root.selected + "'? Changes since then are lost.", "Restore", ["restore", root.selected, "--yes"])
        }

        DButton {
            text: "Delete"
            iconName: "delete"
            variant: "text"
            enabled: root.selected !== ""
            onClicked: root.ask("Delete checkpoint", "Delete '" + root.selected + "'? This frees its disk space and cannot be undone.", "Delete", ["delete", root.selected, "--yes"])
        }

        DButton {
            text: "Stop"
            iconName: "stop"
            variant: "text"
            onClicked: root.run(["stop"])
        }
    }

    DTextField {
        id: nameField

        width: root.width
        placeholderText: "New checkpoint name (empty: date and time)"
    }

    DButton {
        text: "Checkpoint now"
        iconName: "add_a_photo"
        variant: "tonal"
        onClicked: {
            root.run(["snapshot"].concat(nameField.text.trim() !== "" ? [nameField.text.trim()] : []));
            nameField.text = "";
        }
    }

    StyledText {
        width: root.width
        wrapMode: Text.WordWrap
        text: "A checkpoint is a full copy of the Windows disk (about 16 GB, 30 s). The VM is shut down while it is taken or restored, and started again if it was running."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
}
