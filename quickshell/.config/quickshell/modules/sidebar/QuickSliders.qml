import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    Layout.fillWidth: true
    color: Theme.surface
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

            Slider {
                id: brightnessSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: Brightness.brightness
                onMoved: Brightness.setBrightness(value)

                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: brightnessSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Theme.surfaceVariant

                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Theme.primary
                    }
                }

                handle: Rectangle {
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.primary
                }
            }
        }

        RowLayout {
            spacing: 8

            MaterialIcon {
                text: Audio.muted ? "volume_off" : "volume_up"
                color: Theme.text

                MouseArea {
                    anchors.fill: parent
                    onClicked: Audio.toggleMute()
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 150
                value: Audio.volume
                onMoved: {
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)]);
                    Audio.refresh();
                }

                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Theme.surfaceVariant

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Audio.muted ? Theme.error : Theme.primary
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: Audio.muted ? Theme.error : Theme.primary
                }
            }
        }
    }
}
