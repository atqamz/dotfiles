// quickshell/.config/quickshell/modules/bar/ClockPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 12

    HoverHandler { id: hoverHandler }

    contentItem: StyledText {
        text: Time.now ? Qt.formatDateTime(Time.now, "HH:mm") : "--:--"
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
        font.bold: true
    }
}
