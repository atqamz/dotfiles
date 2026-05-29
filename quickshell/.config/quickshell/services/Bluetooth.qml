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
    property var allDevices: []
    property bool discovering: false

    function togglePowered(): void {
        if (!root.available) return;
        toggleProc.command = ["bluetoothctl", "power", root.powered ? "off" : "on"];
        toggleProc.running = true;
    }

    function startScan(): void {
        root.discovering = true;
        Quickshell.execDetached(["bluetoothctl", "scan", "on"]);
        scanTimer.restart();
    }

    function stopScan(): void {
        root.discovering = false;
        Quickshell.execDetached(["bluetoothctl", "scan", "off"]);
    }

    function connectDevice(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
    }

    function disconnectDevice(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac]);
    }

    function pairDevice(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "pair", mac]);
    }

    function forgetDevice(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "remove", mac]);
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

    Process {
        id: allDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.startsWith("Device "));
                root.allDevices = lines.map(l => {
                    const parts = l.split(" ");
                    const mac = parts[1] || "";
                    const name = parts.slice(2).join(" ");
                    return {
                        mac: mac,
                        name: name,
                        connected: root.connectedDeviceNames.indexOf(name) >= 0
                    };
                });
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 15000
        repeat: false
        onTriggered: root.stopScan()
    }

    function poll(): void {
        showProc.running = true;
        devicesProc.running = true;
        allDevicesProc.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
