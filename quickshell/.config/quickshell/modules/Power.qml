import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool open: false

    readonly property var actions: [
        { label: "Lock",     cmd: ["hyprlock"] },
        { label: "Logout",   cmd: ["hyprctl", "dispatch", "exit"] },
        { label: "Suspend",  cmd: ["systemctl", "suspend"] },
        { label: "Reboot",   cmd: ["systemctl", "reboot"] },
        { label: "Shutdown", cmd: ["systemctl", "poweroff"] }
    ]

    function toggle(): void { root.open = !root.open; }

    function run(cmd: list<string>): void {
        root.open = false;
        Quickshell.execDetached(cmd);
    }

    IpcHandler {
        target: "session"
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

            color: "#cc000000"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Keys.onEscapePressed: root.open = false

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                anchors.centerIn: parent
                implicitWidth: buttonRow.implicitWidth + 32
                implicitHeight: buttonRow.implicitHeight + 32
                color: "#0a0a0a"
                border.color: "#3a3a3a"
                border.width: 1
                radius: 6

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: buttonRow
                    anchors.centerIn: parent
                    spacing: 12

                    Repeater {
                        model: root.actions

                        Rectangle {
                            required property var modelData
                            implicitWidth: 120
                            implicitHeight: 120
                            color: hover.hovered ? "#1f1f1f" : "#141414"
                            border.color: hover.hovered ? "#ffffff" : "#3a3a3a"
                            border.width: 1
                            radius: 4

                            HoverHandler { id: hover }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                            }

                            TapHandler {
                                onTapped: root.run(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
