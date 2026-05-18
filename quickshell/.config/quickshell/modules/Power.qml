import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components

Scope {
    id: root

    property bool open: false

    readonly property var actions: [
        { label: "Lock",     icon: "lock",              cmd: ["hyprlock"] },
        { label: "Logout",   icon: "logout",            cmd: ["hyprctl", "dispatch", "exit"] },
        { label: "Suspend",  icon: "bedtime",           cmd: ["systemctl", "suspend"] },
        { label: "Reboot",   icon: "restart_alt",       cmd: ["systemctl", "reboot"] },
        { label: "Shutdown", icon: "power_settings_new", cmd: ["systemctl", "poweroff"] }
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

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Keys.onEscapePressed: root.open = false

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: buttonRow.implicitWidth + Theme.padding.larger * 2
                implicitHeight: buttonRow.implicitHeight + Theme.padding.larger * 2
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: buttonRow
                    anchors.centerIn: parent
                    spacing: Theme.spacing.large

                    Repeater {
                        model: root.actions

                        StyledRect {
                            required property var modelData
                            implicitWidth: 128
                            implicitHeight: 128
                            color: layer.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.color: layer.hovered ? Theme.primary : Theme.outlineVariant
                            border.width: 1
                            radius: Theme.radius.large

                            StateLayer { id: layer; radius: parent.radius }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacing.normal

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: layer.hovered ? Theme.primary : Theme.text
                                    font.pixelSize: 36
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.large
                                }
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
