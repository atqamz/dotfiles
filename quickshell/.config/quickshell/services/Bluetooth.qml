pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property int connectedDeviceCount: 0
    property var connectedDeviceNames: []

    function togglePowered(): void {
        if (!root.available) return;
        toggleProc.command = ["bluetoothctl", "power", root.powered ? "off" : "on"];
        toggleProc.running = true;
    }

    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text;
                if (out.length === 0) {
                    root.available = false;
                    root.powered = false;
                    return;
                }
                root.available = true;
                const m = out.match(/Powered:\s+(yes|no)/);
                root.powered = m && m[1] === "yes";
            }
        }
    }

    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.startsWith("Device "));
                root.connectedDeviceCount = lines.length;
                root.connectedDeviceNames = lines.map(l => {
                    const parts = l.split(" ");
                    return parts.slice(2).join(" ");
                });
            }
        }
    }

    Process {
        id: toggleProc
        onExited: poll()
    }

    function poll(): void {
        showProc.running = true;
        devicesProc.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
