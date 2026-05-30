import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import "sidebar"

Scope {
    id: root

    property bool open: false

    function toggle(): void { open = !open; }

    IpcHandler {
        target: "sidebarRight"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Keys.onEscapePressed: root.open = false

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                id: panel
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 380
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1

                MouseArea { anchors.fill: parent }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: 8
                    active: root.open
                    sourceComponent: SidebarRightContent {}
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: panel.left
                color: Theme.scrim
            }
        }
    }
}
