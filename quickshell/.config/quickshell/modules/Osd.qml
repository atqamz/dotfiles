import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property string label: ""
    property int value: 0
    property bool active: false

    Process {
        id: volRead
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (!m) return;
                const pct = Math.round(parseFloat(m[1]) * 100);
                root.label = m[2] !== undefined ? "muted" : "volume";
                root.value = pct;
                root.show();
            }
        }
    }

    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "intel_backlight,brightness,9600,40%,24000"
                const cols = this.text.trim().split(",");
                if (cols.length < 4) return;
                const pct = parseInt(cols[3].replace("%", ""), 10);
                root.label = "brightness";
                root.value = pct;
                root.show();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.active = false
    }

    function show(): void {
        root.active = true;
        hideTimer.restart();
    }

    IpcHandler {
        target: "osd"
        function volume(): void { volRead.running = true; }
        function brightness(): void { brightRead.running = true; }
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
                bottom: 60
            }

            implicitHeight: 60
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                implicitWidth: 280
                implicitHeight: 48
                color: "#0a0a0a"
                border.color: "#3a3a3a"
                border.width: 1
                radius: 6

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.label
                        color: "#888888"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        width: 80
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 140
                        height: 6
                        color: "#1a1a1a"
                        radius: 3

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * (root.value / 100)
                            height: parent.height
                            color: "#ffffff"
                            radius: 3
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${root.value}%`
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        width: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
