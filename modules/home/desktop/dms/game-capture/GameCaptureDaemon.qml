import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins

// `dms ipc call gameCapture show` opens the menu picked in Settings -> Plugins -> Game capture:
//   overlay (default)  a DMS modal, centered over everything
//   window             a real floating window
//   dash               the Game capture tab of the dash
//   dialog             prints GAME_CAPTURE_DIALOG, so `game-capture launcher` shows its yad dialog
PluginComponent {
    id: root

    readonly property string menuType: root.pluginData?.menuType ?? "overlay"

    function show() {
        switch (menuType) {
        case "dialog":
            return "GAME_CAPTURE_DIALOG";
        case "dash":
            Quickshell.execDetached(["dms", "ipc", "call", "dash", "open", "plugin_gameCapture"]);
            break;
        case "window":
            floatWin.visible = true;
            break;
        default:
            modal.open();
        }
        return "GAME_CAPTURE_SHOWN";
    }

    IpcHandler {
        target: "gameCapture"

        function show(): string {
            return root.show();
        }
    }

    GameCaptureWindow {
        id: floatWin

        pluginId: root.pluginId
        pluginService: root.pluginService
    }

    DModal {
        id: modal

        layerNamespace: "dms:game-capture"
        keepPopoutsOpen: true
        shouldBeVisible: false
        shouldHaveFocus: true
        modalWidth: Math.min(Theme.dialogMaxWidth, screenWidth - Theme.spacingXL * 2)
        modalHeight: contentLoader.item ? Math.min(contentLoader.item.implicitHeight, screenHeight - Theme.spacingXL * 2) : 480
        onBackgroundClicked: close()

        content: DDialog {
            title: "Game capture"
            onAccepted: form.start()
            onRejected: modal.close()

            GameCaptureForm {
                id: form

                width: parent.width
                pluginId: root.pluginId
                pluginService: root.pluginService
                transientSurfaceTracker: modal.transientSurfaceTracker
                onStarted: modal.close()
            }

            actions: [
                DButton {
                    text: "Cancel"
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
