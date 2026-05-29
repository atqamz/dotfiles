pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string state: ""
    property string connectivity: ""
    property string activeConnection: ""
    readonly property bool connected: state === "connected"
    property var wifiNetworks: []
    property bool scanning: false

    function toggleWifi(): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi",
            root.state === "connected" ? "off" : "on"]);
    }

    function scanWifi(): void {
        root.scanning = true;
        scanProc.running = true;
    }

    function connectWifi(ssid: string, password: string): void {
        if (password.length > 0)
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
        else
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
    }

    Process {
        id: stateProc
        command: ["nmcli", "-t", "-f", "STATE,CONNECTIVITY", "general"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(":");
                if (parts.length >= 1) root.state = parts[0];
                if (parts.length >= 2) root.connectivity = parts[1];
            }
        }
    }

    Process {
        id: activeProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                // Prefer wifi/ethernet over tun/bridge
                const ranked = lines.map(l => l.split(":")).filter(c => c.length >= 3);
                ranked.sort((a, b) => {
                    const rank = t => (t === "802-11-wireless" ? 0 : t === "802-3-ethernet" ? 1 : 2);
                    return rank(a[1]) - rank(b[1]);
                });
                root.activeConnection = ranked.length > 0 ? ranked[0][0] : "";
            }
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                const seen = {};
                const nets = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length < 4 || !parts[0]) continue;
                    if (seen[parts[0]]) continue;
                    seen[parts[0]] = true;
                    nets.push({
                        ssid: parts[0],
                        signal: parseInt(parts[1]) || 0,
                        security: parts[2] || "",
                        active: parts[3] === "*"
                    });
                }
                nets.sort((a, b) => b.signal - a.signal);
                root.wifiNetworks = nets;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stateProc.running = true;
            activeProc.running = true;
        }
    }
}
