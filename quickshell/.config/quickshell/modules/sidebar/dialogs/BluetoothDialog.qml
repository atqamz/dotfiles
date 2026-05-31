import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    signal dismiss()

    color: Theme.surfaceContainerHigh
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

            Item {
                property real radius: Theme.radius.small
                implicitWidth: scanIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: scanIcon.implicitHeight + 2 * Theme.padding.smaller

                StateLayer {
                    pressed: scanMa.pressed
                }

                MaterialIcon {
                    id: scanIcon
                    anchors.centerIn: parent
                    text: "bluetooth_searching"
                    color: Bluetooth.discovering ? Theme.tertiary : Theme.textVariant
                    font.pixelSize: Theme.icon.size.small
                    opacity: Bluetooth.discovering ? 1.0 : 0.5

                    Behavior on opacity { Anim { curve: Theme.anim.standard } }
                }

                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    onClicked: Bluetooth.discovering ? Bluetooth.stopScan() : Bluetooth.startScan()
                }
            }

            IconButton {
                icon: "close"
                onClicked: root.dismiss()
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
                id: devItem
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: devRow.implicitHeight + 16
                radius: Theme.radius.normal
                color: modelData.connected ? Theme.surfaceContainerHighest : "transparent"

                property bool expanded: false

                StateLayer {
                    pressed: devMa.pressed
                    focused: devItem.modelData.connected
                }

                ColumnLayout {
                    id: devRow
                    anchors.fill: parent
                    anchors.margins: Theme.padding.normal
                    spacing: Theme.spacing.smaller

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.normal

                        MaterialIcon {
                            text: modelData.connected ? "bluetooth_connected" : "bluetooth"
                            color: modelData.connected ? Theme.tertiary : Theme.textVariant
                            font.pixelSize: Theme.icon.size.small
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
                        spacing: Theme.spacing.smaller

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radius.normal
                            color: Theme.surfaceContainerLow

                            StateLayer {
                                pressed: connectMa.pressed
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Connect"
                                font.pixelSize: Theme.font.size.smaller
                                color: Theme.text
                            }

                            MouseArea {
                                id: connectMa
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

                            StateLayer {
                                pressed: forgetMa.pressed
                                tint: Theme.error
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: "Forget"
                                font.pixelSize: Theme.font.size.smaller
                                color: Theme.error
                            }

                            MouseArea {
                                id: forgetMa
                                anchors.fill: parent
                                onClicked: Bluetooth.forgetDevice(modelData.mac)
                            }
                        }
                    }
                }

                MouseArea {
                    id: devMa
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
