import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.components

ColumnLayout {
    id: root

    spacing: Theme.spacing.small

    Repeater {
        model: Hyprland.workspaces

        StyledRect {
            required property var modelData
            readonly property bool active: modelData.active
            readonly property bool urgent: modelData.urgent ?? false

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: active ? 28 : 14
            implicitHeight: 14
            radius: Theme.radius.full
            color: active ? Theme.primary
                  : urgent ? Theme.warning
                  : Theme.surfaceContainerHigh
            border.width: 0

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.anim.durations.normal
                    easing.type: Easing.OutCubic
                }
            }

            TapHandler {
                onTapped: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
