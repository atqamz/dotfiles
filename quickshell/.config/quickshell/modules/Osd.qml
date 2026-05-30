// quickshell/.config/quickshell/modules/Osd.qml
import Quickshell
import Quickshell.Io
import QtQuick
import qs.components
import qs.services

Scope {
    id: root

    // "volume" | "brightness" | "microphone"
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

    Process {
        id: micRead
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (!m) return;
                root.kind = "microphone";
                root.value = Math.round(parseFloat(m[1]) * 100);
                root.muted = m[2] !== undefined;
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
        function microphone(): void {
            micRead.running = true;
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

            implicitHeight: 90
            color: "transparent"

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 360
                implicitHeight: 72
                color: Theme.surfaceContainer
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
                            if (root.kind === "microphone") return root.muted ? "mic_off" : "mic";
                            if (root.muted) return "volume_off";
                            if (root.value === 0) return "volume_mute";
                            if (root.value < 50) return "volume_down";
                            return "volume_up";
                        }
                        color: root.muted ? Theme.textDim : Theme.text
                        font.pixelSize: Theme.icon.size.large
                    }

                    StyledProgressBar {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 220
                        implicitHeight: 10
                        from: 0
                        to: root.kind === "volume" ? 150 : 100
                        value: root.value
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.muted ? "--" : (root.value + "%")
                        color: Theme.text
                        font.pixelSize: Theme.font.size.large
                        font.bold: true
                        width: 56
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
