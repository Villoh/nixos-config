import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash

// The dash-tab menu (see WindowsVmDaemon.qml for the others).
DashTabComponent {
    id: root

    focusTarget: startButton
    implicitHeight: Math.max(DashMetrics.tabMinHeight, content.implicitHeight + Theme.spacingL * 2)

    function restoreFocus() {
        startButton.forceActiveFocus(Qt.OtherFocusReason);
    }

    Column {
        id: content
        anchors.centerIn: parent
        width: Math.min(parent.width, 460)
        spacing: Theme.spacingL

        WindowsVmForm {
            id: form

            width: parent.width
            pluginId: root.pluginId
            pluginService: root.pluginService
            onStarted: Quickshell.execDetached(["dms", "ipc", "call", "dash", "close"])
        }

        DButton {
            id: startButton
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Start"
            iconName: "play_arrow"
            onClicked: form.start()
        }
    }
}
