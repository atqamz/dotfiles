pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dirPath: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string filePath: dirPath + "/settings.json"
    property alias options: jsonAdapter
    property bool ready: false
    readonly property int readWriteDelay: 50

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object")
                obj[keys[i]] = {};
            obj = obj[keys[i]];
        }
        let converted = value;
        if (typeof value === "string") {
            let t = value.trim();
            if (t === "true" || t === "false" || (t !== "" && !isNaN(Number(t)))) {
                try { converted = JSON.parse(t); } catch (e) { converted = value; }
            }
        }
        obj[keys[keys.length - 1]] = converted;
    }

    // FileView won't create missing parent dirs. On first run (file missing) we must
    // mkdir BEFORE the first writeAdapter(). The Process is async, so gate the
    // initial write on its exit rather than racing it from Component.onCompleted.
    property bool _pendingWrite: false
    Process {
        id: ensureDirProc
        command: ["bash", "-c", "mkdir -p " + root.dirPath]
        onExited: {
            if (root._pendingWrite) { root._pendingWrite = false; fileView.writeAdapter(); }
        }
    }

    Timer { id: reloadTimer; interval: root.readWriteDelay; onTriggered: fileView.reload() }
    Timer { id: writeTimer;  interval: root.readWriteDelay; onTriggered: fileView.writeAdapter() }

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        blockLoading: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
                root._pendingWrite = true;
                ensureDirProc.running = true;   // writes defaults once mkdir exits
            }
        }

        JsonAdapter {
            id: jsonAdapter

            property JsonObject appearance: JsonObject {
                property string fontFamily: "Rubik"
                property real fontScale: 1.0
                property real radiusScale: 1.0
                property real motionScale: 1.0
            }
            property JsonObject bar: JsonObject {
                property int height: 28
                property bool clock24h: true
                property bool showLauncher: true
                property bool showWorkspaces: true
                property bool showMedia: true
                property bool showClock: true
                property bool showResources: true
                property bool showTray: true
                property bool showStatus: true
            }
            property JsonObject dock: JsonObject {
                property bool enable: true
                property int height: 60
                property int iconSize: 36
                property bool autoHide: true
            }
            property JsonObject overview: JsonObject {
                property real scale: 0.18
                property int rows: 2
                property int columns: 5
            }
            property JsonObject behavior: JsonObject {
                property int notifTimeout: 5000
                property int notifMaxVisible: 5
                property int notifHistoryMax: 50
                property bool dndDefault: false
                property int nightTemp: 4000
            }
        }
    }
}
