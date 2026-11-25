import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Widgets

// "Window" menu: a real floating window (like DMS's own dialogs), so the compositor draws the
// border and rounding.
DFloatingWindow {
    id: win

    property string pluginId: ""
    property var pluginService: null

    objectName: "gameCaptureWindow"
    title: "Game capture"
    minimumSize: Qt.size(460, dialog.implicitHeight)
    maximumSize: Qt.size(460, dialog.implicitHeight)
    implicitWidth: minimumSize.width
    implicitHeight: minimumSize.height
    visible: false

    onClosed: visible = false

    DDialog {
        id: dialog

        anchors.fill: parent
        windowControls: controls
        title: win.title
        onAccepted: form.start()
        onRejected: win.visible = false

        GameCaptureForm {
            id: form

            width: parent.width
            pluginId: win.pluginId
            pluginService: win.pluginService
            onStarted: win.visible = false
        }

        actions: [
            DButton {
                text: "Cancel"
                variant: "text"
                onClicked: win.visible = false
            },
            DButton {
                text: "Start"
                iconName: "play_arrow"
                onClicked: form.start()
            }
        ]
    }

    FloatingWindowControls {
        id: controls
        targetWindow: win
    }
}
