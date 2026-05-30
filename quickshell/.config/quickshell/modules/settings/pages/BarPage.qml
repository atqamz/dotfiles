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
            title: "Layout"
            SettingSlider {
                label: "Bar height"; suffix: " px"
                from: 24; to: 48; stepSize: 1; decimals: 0
                value: Config.options.bar.height
                onMoved: v => Config.options.bar.height = v
            }
            SettingSelect {
                label: "Clock format"
                options: [{ label: "24h", value: true }, { label: "12h", value: false }]
                currentValue: Config.options.bar.clock24h
                onSelected: v => Config.options.bar.clock24h = v
            }
        }
        SettingSection {
            title: "Pills"
            SettingSwitch { label: "Launcher";   checked: Config.options.bar.showLauncher;   onToggled: v => Config.options.bar.showLauncher = v }
            SettingSwitch { label: "Workspaces"; checked: Config.options.bar.showWorkspaces; onToggled: v => Config.options.bar.showWorkspaces = v }
            SettingSwitch { label: "Media";      checked: Config.options.bar.showMedia;      onToggled: v => Config.options.bar.showMedia = v }
            SettingSwitch { label: "Clock";      checked: Config.options.bar.showClock;      onToggled: v => Config.options.bar.showClock = v }
            SettingSwitch { label: "Resources";  checked: Config.options.bar.showResources;  onToggled: v => Config.options.bar.showResources = v }
            SettingSwitch { label: "Tray";       checked: Config.options.bar.showTray;       onToggled: v => Config.options.bar.showTray = v }
            SettingSwitch { label: "Status";     checked: Config.options.bar.showStatus;     onToggled: v => Config.options.bar.showStatus = v }
        }
    }
}
