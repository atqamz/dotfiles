// quickshell/.config/quickshell/modules/NotificationHistory.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components
import qs.services

Scope {
    id: root
    property bool open: false

    Component.onCompleted: {
        NotificationHistory._toggleCb = () => root.open = !root.open;
        NotificationHistory._openCb = () => root.open = true;
        NotificationHistory._closeCb = () => root.open = false;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: root.open
            color: "transparent"

            anchors { top: true; left: true; right: true; bottom: true }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            FocusScope {
                anchors.fill: parent
                focus: root.open
                Keys.onEscapePressed: root.open = false

                Rectangle {
                    anchors.fill: parent
                    color: Theme.scrim
                    MouseArea { anchors.fill: parent; onClicked: root.open = false }
                }
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 480
                implicitHeight: 600
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                radius: Theme.radius.large

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: Theme.text
                            font.pixelSize: Theme.font.size.large
                            font.bold: true
                        }

                        StyledRect {
                            id: clearBtn
                            property bool hovered: clearHover.hovered
                            Layout.preferredHeight: 24
                            implicitWidth: clearLabel.implicitWidth + Theme.padding.large * 2
                            color: clearBtn.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1
                            radius: Theme.radius.full
                            visible: NotificationHistory.history.length > 0

                            HoverHandler { id: clearHover }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: NotificationHistory.clear()
                            }

                            StyledText {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Theme.textVariant
                                font.pixelSize: Theme.font.size.small
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: NotificationHistory.history.length === 0

                        StyledText {
                            anchors.centerIn: parent
                            text: "No notifications"
                            color: Theme.textMuted
                            font.pixelSize: Theme.font.size.normal
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: NotificationHistory.history.length > 0
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing.small

                            Repeater {
                                model: NotificationHistory.history

                                StyledRect {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    property bool hovered: rowHover.hovered

                                    Layout.fillWidth: true
                                    implicitHeight: rowCol.implicitHeight + Theme.padding.normal * 2
                                    color: row.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                                    border.color: Theme.outlineVariant
                                    border.width: 1
                                    radius: Theme.radius.normal

                                    HoverHandler { id: rowHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: NotificationHistory.removeAt(row.index)
                                    }

                                    ColumnLayout {
                                        id: rowCol
                                        anchors.fill: parent
                                        anchors.margins: Theme.padding.normal
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.spacing.small

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: row.modelData.summary
                                                color: Theme.text
                                                font.pixelSize: Theme.font.size.normal
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                text: Qt.formatDateTime(new Date(row.modelData.timestamp), "hh:mm")
                                                color: Theme.textDim
                                                font.pixelSize: Theme.font.size.smaller
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: row.modelData.body.length > 0
                                            text: row.modelData.body
                                            color: Theme.textVariant
                                            font.pixelSize: Theme.font.size.small
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            visible: row.modelData.appName.length > 0
                                            text: row.modelData.appName
                                            color: Theme.textDim
                                            font.pixelSize: Theme.font.size.smaller
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
