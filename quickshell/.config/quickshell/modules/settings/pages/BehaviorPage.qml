import QtQuick
import qs.components
import "../widgets"

Flickable {
    id: page
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: page.width
        spacing: Theme.spacing.extraLarge

        SettingSection {
            title: "Notifications"
            SettingSlider {
                label: "On-screen timeout"; suffix: " ms"
                from: 2000; to: 15000; stepSize: 500; decimals: 0
                value: Config.options.behavior.notifTimeout
                onMoved: v => Config.options.behavior.notifTimeout = v
            }
            SettingSlider {
                label: "Max on screen"
                from: 1; to: 10; stepSize: 1; decimals: 0
                value: Config.options.behavior.notifMaxVisible
                onMoved: v => Config.options.behavior.notifMaxVisible = v
            }
            SettingSlider {
                label: "History limit"
                from: 10; to: 200; stepSize: 10; decimals: 0
                value: Config.options.behavior.notifHistoryMax
                onMoved: v => Config.options.behavior.notifHistoryMax = v
            }
            SettingSwitch {
                label: "Do not disturb on startup"
                checked: Config.options.behavior.dndDefault
                onToggled: v => Config.options.behavior.dndDefault = v
            }
        }
        SettingSection {
            title: "Night light"
            SettingSlider {
                label: "Default temperature"; suffix: " K"
                from: 2500; to: 6500; stepSize: 100; decimals: 0
                value: Config.options.behavior.nightTemp
                onMoved: v => Config.options.behavior.nightTemp = v
            }
        }
    }
}
