import QtQuick
import QtQuick.Controls
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

    Component.onCompleted: Network.scanWifi()

    ColumnLayout {
        id: dialogCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "WiFi Networks"
                font.pixelSize: Theme.font.size.large
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            MaterialIcon {
                text: "refresh"
                color: Network.scanning ? Theme.tertiary : Theme.textVariant
                font.pixelSize: 18

                RotationAnimation on rotation {
                    running: Network.scanning
                    from: 0; to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Network.scanWifi()
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
            model: Network.wifiNetworks

            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                height: 40
                radius: Theme.radius.normal
                color: modelData.active ? Theme.surfaceContainerHigh : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    MaterialIcon {
                        text: modelData.signal > 75 ? "signal_wifi_4_bar"
                            : modelData.signal > 50 ? "network_wifi_3_bar"
                            : modelData.signal > 25 ? "network_wifi_2_bar"
                            : "network_wifi_1_bar"
                        color: modelData.active ? Theme.tertiary : Theme.textVariant
                        font.pixelSize: 18
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.ssid
                        color: Theme.text
                        elide: Text.ElideRight
                    }

                    MaterialIcon {
                        visible: modelData.security.length > 0
                        text: "lock"
                        color: Theme.textMuted
                        font.pixelSize: 14
                    }

                    MaterialIcon {
                        visible: modelData.active
                        text: "check"
                        color: Theme.tertiary
                        font.pixelSize: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!modelData.active)
                            Network.connectWifi(modelData.ssid, "");
                    }
                }
            }
        }

        StyledText {
            visible: Network.wifiNetworks.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: Network.scanning ? "Scanning..." : "No networks found"
            color: Theme.textMuted
        }
    }
}
