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
            title: "Dock"
            SettingSwitch { label: "Enable dock"; checked: Config.options.dock.enable;  onToggled: v => Config.options.dock.enable = v }
            SettingSwitch { label: "Auto-hide";   checked: Config.options.dock.autoHide; onToggled: v => Config.options.dock.autoHide = v }
            SettingSlider {
                label: "Dock height"; suffix: " px"
                from: 40; to: 96; stepSize: 2; decimals: 0
                value: Config.options.dock.height
                onMoved: v => Config.options.dock.height = v
            }
            SettingSlider {
                label: "Icon size"; suffix: " px"
                from: 24; to: 64; stepSize: 2; decimals: 0
                value: Config.options.dock.iconSize
                onMoved: v => Config.options.dock.iconSize = v
            }
        }
    }
}
