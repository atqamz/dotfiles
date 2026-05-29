import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Notifications"
                font.pixelSize: Theme.font.size.large
                font.bold: true
            }

            StyledText {
                visible: NotificationHistory.history.length > 0
                text: NotificationHistory.history.length.toString()
                font.pixelSize: Theme.font.size.smaller
                color: Theme.textMuted
            }

            Item { Layout.fillWidth: true }

            MaterialIcon {
                visible: NotificationHistory.history.length > 0
                text: "clear_all"
                color: Theme.textVariant
                font.pixelSize: 18

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotificationHistory.clear()
                }
            }
        }

        Repeater {
            model: NotificationHistory.history.slice(0, 10)

            StyledRect {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                color: Theme.surface
                radius: Theme.radius.normal
                implicitHeight: notifCol.implicitHeight + 12

                ColumnLayout {
                    id: notifCol
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.summary
                            font.pixelSize: Theme.font.size.small
                            font.bold: true
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: {
                                var d = new Date(modelData.timestamp);
                                return Qt.formatTime(d, "HH:mm");
                            }
                            font.pixelSize: Theme.font.size.smaller
                            color: Theme.textDim
                        }
                    }

                    StyledText {
                        visible: modelData.body.length > 0
                        Layout.fillWidth: true
                        text: modelData.body
                        font.pixelSize: Theme.font.size.smaller
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    StyledText {
                        visible: modelData.appName.length > 0
                        text: modelData.appName
                        font.pixelSize: Theme.font.size.smaller
                        color: Theme.textDim
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: NotificationHistory.removeAt(index)
                }
            }
        }

        StyledText {
            visible: NotificationHistory.history.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: "No notifications"
            color: Theme.textMuted
        }
    }
}
