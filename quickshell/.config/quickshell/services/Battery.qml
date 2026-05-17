pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: -1
    property string status: ""
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool present: percent >= 0

    // Try BAT0 first, fall back to BAT1 (some laptops only expose BAT1).
    FileView {
        id: bat0Cap
        path: "/sys/class/power_supply/BAT0/capacity"
        watchChanges: false
        onLoaded: root.percent = parseInt(this.text(), 10)
        onLoadFailed: {
            bat0Cap.path = "/sys/class/power_supply/BAT1/capacity";
            bat0Status.path = "/sys/class/power_supply/BAT1/status";
        }
    }

    FileView {
        id: bat0Status
        path: "/sys/class/power_supply/BAT0/status"
        watchChanges: false
        onLoaded: root.status = this.text().trim()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            bat0Cap.reload();
            bat0Status.reload();
        }
    }
}
