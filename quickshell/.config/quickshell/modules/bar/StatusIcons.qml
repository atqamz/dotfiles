import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: Theme.spacing.normal

    // Volume
    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: Audio.muted ? "volume_off"
              : Audio.volume === 0 ? "volume_mute"
              : Audio.volume < 50 ? "volume_down"
              : "volume_up"
        color: Audio.muted ? Theme.textDim : Theme.text
        font.pixelSize: 20

        TapHandler {
            onTapped: Audio.toggleMute()
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Audio.muted ? "--" : Audio.volume + ""
        color: Audio.muted ? Theme.textDim : Theme.textVariant
        font.pixelSize: Theme.font.size.smaller
    }

    // Network
    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.small
        text: Network.connected ? "wifi" : "wifi_off"
        color: Network.connected ? Theme.text : Theme.warning
        font.pixelSize: 18
    }

    // Battery
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.small
        visible: Battery.present
        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        ColumnLayout {
            id: column
            spacing: 0

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Battery.charging ? "battery_charging_full"
                      : Battery.percent < 10 ? "battery_alert"
                      : Battery.percent < 25 ? "battery_2_bar"
                      : Battery.percent < 50 ? "battery_4_bar"
                      : Battery.percent < 75 ? "battery_5_bar"
                      : "battery_full"
                color: !Battery.charging && Battery.percent < 10 ? Theme.error
                       : !Battery.charging && Battery.percent < 25 ? Theme.warning
                       : Theme.text
                font.pixelSize: 18
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Battery.percent + ""
                color: !Battery.charging && Battery.percent < 25 ? Theme.warning : Theme.textVariant
                font.pixelSize: Theme.font.size.smaller
            }
        }
    }
}
