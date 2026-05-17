import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 28
        color: "#000000"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Workspace indicator
            Row {
                Layout.alignment: Qt.AlignLeft
                spacing: 6

                Repeater {
                    model: Hyprland.workspaces

                    Rectangle {
                        required property var modelData
                        width: 16
                        height: 16
                        radius: 2
                        color: modelData.active ? "#ffffff" : "#1a1a1a"
                        border.color: "#3a3a3a"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.id
                            color: modelData.active ? "#000000" : "#888888"
                            font.pixelSize: 10
                            font.family: "JetBrains Mono"
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Clock
            Text {
                Layout.alignment: Qt.AlignRight
                text: clock.now.toLocaleTimeString(Qt.locale(), "HH:mm  ddd dd MMM")
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "JetBrains Mono"

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }
            }
        }
    }
}
