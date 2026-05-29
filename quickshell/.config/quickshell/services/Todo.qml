pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var list: []
    readonly property string storePath: Quickshell.env("HOME") + "/.local/state/quickshell/todo.json"

    function addTask(content: string): void {
        var next = root.list.slice();
        next.push({ content: content, done: false });
        root.list = next;
        save();
    }

    function markDone(index: int): void {
        if (index < 0 || index >= root.list.length) return;
        var next = root.list.slice();
        next[index] = Object.assign({}, next[index], { done: !next[index].done });
        root.list = next;
        save();
    }

    function deleteItem(index: int): void {
        if (index < 0 || index >= root.list.length) return;
        var next = root.list.slice();
        next.splice(index, 1);
        root.list = next;
        save();
    }

    function save(): void {
        writeProc.command = ["bash", "-c",
            "mkdir -p ~/.local/state/quickshell && cat > " + root.storePath];
        writeProc.stdinReady.connect(function() {
            writeProc.write(JSON.stringify(root.list));
            writeProc.closeStdin();
        });
        writeProc.running = true;
    }

    function load(): void {
        readProc.running = true;
    }

    Process {
        id: readProc
        command: ["cat", root.storePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.list = JSON.parse(this.text);
                } catch (e) {
                    root.list = [];
                }
            }
        }
    }

    Process {
        id: writeProc
    }

    Component.onCompleted: load()
}
