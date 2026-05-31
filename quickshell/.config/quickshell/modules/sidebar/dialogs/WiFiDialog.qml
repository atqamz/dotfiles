import QtQuick
import QtQuick.Controls
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

            Item {
                property real radius: Theme.radius.small
                implicitWidth: refreshIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: refreshIcon.implicitHeight + 2 * Theme.padding.smaller

                StateLayer {
                    pressed: refreshMa.pressed
                }

                MaterialIcon {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "refresh"
                    color: Network.scanning ? Theme.tertiary : Theme.textVariant
                    font.pixelSize: Theme.icon.size.small

                    RotationAnimation on rotation {
                        running: Network.scanning
                        from: 0; to: 360
                        duration: Theme.anim.durations.spring
                        easing.type: Easing.Linear
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    onClicked: Network.scanWifi()
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
            model: Network.wifiNetworks

            Rectangle {
                id: netRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                height: 40
                radius: Theme.radius.normal
                color: modelData.active ? Theme.surfaceContainerHighest : "transparent"

                StateLayer {
                    pressed: netMa.pressed
                    focused: netRow.modelData.active
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.padding.normal
                    anchors.rightMargin: Theme.padding.normal
                    spacing: Theme.spacing.normal

                    MaterialIcon {
                        text: modelData.signal > 75 ? "signal_wifi_4_bar"
                            : modelData.signal > 50 ? "network_wifi_3_bar"
                            : modelData.signal > 25 ? "network_wifi_2_bar"
                            : "network_wifi_1_bar"
                        color: modelData.active ? Theme.tertiary : Theme.textVariant
                        font.pixelSize: Theme.icon.size.small
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
                        font.pixelSize: Theme.icon.size.small
                    }

                    MaterialIcon {
                        visible: modelData.active
                        text: "check"
                        color: Theme.tertiary
                        font.pixelSize: Theme.icon.size.small
                    }
                }

                MouseArea {
                    id: netMa
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
