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
    property bool wifiEnabled: false
    property var wifiNetworks: []
    property var savedConnections: []
    property bool scanning: false

    // True when a saved wifi profile exists for this SSID, so connecting needs
    // no password prompt (nmcli reuses the stored credentials).
    function isSaved(ssid: string): bool {
        return root.savedConnections.indexOf(ssid) !== -1;
    }

    function setWifiRadio(on: bool): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    function toggleWifi(): void {
        setWifiRadio(!root.wifiEnabled);
    }

    function disconnectWifi(ssid: string): void {
        Quickshell.execDetached(["nmcli", "connection", "down", "id", ssid]);
    }

    function scanWifi(): void {
        root.scanning = true;
        scanProc.running = true;
    }

    // Fast list refresh (no rescan) to pick up the active flag after connect.
    function refreshWifiList(): void {
        listProc.running = true;
    }

    function poll(): void {
        stateProc.running = true;
        activeProc.running = true;
        radioProc.running = true;
        savedProc.running = true;
        listProc.running = true;
    }

    function connectWifi(ssid: string, password: string): void {
        if (password.length > 0)
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
        else
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
    }

    // Shared parse for both the rescan (scanProc) and the light refresh (listProc).
    function applyWifiList(text: string): void {
        const lines = text.trim().split("\n").filter(l => l.length > 0);
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
                root.applyWifiList(this.text);
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.applyWifiList(this.text)
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = [];
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless")
                        names.push(parts[0]);
                }
                root.savedConnections = names;
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
