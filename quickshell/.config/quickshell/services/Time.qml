pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property date now: clock.date ?? new Date()
    readonly property string time: now ? Qt.formatDateTime(now, "HH:mm") : ""
    readonly property string date: now ? Qt.formatDateTime(now, "ddd dd MMM") : ""

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
