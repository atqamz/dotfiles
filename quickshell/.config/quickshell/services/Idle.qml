pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool inhibited: false

    function toggle(): void {
        if (inhibited) {
            Quickshell.execDetached(["hypridle"]);
        } else {
            Quickshell.execDetached(["pkill", "-x", "hypridle"]);
        }
        fetchTimer.restart();
    }

    function fetchState(): void {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["pgrep", "-x", "hypridle"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.inhibited = this.text.trim().length === 0;
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
