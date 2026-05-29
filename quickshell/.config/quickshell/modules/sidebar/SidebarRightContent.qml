import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Flickable {
    id: root

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Qt.formatDateTime(Time.now, "HH:mm")
                font.pixelSize: Theme.font.size.extraLarge
                font.bold: true
            }

            StyledText {
                text: Qt.formatDateTime(Time.now, "ddd dd MMM")
                color: Theme.textVariant
            }

            Item { Layout.fillWidth: true }
        }

        QuickSliders {}

        QuickToggles {}

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        CalendarWidget {}

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        TodoWidget {}

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        PomodoroWidget {}
    }
}
