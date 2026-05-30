import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services
import "dialogs"

Flickable {
    id: root

    property string activeDialog: ""

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: StyledScrollBar {}

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

        QuickToggles {
            onOpenWifiDialog: root.activeDialog = root.activeDialog === "wifi" ? "" : "wifi"
            onOpenBluetoothDialog: root.activeDialog = root.activeDialog === "bluetooth" ? "" : "bluetooth"
            onOpenNightLightDialog: root.activeDialog = root.activeDialog === "nightlight" ? "" : "nightlight"
        }

        // Dialog area
        Loader {
            Layout.fillWidth: true
            active: root.activeDialog === "wifi"
            visible: active
            sourceComponent: WiFiDialog {
                onDismiss: root.activeDialog = ""
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.activeDialog === "bluetooth"
            visible: active
            sourceComponent: BluetoothDialog {
                onDismiss: root.activeDialog = ""
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.activeDialog === "nightlight"
            visible: active
            sourceComponent: NightLightDialog {
                onDismiss: root.activeDialog = ""
            }
        }

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

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        NotificationList {}
    }
}
