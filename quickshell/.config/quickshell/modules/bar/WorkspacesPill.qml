// quickshell/.config/quickshell/modules/bar/WorkspacesPill.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.components

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 6

        Repeater {
            model: 5

            StyledRect {
                id: dot
                readonly property int wsId: index + 1
                readonly property var ws: {
                    const list = Hyprland.workspaces.values;
                    for (let i = 0; i < list.length; ++i) {
                        if (list[i].id === wsId) return list[i];
                    }
                    return null;
                }
                readonly property bool active: ws !== null && ws.active === true
                readonly property bool urgent: ws !== null && ws.urgent === true

                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 6
                implicitWidth: active ? 28 : 6
                radius: Theme.radius.full
                color: active ? Theme.text : (urgent ? Theme.warning : Theme.textDim)
                border.width: 0

                Behavior on implicitWidth {
                    Anim {
                        curve: Theme.anim.decel
                        duration: Theme.anim.durations.normal
                    }
                }

                StateLayer {
                    pressed: wsTap.pressed
                }

                TapHandler {
                    id: wsTap
                    onTapped: Hyprland.dispatch("hl.dsp.focus({workspace=" + dot.wsId + "})")
                }
            }
        }
    }
}
