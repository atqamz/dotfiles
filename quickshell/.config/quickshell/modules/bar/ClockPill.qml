// quickshell/.config/quickshell/modules/bar/ClockPill.qml
import QtQuick
import Quickshell
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 12

    HoverHandler { id: hoverHandler }

    StateLayer { pressed: clockTap.pressed }

    TapHandler {
        id: clockTap
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "sidebarRight", "toggle"])
    }

    contentItem: StyledText {
        text: Time.now ? Qt.formatDateTime(Time.now, Config.options.bar.clock24h ? "HH:mm" : "hh:mm AP") : "--:--"
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
        font.bold: true
    }
}
