// quickshell/.config/quickshell/modules/RecordingIndicator.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services

Scope {
    id: root

    property bool recording: false

    IpcHandler {
        target: "record"
        function start(): void { root.recording = true; }
        function stop(): void { root.recording = false; }
        function toggle(): void { root.recording = !root.recording; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.recording

            anchors {
                top: true
                right: true
            }

            margins {
                top: 8
                right: 8
            }

            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            StyledRect {
                id: pill
                implicitWidth: row.implicitWidth + 24
                implicitHeight: 28
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.full

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: Theme.error

                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "REC"
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
}
