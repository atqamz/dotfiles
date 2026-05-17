import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.modules.bar as BarModules

Scope {
    id: bar

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
            }

            implicitWidth: Theme.bar.width + 2 * Theme.bar.margin
            color: "transparent"

            // Vertical dock — caelestia signature look. The outer panel is
            // transparent so the inner StyledRect provides a rounded floating
            // bar with breathing room from the screen edge.
            StyledRect {
                anchors.fill: parent
                anchors.margins: Theme.bar.margin
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.padding.large
                    anchors.bottomMargin: Theme.padding.large
                    anchors.leftMargin: Theme.padding.normal
                    anchors.rightMargin: Theme.padding.normal
                    spacing: Theme.spacing.larger

                    BarModules.OsIcon {
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
                    }

                    BarModules.Workspaces {
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }

                    BarModules.StatusIcons {
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Theme.spacing.normal
                        Layout.bottomMargin: Theme.spacing.normal
                        implicitWidth: 18
                        implicitHeight: 1
                        color: Theme.outlineVariant
                    }

                    BarModules.Clock {
                        Layout.alignment: Qt.AlignHCenter
                    }

                    BarModules.PowerButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Theme.spacing.large
                    }
                }
            }
        }
    }
}
