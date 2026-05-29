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

    ColumnLayout {
        id: dialogCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Night Light"
                font.pixelSize: Theme.font.size.large
                font.bold: true
            }

            Item { Layout.fillWidth: true }

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

        // Enable toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "Enable"
                color: Theme.text
            }

            Rectangle {
                width: 48; height: 28; radius: 14
                color: Hyprsunset.active ? Theme.primary : Theme.surfaceContainerHigh

                Behavior on color { ColorAnimation { duration: 200 } }

                Rectangle {
                    width: 20; height: 20; radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: Hyprsunset.active ? parent.width - width - 4 : 4
                    color: Hyprsunset.active ? Theme.textOnPrimary : Theme.textMuted

                    Behavior on x { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprsunset.toggle()
                }
            }
        }

        // Temperature slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Temperature"
                    color: Theme.textVariant
                    font.pixelSize: Theme.font.size.small
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: Hyprsunset.temperature + "K"
                    color: Theme.textVariant
                    font.pixelSize: Theme.font.size.small
                }
            }

            Slider {
                id: tempSlider
                Layout.fillWidth: true
                from: 1200
                to: 6500
                stepSize: 100
                value: Hyprsunset.temperature
                onMoved: Hyprsunset.setTemperature(Math.round(value))

                background: Rectangle {
                    x: tempSlider.leftPadding
                    y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                    width: tempSlider.availableWidth
                    height: 4
                    radius: 2

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ff8800" }
                        GradientStop { position: 0.5; color: "#ffcc88" }
                        GradientStop { position: 1.0; color: "#ffffff" }
                    }
                }

                handle: Rectangle {
                    x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                    y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                    width: 16; height: 16; radius: 8
                    color: Theme.primary
                }
            }
        }

        // Presets
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { label: "Warm", temp: 2700 },
                    { label: "Cozy", temp: 3500 },
                    { label: "Default", temp: 4000 },
                    { label: "Cool", temp: 5500 }
                ]

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radius.normal
                    color: Hyprsunset.temperature === modelData.temp ? Theme.surfaceContainerHigh : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.font.size.smaller
                        color: Hyprsunset.temperature === modelData.temp ? Theme.text : Theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Hyprsunset.setTemperature(modelData.temp);
                            if (!Hyprsunset.active) Hyprsunset.toggle();
                        }
                    }
                }
            }
        }
    }
}
