import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

GridLayout {
    id: toggleGrid

    signal openWifiDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()

    Layout.fillWidth: true
    columns: 2
    columnSpacing: 8
    rowSpacing: 8

    QuickToggleTile {
        model: QuickToggleModel {
            name: "WiFi"
            icon: Network.connected ? "wifi" : "wifi_off"
            statusText: Network.connected ? Network.activeConnection : "Off"
            toggled: Network.connected
            mainAction: function() { Network.toggleWifi(); }
        }
        onPressAndHold: toggleGrid.openWifiDialog()
    }

    QuickToggleTile {
        model: QuickToggleModel {
            name: "Bluetooth"
            icon: Bluetooth.powered ? (Bluetooth.connectedDeviceCount > 0 ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
            statusText: Bluetooth.connectedDeviceCount > 0 ? Bluetooth.connectedDeviceNames[0] : (Bluetooth.powered ? "On" : "Off")
            available: Bluetooth.available
            toggled: Bluetooth.powered
            mainAction: function() { Bluetooth.togglePowered(); }
        }
        onPressAndHold: toggleGrid.openBluetoothDialog()
    }

    QuickToggleTile {
        model: QuickToggleModel {
            name: "Night Light"
            icon: Hyprsunset.active ? "bedtime" : "brightness_5"
            statusText: Hyprsunset.active ? (Hyprsunset.temperature + "K") : "Off"
            toggled: Hyprsunset.active
            mainAction: function() { Hyprsunset.toggle(); }
        }
        onPressAndHold: toggleGrid.openNightLightDialog()
    }

    QuickToggleTile {
        model: QuickToggleModel {
            name: "Idle"
            icon: Idle.inhibited ? "coffee" : "schedule"
            statusText: Idle.inhibited ? "Inhibited" : "Active"
            toggled: Idle.inhibited
            mainAction: function() { Idle.toggle(); }
        }
    }

    QuickToggleTile {
        model: QuickToggleModel {
            name: "DND"
            icon: NotificationHistory.doNotDisturb ? "do_not_disturb_on" : "do_not_disturb_off"
            statusText: NotificationHistory.doNotDisturb ? "On" : "Off"
            toggled: NotificationHistory.doNotDisturb
            mainAction: function() { NotificationHistory.doNotDisturb = !NotificationHistory.doNotDisturb; }
        }
    }

    QuickToggleTile {
        model: QuickToggleModel {
            name: "Mic"
            icon: Audio.micMuted ? "mic_off" : "mic"
            statusText: Audio.micMuted ? "Muted" : (Audio.micVolume + "%")
            toggled: !Audio.micMuted
            mainAction: function() { Audio.toggleMicMute(); }
        }
    }
}
