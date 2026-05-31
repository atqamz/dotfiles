// quickshell/.config/quickshell/modules/bar/StatusPill.qml
import QtQuick
import Quickshell
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

    readonly property string bluetoothIcon: {
        if (!Bluetooth.powered) return "bluetooth_disabled";
        if (Bluetooth.connectedDeviceCount > 0) return "bluetooth_connected";
        return "bluetooth";
    }

    readonly property color bluetoothColor: {
        if (!Bluetooth.powered) return Theme.textDim;
        if (Bluetooth.connectedDeviceCount > 0) return Theme.text;
        return Theme.textVariant;
    }

    // The graduated battery_N_bar icons are Material Symbols only and absent
    // from this repo's Material Icons font, so they would render as literal
    // text. Stick to ligatures the classic font actually ships.
    readonly property string batteryIcon: {
        if (Battery.charging) return "battery_charging_full";
        if (Battery.percent < 25) return "battery_alert";
        return "battery_full";
    }

    readonly property color batteryColor: {
        if (!Battery.charging && Battery.percent < 10) return Theme.error;
        if (!Battery.charging && Battery.percent < 25) return Theme.warning;
        return Theme.text;
    }

    contentItem: Row {
        spacing: 10

        // updates
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Updates.available > 0
            spacing: 4

            Item {
                id: updatesBtn
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: updatesIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: updatesIcon.implicitHeight + 2 * Theme.padding.smaller
                property real radius: Theme.radius.small

                MaterialIcon {
                    id: updatesIcon
                    anchors.centerIn: parent
                    text: "system_update"
                    color: Theme.warning
                    font.pixelSize: Theme.icon.size.small
                }
                StateLayer { pressed: updatesTap.pressed }
                TapHandler {
                    id: updatesTap
                    onTapped: Quickshell.execDetached(["alacritty", "-e", "bash", "-c", "sudo dnf upgrade; read -n 1 -s -r -p 'Press any key to close...'"])
                }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.available.toString()
                color: Theme.warning
                font.pixelSize: Theme.font.size.smaller
            }
        }

        // volume
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                id: volumeBtn
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: volumeIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: volumeIcon.implicitHeight + 2 * Theme.padding.smaller
                property real radius: Theme.radius.small

                MaterialIcon {
                    id: volumeIcon
                    anchors.centerIn: parent
                    text: root.volumeIcon
                    color: Audio.muted ? Theme.textDim : Theme.text
                    font.pixelSize: Theme.icon.size.small
                }
                StateLayer { pressed: volumeTap.pressed }
                TapHandler { id: volumeTap; onTapped: Audio.toggleMute() }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "--" : Audio.volume.toString()
                color: Audio.muted ? Theme.textDim : Theme.textVariant
                font.pixelSize: Theme.font.size.smaller
            }
        }

        // bluetooth
        Item {
            id: bluetoothBtn
            anchors.verticalCenter: parent.verticalCenter
            visible: Bluetooth.available
            implicitWidth: bluetoothIcon.implicitWidth + 2 * Theme.padding.smaller
            implicitHeight: bluetoothIcon.implicitHeight + 2 * Theme.padding.smaller
            property real radius: Theme.radius.small

            MaterialIcon {
                id: bluetoothIcon
                anchors.centerIn: parent
                text: root.bluetoothIcon
                color: root.bluetoothColor
                font.pixelSize: Theme.icon.size.small
            }
            StateLayer { pressed: bluetoothTap.pressed }
            TapHandler { id: bluetoothTap; onTapped: Bluetooth.togglePowered() }
        }

        // network
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Network.connected ? "wifi" : "wifi_off"
            color: Network.connected ? Theme.text : Theme.warning
            font.pixelSize: Theme.icon.size.small

            TapHandler {
                onTapped: Quickshell.execDetached(["qs", "ipc", "call", "sidebarRight", "toggle"])
            }
        }

        // battery
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            spacing: 4

            TapHandler {
                onTapped: Quickshell.execDetached(["qs", "ipc", "call", "sidebarRight", "toggle"])
            }

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryIcon
                color: root.batteryColor
                font.pixelSize: Theme.icon.size.small
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent.toString()
                color: root.batteryColor === Theme.text ? Theme.textVariant : root.batteryColor
                font.pixelSize: Theme.font.size.smaller
            }
        }
    }
}
