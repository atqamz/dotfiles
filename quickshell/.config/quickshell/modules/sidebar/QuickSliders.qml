import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    Layout.fillWidth: true
    color: Theme.surfaceContainerHigh
    radius: Theme.radius.large
    implicitHeight: sliderCol.implicitHeight + 24

    ColumnLayout {
        id: sliderCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            spacing: 8

            MaterialIcon {
                text: "brightness_6"
                color: Theme.text
            }

            StyledSlider {
                id: brightnessSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: Brightness.brightness
                onMoved: Brightness.setBrightness(value)
            }
        }

        RowLayout {
            spacing: 8

            Item {
                property real radius: Theme.radius.full
                implicitWidth: muteIcon.implicitWidth + 2 * Theme.padding.small
                implicitHeight: muteIcon.implicitHeight + 2 * Theme.padding.small

                MaterialIcon {
                    id: muteIcon
                    anchors.centerIn: parent
                    text: Audio.muted ? "volume_off" : "volume_up"
                    color: Theme.text
                }

                StateLayer { pressed: muteTap.pressed }

                MouseArea {
                    id: muteTap
                    anchors.fill: parent
                    onClicked: Audio.toggleMute()
                }
            }

            StyledSlider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 150
                value: Audio.volume
                fillColor: Audio.muted ? Theme.error : Theme.primary
                onMoved: {
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)]);
                    Audio.refresh();
                }
            }
        }
    }
}
