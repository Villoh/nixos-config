import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "gameCapture"

    SelectionSetting {
        settingKey: "menuType"
        label: "Menu"
        description: "What `game-capture launcher` and `dms ipc call gameCapture show` open. Overlay: centered over everything, closes on click outside. Window: a real floating window, so the border and rounding come from your compositor config. Dash tab: the Game capture tab of the dash. Dialog: the yad dialog, which does not need this plugin."
        options: [
            {
                label: "Overlay",
                value: "overlay"
            },
            {
                label: "Window",
                value: "window"
            },
            {
                label: "Dash tab",
                value: "dash"
            },
            {
                label: "Dialog (yad)",
                value: "dialog"
            }
        ]
        defaultValue: "overlay"
    }
}
