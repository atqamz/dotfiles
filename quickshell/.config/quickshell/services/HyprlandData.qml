pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []
    property var monitors: []

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) return null;
        return root.windowByAddress["0x" + toplevel.HyprlandToplevel.address] || null;
    }

    function refresh() { clientsProc.running = true; monitorsProc.running = true; }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var list = JSON.parse(this.text).filter(function (c) { return c.mapped !== false; });
                    var byAddr = ({});
                    for (var i = 0; i < list.length; ++i) byAddr[list[i].address] = list[i];
                    root.windowList = list;
                    root.windowByAddress = byAddr;
                    root.addresses = list.map(function (c) { return c.address; });
                } catch (e) { /* keep last good */ }
            }
        }
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(this.text); } catch (e) {}
            }
        }
    }

    // Debounced refresh on Hyprland events; skip noisy ones (screencast is
    // emitted BY ScreencopyView -> would feedback-loop while overview is open).
    Timer {
        id: debounce
        interval: 100; repeat: false
        onTriggered: root.refresh()
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].indexOf(event.name) !== -1) return;
            debounce.restart();
        }
    }

    Component.onCompleted: root.refresh()
}
