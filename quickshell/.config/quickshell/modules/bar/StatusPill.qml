// quickshell/.config/quickshell/modules/bar/StatusPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 12

    HoverHandler { id: hoverHandler }

    readonly property string volumeIcon: {
        if (Audio.muted) return "volume_off";
        if (Audio.volume === 0) return "volume_mute";
        if (Audio.volume < 50) return "volume_down";
        return "volume_up";
    }

    readonly property string batteryIcon: {
        if (Battery.charging) return "battery_charging_full";
        if (Battery.percent < 10) return "battery_alert";
        if (Battery.percent < 25) return "battery_2_bar";
        if (Battery.percent < 50) return "battery_4_bar";
        if (Battery.percent < 75) return "battery_5_bar";
        return "battery_full";
    }

    readonly property color batteryColor: {
        if (!Battery.charging && Battery.percent < 10) return Theme.error;
        if (!Battery.charging && Battery.percent < 25) return Theme.warning;
        return Theme.text;
    }

    contentItem: Row {
        spacing: 10

        // volume
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volumeIcon
                color: Audio.muted ? Theme.textDim : Theme.text
                font.pixelSize: 16
                TapHandler { onTapped: Audio.toggleMute() }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "--" : Audio.volume.toString()
                color: Audio.muted ? Theme.textDim : Theme.textVariant
                font.pixelSize: 11
            }
        }

        // network
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Network.connected ? "wifi" : "wifi_off"
            color: Network.connected ? Theme.text : Theme.warning
            font.pixelSize: 16
        }

        // battery
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryIcon
                color: root.batteryColor
                font.pixelSize: 16
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent.toString()
                color: root.batteryColor === Theme.text ? Theme.textVariant : root.batteryColor
                font.pixelSize: 11
            }
        }
    }
}
