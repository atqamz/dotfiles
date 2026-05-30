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
            title: "Typography"
            SettingText {
                label: "UI font"
                text: Config.options.appearance.fontFamily
                onEdited: value => Config.options.appearance.fontFamily = value
            }
            SettingSlider {
                label: "Font scale"
                from: 0.85; to: 1.25; stepSize: 0.05; decimals: 2
                value: Config.options.appearance.fontScale
                onMoved: v => Config.options.appearance.fontScale = v
            }
        }
        SettingSection {
            title: "Shape & motion"
            SettingSlider {
                label: "Roundness"
                from: 0.5; to: 1.5; stepSize: 0.05; decimals: 2
                value: Config.options.appearance.radiusScale
                onMoved: v => Config.options.appearance.radiusScale = v
            }
            SettingSlider {
                label: "Motion speed"
                from: 0.5; to: 2.0; stepSize: 0.1; decimals: 1; suffix: "x"
                value: Config.options.appearance.motionScale
                onMoved: v => Config.options.appearance.motionScale = v
            }
        }
    }
}
