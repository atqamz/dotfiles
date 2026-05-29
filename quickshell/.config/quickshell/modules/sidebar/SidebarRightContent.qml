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
                font.pixelSize: Theme.font.size.title
                font.bold: true
            }

            StyledText {
                text: Qt.formatDateTime(Time.now, "ddd dd MMM")
                color: Theme.textSecondary
            }

            Item { Layout.fillWidth: true }
        }

        QuickSliders {}

        QuickToggles {}
    }
}
