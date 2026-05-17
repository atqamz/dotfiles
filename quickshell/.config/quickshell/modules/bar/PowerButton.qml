import QtQuick
import Quickshell
import qs.components

Item {
    id: root

    implicitWidth: 32
    implicitHeight: 32

    StyledRect {
        anchors.fill: parent
        color: layer.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
        radius: Theme.radius.large

        MaterialIcon {
            anchors.centerIn: parent
            text: "power_settings_new"
            color: layer.hovered ? Theme.error : Theme.text
            font.pixelSize: 18
        }

        StateLayer {
            id: layer
            radius: parent.radius
        }

        TapHandler {
            onTapped: Quickshell.execDetached(["qs", "ipc", "call", "session", "toggle"])
        }
    }
}
