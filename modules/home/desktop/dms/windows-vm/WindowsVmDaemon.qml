import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins

// `dms ipc call windowsVm show` opens the menu picked in Settings -> Plugins -> Windows VM:
//   overlay (default)  a DMS modal, centered over everything
//   window             a real floating window
//   dash               the Windows VM tab of the dash
//   dialog             prints WINDOWS_VM_DIALOG, so `windows-vm launcher` shows its yad dialog
PluginComponent {
    id: root

    readonly property string menuType: root.pluginData?.menuType ?? "overlay"

    function show() {
        switch (menuType) {
        case "dialog":
            return "WINDOWS_VM_DIALOG";
        case "dash":
            Quickshell.execDetached(["dms", "ipc", "call", "dash", "open", "plugin_windowsVm"]);
            break;
        case "window":
            floatWin.visible = true;
            break;
        default:
            modal.open();
        }
        return "WINDOWS_VM_SHOWN";
    }

    IpcHandler {
        target: "windowsVm"

        function show(): string {
            return root.show();
        }
    }

    WindowsVmWindow {
        id: floatWin

        pluginId: root.pluginId
        pluginService: root.pluginService
    }

    DModal {
        id: modal

        layerNamespace: "dms:windows-vm"
        keepPopoutsOpen: true
        shouldBeVisible: false
        shouldHaveFocus: true
        modalWidth: Math.min(Theme.dialogMaxWidth, screenWidth - Theme.spacingXL * 2)
        modalHeight: contentLoader.item ? Math.min(contentLoader.item.implicitHeight, screenHeight - Theme.spacingXL * 2) : 480
        onBackgroundClicked: close()

        content: DDialog {
            title: "Windows VM"
            onAccepted: form.start()
            onRejected: modal.close()

            WindowsVmForm {
                id: form

                width: parent.width
                pluginId: root.pluginId
                pluginService: root.pluginService
                transientSurfaceTracker: modal.transientSurfaceTracker
                onStarted: modal.close()
            }

            actions: [
                DButton {
                    text: "Close"
                    variant: "text"
                    onClicked: modal.close()
                },
                DButton {
                    text: "Start"
                    iconName: "play_arrow"
                    onClicked: form.start()
                }
            ]
        }
    }
}
