import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: bar

    property int volumePercent: 0
    property bool volumeMuted: false
    property int batteryPercent: -1
    property string batteryStatus: ""
    property string networkState: ""

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Volume: 0.42 [MUTED]"
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (m) {
                    bar.volumePercent = Math.round(parseFloat(m[1]) * 100);
                    bar.volumeMuted = m[2] !== undefined;
                }
            }
        }
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "STATE", "general"]
        stdout: StdioCollector {
            onStreamFinished: bar.networkState = this.text.trim()
        }
    }

    FileView {
        id: batCapacityView
        path: "/sys/class/power_supply/BAT0/capacity"
        watchChanges: false
        onLoaded: bar.batteryPercent = parseInt(this.text(), 10)
        onLoadFailed: {
            // try BAT1
            batCapacityView.path = "/sys/class/power_supply/BAT1/capacity";
            batStatusView.path = "/sys/class/power_supply/BAT1/status";
        }
    }

    FileView {
        id: batStatusView
        path: "/sys/class/power_supply/BAT0/status"
        watchChanges: false
        onLoaded: bar.batteryStatus = this.text().trim()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volProc.running = true;
            netProc.running = true;
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batCapacityView.reload();
            batStatusView.reload();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 28
            color: "#000000"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Workspace indicator
                Row {
                    Layout.alignment: Qt.AlignLeft
                    spacing: 6

                    Repeater {
                        model: Hyprland.workspaces

                        Rectangle {
                            required property var modelData
                            width: 16
                            height: 16
                            radius: 2
                            color: modelData.active ? "#ffffff" : "#1a1a1a"
                            border.color: "#3a3a3a"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                color: modelData.active ? "#000000" : "#888888"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono"
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Network indicator
                Text {
                    Layout.alignment: Qt.AlignRight
                    visible: bar.networkState.length > 0
                    text: bar.networkState === "connected" ? "net" : `net:${bar.networkState}`
                    color: bar.networkState === "connected" ? "#cccccc" : "#ff8866"
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                }

                // Volume indicator
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: bar.volumeMuted ? "muted" : `vol ${bar.volumePercent}%`
                    color: bar.volumeMuted ? "#666666" : "#cccccc"
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                }

                // Battery indicator
                Text {
                    Layout.alignment: Qt.AlignRight
                    visible: bar.batteryPercent >= 0
                    text: {
                        const prefix = bar.batteryStatus === "Charging" ? "chg" : "bat";
                        return `${prefix} ${bar.batteryPercent}%`;
                    }
                    color: {
                        if (bar.batteryPercent < 10 && bar.batteryStatus !== "Charging")
                            return "#ff4444";
                        if (bar.batteryPercent < 25 && bar.batteryStatus !== "Charging")
                            return "#ffaa44";
                        return "#cccccc";
                    }
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                }

                // Clock
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: clock.now.toLocaleTimeString(Qt.locale(), "HH:mm  ddd dd MMM")
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"

                    SystemClock {
                        id: clock
                        precision: SystemClock.Minutes
                    }
                }
            }
        }
    }
}
