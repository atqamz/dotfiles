// quickshell/.config/quickshell/modules/bar/LauncherPill.qml
import QtQuick
import Quickshell
import qs.components

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 8
    implicitWidth: 28               // square pill

    HoverHandler { id: hoverHandler }

    contentItem: MaterialIcon {
        text: "apps"
        color: Theme.text
        font.pixelSize: 18
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
    }
}
