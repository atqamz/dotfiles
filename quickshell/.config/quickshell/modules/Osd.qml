import Quickshell
import Quickshell.Io
import QtQuick
import qs.components
import qs.services

Scope {
    id: root

    // "volume" | "brightness"
    property string kind: ""
    property int value: 0
    property bool muted: false
    property bool active: false

    function show(): void {
        root.active = true;
        hideTimer.restart();
    }

    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cols = this.text.trim().split(",");
                if (cols.length < 4) return;
                root.kind = "brightness";
                root.value = parseInt(cols[3].replace("%", ""), 10);
                root.muted = false;
                root.show();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.active = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            if (root.kind === "volume" || !root.active) {
                root.kind = "volume";
                root.value = Audio.volume;
                root.muted = Audio.muted;
            }
        }
        function onMutedChanged() {
            root.kind = "volume";
            root.value = Audio.volume;
            root.muted = Audio.muted;
        }
    }

    IpcHandler {
        target: "osd"
        function volume(): void {
            Audio.refresh();
            root.kind = "volume";
            root.value = Audio.volume;
            root.muted = Audio.muted;
            root.show();
        }
        function brightness(): void {
            brightRead.running = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active

            anchors {
                bottom: true
                left: true
                right: true
            }

            margins {
                bottom: 80
            }

            implicitHeight: 80
            color: "transparent"

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 320
                implicitHeight: 60
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.full

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.kind === "brightness") return "brightness_6";
                            if (root.muted) return "volume_off";
                            if (root.value === 0) return "volume_mute";
                            if (root.value < 50) return "volume_down";
                            return "volume_up";
                        }
                        color: root.muted ? Theme.textDim : Theme.text
                        font.pixelSize: 24
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 180
                        implicitHeight: 8

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHigh
                            radius: Theme.radius.full
                        }

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.value / 100))
                            height: parent.height
                            color: root.muted ? Theme.textDim : Theme.primary
                            radius: Theme.radius.full

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.anim.durations.normal
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.value + "%"
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal
                        width: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
