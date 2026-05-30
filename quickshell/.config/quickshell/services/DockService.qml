pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property var pinned: []   // array of desktop ids (strings)
    readonly property string storePath: Quickshell.env("HOME") + "/.local/state/quickshell/dock-pins.json"

    function resolve(appId) {
        if (!appId) return null;
        return DesktopEntries.byId(appId)
            || DesktopEntries.byId(appId.toLowerCase())
            || DesktopEntries.heuristicLookup(appId)
            || null;
    }
    function resolvedId(appId) {
        var e = resolve(appId);
        return e ? e.id : appId;
    }

    // Ordered model: pinned (with toplevels) -> separator -> running-only.
    readonly property var entries: {
        var tl = ToplevelManager.toplevels.values;
        var groups = ({});                       // resolvedId -> [Toplevel]
        for (var i = 0; i < tl.length; ++i) {
            var t = tl[i];
            var rid = root.resolvedId(t.appId);
            if (!groups[rid]) groups[rid] = [];
            groups[rid].push(t);
        }
        var out = [];
        for (var p = 0; p < root.pinned.length; ++p) {
            var pid = root.pinned[p];
            var pe = DesktopEntries.byId(pid) || root.resolve(pid);
            out.push({
                id: pid,
                name: pe ? pe.name : pid,
                iconPath: Quickshell.iconPath(pe ? pe.icon : "", "application-x-executable"),
                toplevels: groups[pid] || [],
                pinned: true
            });
            delete groups[pid];
        }
        var runIds = Object.keys(groups);
        if (root.pinned.length > 0 && runIds.length > 0) out.push({ separator: true });
        for (var r = 0; r < runIds.length; ++r) {
            var e = root.resolve(runIds[r]);
            out.push({
                id: runIds[r],
                name: e ? e.name : runIds[r],
                iconPath: Quickshell.iconPath(e ? e.icon : "", "application-x-executable"),
                toplevels: groups[runIds[r]],
                pinned: false
            });
        }
        return out;
    }

    function isPinned(id) { return root.pinned.indexOf(id) >= 0; }
    function pin(id) {
        if (root.isPinned(id)) return;
        var next = root.pinned.slice(); next.push(id); root.pinned = next; root.save();
    }
    function unpin(id) {
        root.pinned = root.pinned.filter(function (x) { return x !== id; });
        root.save();
    }

    function save() {
        writeProc.command = ["bash", "-c",
            "mkdir -p ~/.local/state/quickshell && cat > " + root.storePath];
        writeProc.stdinReady.connect(function() {
            writeProc.write(JSON.stringify(root.pinned));
            writeProc.closeStdin();
        });
        writeProc.running = true;
    }

    Process {
        id: readProc
        command: ["cat", root.storePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pinned = JSON.parse(this.text); }
                catch (e) { root.pinned = []; }
            }
        }
    }

    Process {
        id: writeProc
    }

    Component.onCompleted: readProc.running = true
}
