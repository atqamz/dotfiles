pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real brightness: 0
    property real max: 1

    function refresh(): void {
        proc.running = true;
    }

    function setBrightness(value: real): void {
        Quickshell.execDetached(["brightnessctl", "set", Math.round(value * 100) + "%"]);
        refresh();
    }

    function increment(): void {
        Quickshell.execDetached(["brightnessctl", "set", "10%+"]);
        refresh();
    }

    function decrement(): void {
        Quickshell.execDetached(["brightnessctl", "set", "10%-"]);
        refresh();
    }

    Process {
        id: proc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",");
                if (parts.length < 4) return;
                root.max = parseInt(parts[2]) || 1;
                const current = parseInt(parts[3]) || 0;
                root.brightness = current / root.max;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
