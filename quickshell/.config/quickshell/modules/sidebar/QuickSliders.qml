import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

StyledRect {
    Layout.fillWidth: true
    color: Theme.surfaceContainerHigh
    radius: Theme.radius.large
    implicitHeight: sliderCol.implicitHeight + 2 * Theme.padding.larger

    ColumnLayout {
        id: sliderCol
        anchors.fill: parent
        anchors.margins: Theme.padding.larger
        spacing: Theme.spacing.large

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.normal

            // Brightness, icon tracks the level. Not interactive (no toggle).
            Item {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                MaterialIcon {
                    anchors.centerIn: parent
                    text: Brightness.brightness < 0.34 ? "brightness_low"
                        : Brightness.brightness < 0.67 ? "brightness_medium"
                        : "brightness_high"
                    color: Theme.text
                    font.pixelSize: Theme.icon.size.normal
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: Brightness.brightness
                onMoved: Brightness.setBrightness(value)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.normal

            Item {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                property real radius: Theme.radius.full

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Audio.muted ? "volume_off" : (Audio.volume === 0 ? "volume_mute" : Audio.volume < 50 ? "volume_down" : "volume_up")
                    color: Audio.muted ? Theme.textDim : Theme.text
                    font.pixelSize: Theme.icon.size.normal
                }

                StateLayer { pressed: muteTap.pressed }

                MouseArea {
                    id: muteTap
                    anchors.fill: parent
                    onClicked: Audio.toggleMute()
                }
            }

            StyledSlider {
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
