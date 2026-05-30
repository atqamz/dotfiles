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
                label: "Workspace scale"
                from: 0.10; to: 0.30; stepSize: 0.01; decimals: 2
                value: Config.options.overview.scale
                onMoved: v => Config.options.overview.scale = v
            }
            SettingSlider {
                label: "Rows"
                from: 1; to: 3; stepSize: 1; decimals: 0
                value: Config.options.overview.rows
                onMoved: v => Config.options.overview.rows = v
            }
            SettingSlider {
                label: "Columns"
                from: 3; to: 8; stepSize: 1; decimals: 0
                value: Config.options.overview.columns
                onMoved: v => Config.options.overview.columns = v
            }
        }
    }
}
