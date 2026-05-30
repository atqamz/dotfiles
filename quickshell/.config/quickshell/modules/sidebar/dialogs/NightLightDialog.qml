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

            Item {
                property real radius: Theme.radius.small
                implicitWidth: closeIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: closeIcon.implicitHeight + 2 * Theme.padding.smaller

                StateLayer {
                    id: closeState
                    pressed: closeMa.pressed
                }

                MaterialIcon {
                    id: closeIcon
                    anchors.centerIn: parent
                    text: "close"
                    color: Theme.textVariant
                    font.pixelSize: Theme.icon.size.small
                }

                MouseArea {
                    id: closeMa
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

            StyledSwitch {
                checked: Hyprsunset.active
                onToggled: Hyprsunset.toggle()
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
                    radius: Theme.radius.small

                    // warmth data-viz, intentional
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
                    width: 16; height: 16; radius: Theme.radius.full
                    color: Theme.primary
                    border.width: tempSlider.activeFocus ? 2 : 0
                    border.color: Theme.primary
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
                    id: presetRow
                    required property var modelData
                    readonly property bool selected: Hyprsunset.temperature === modelData.temp
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radius.normal
                    color: selected ? Theme.surfaceContainerHighest : "transparent"

                    StateLayer {
                        pressed: presetMa.pressed
                        focused: presetRow.selected
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.font.size.smaller
                        color: presetRow.selected ? Theme.text : Theme.textMuted
                    }

                    MouseArea {
                        id: presetMa
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
