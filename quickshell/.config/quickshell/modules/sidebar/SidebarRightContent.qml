import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
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

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.normal
                color: "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "settings"
                    font.pixelSize: Theme.icon.size.normal
                    color: Theme.textVariant
                }

                StateLayer { pressed: settingsBtnTap.pressed }

                MouseArea {
                    id: settingsBtnTap
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "open"])
                }
            }
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

        SectionHeader { label: "Calendar"; Layout.topMargin: Theme.spacing.small }
        CalendarWidget {}

        SectionHeader { label: "Tasks"; Layout.topMargin: Theme.spacing.small }
        TodoWidget {}

        SectionHeader { label: "Focus"; Layout.topMargin: Theme.spacing.small }
        PomodoroWidget {}

        SectionHeader {
            label: "Notifications"
            Layout.topMargin: Theme.spacing.small

            StyledText {
                visible: NotificationHistory.history.length > 0
                text: NotificationHistory.history.length.toString()
                font.pixelSize: Theme.font.size.smaller
                color: Theme.textMuted
            }
            IconButton {
                visible: NotificationHistory.history.length > 0
                radius: Theme.radius.full
                padding: Theme.padding.small
                icon: "clear_all"
                onClicked: NotificationHistory.clear()
            }
        }
        NotificationList {}
    }
}
