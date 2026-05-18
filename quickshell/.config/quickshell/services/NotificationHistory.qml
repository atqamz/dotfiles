// quickshell/.config/quickshell/services/NotificationHistory.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 50
    property var history: []
    readonly property alias server: notifServer

    function _push(notif) {
        const entry = {
            id: Date.now() + "-" + Math.floor(Math.random() * 1000),
            summary: notif.summary || "",
            body: notif.body || "",
            appName: notif.appName || "",
            timestamp: Date.now()
        };
        const next = [entry].concat(root.history);
        if (next.length > root.historyLimit) next.length = root.historyLimit;
        root.history = next;
    }

    function clear() { root.history = []; }

    function removeAt(idx) {
        if (idx < 0 || idx >= root.history.length) return;
        const next = root.history.slice();
        next.splice(idx, 1);
        root.history = next;
    }

    NotificationServer {
        id: notifServer
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: false
        persistenceSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
            root._push(notif);
        }
    }

    IpcHandler {
        target: "notificationHistory"
        function toggle(): void { root._toggleCb && root._toggleCb(); }
        function open(): void   { root._openCb   && root._openCb();   }
        function close(): void  { root._closeCb  && root._closeCb();  }
        function clear(): void  { root.clear(); }
    }

    property var _toggleCb: null
    property var _openCb: null
    property var _closeCb: null
}
