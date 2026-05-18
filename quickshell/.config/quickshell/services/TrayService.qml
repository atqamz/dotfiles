pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root
    readonly property list<SystemTrayItem> items: SystemTray.items.values
    readonly property int count: items.length
}
