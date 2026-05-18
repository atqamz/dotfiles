// quickshell/.config/quickshell/services/Updates.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int available: 0
    property bool checking: false
    property date lastChecked: new Date(0)

    function refresh() {
        if (proc.running) return;
        root.checking = true;
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", "-c", "dnf -q check-update 2>/dev/null; exit 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                let count = 0;
                for (const line of lines) {
                    if (/^[A-Za-z0-9][^ ]*\.[^ ]+\s+\S+\s+\S+$/.test(line)) count++;
                }
                root.available = count;
                root.lastChecked = new Date();
            }
        }
        onRunningChanged: {
            if (!proc.running) root.checking = false;
        }
    }

    Timer {
        interval: 1800000     // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "updates"
        function refresh(): void { root.refresh(); }
    }
}
