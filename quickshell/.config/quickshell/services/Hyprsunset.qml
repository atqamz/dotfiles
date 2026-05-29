pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property int temperature: 4000

    function toggle(): void {
        if (active) {
            Quickshell.execDetached(["pkill", "hyprsunset"]);
        } else {
            Quickshell.execDetached(["hyprsunset", "-t", temperature.toString()]);
        }
        fetchTimer.restart();
    }

    function setTemperature(kelvin: int): void {
        temperature = kelvin;
        if (active) {
            Quickshell.execDetached(["pkill", "hyprsunset"]);
            Qt.callLater(() => {
                Quickshell.execDetached(["hyprsunset", "-t", temperature.toString()]);
                fetchTimer.restart();
            });
        }
    }

    function fetchState(): void {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["pgrep", "-x", "hyprsunset"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = this.text.trim().length > 0;
            }
        }
    }

    Timer {
        id: fetchTimer
        interval: 1000
        repeat: false
        onTriggered: proc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
