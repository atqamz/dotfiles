import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    signal dismiss()

    color: Theme.background
    radius: Theme.radius.large
    border.color: Theme.outlineVariant
    border.width: 1

    implicitHeight: dialogCol.implicitHeight + 24

    Component.onCompleted: Bluetooth.startScan()
    Component.onDestruction: Bluetooth.stopScan()

    ColumnLayout {
        id: dialogCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Bluetooth Devices"
                font.pixelSize: Theme.font.size.large
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            MaterialIcon {
                text: "bluetooth_searching"
                color: Bluetooth.discovering ? Theme.tertiary : Theme.textVariant
                font.pixelSize: 18
                opacity: Bluetooth.discovering ? 1.0 : 0.5

                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Bluetooth.discovering ? Bluetooth.stopScan() : Bluetooth.startScan()
                }
            }

            MaterialIcon {
                text: "close"
                color: Theme.textVariant
                font.pixelSize: 18

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismiss()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        Repeater {
            model: Bluetooth.allDevices

            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: devRow.implicitHeight + 16
                radius: Theme.radius.normal
                color: modelData.connected ? Theme.surfaceContainerHigh : "transparent"

                property bool expanded: false

                ColumnLayout {
                    id: devRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialIcon {
                            text: modelData.connected ? "bluetooth_connected" : "bluetooth"
                            color: modelData.connected ? Theme.tertiary : Theme.textVariant
                            font.pixelSize: 18
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.mac
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        StyledText {
                            visible: modelData.connected
                            text: "Connected"
                            font.pixelSize: Theme.font.size.smaller
                            color: Theme.tertiary
                        }
                    }

                    RowLayout {
                        visible: expanded
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radius.normal
                            color: Theme.surfaceContainerLow

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Connect"
                                font.pixelSize: Theme.font.size.smaller
                                color: Theme.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.connected
                                    ? Bluetooth.disconnectDevice(modelData.mac)
                                    : Bluetooth.connectDevice(modelData.mac)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radius.normal
                            color: Theme.surfaceContainerLow

                            StyledText {
                                anchors.centerIn: parent
                                text: "Forget"
                                font.pixelSize: Theme.font.size.smaller
                                color: Theme.error
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Bluetooth.forgetDevice(modelData.mac)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: expanded = !expanded
                }
            }
        }

        StyledText {
            visible: Bluetooth.allDevices.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: Bluetooth.discovering ? "Scanning..." : "No devices found"
            color: Theme.textMuted
        }
    }
}
