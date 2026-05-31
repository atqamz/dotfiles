// quickshell/.config/quickshell/modules/Launcher.qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import qs.components
import "../components/Fuzzy.js" as Fuzzy

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property bool isShellCmd: root.query.startsWith(">")
    readonly property string shellCmd: root.query.substring(1).trim()
    readonly property bool isMath: /^[\d+\-*/().\s%]+$/.test(root.query) && root.query.trim().length > 0
    readonly property string mathResult: {
        if (!root.isMath) return "";
        try {
            const expr = root.query.replace(/%/g, "/100");
            const fn = new Function("return (" + expr + ")");
            const r = fn();
            if (typeof r !== "number" || !isFinite(r)) return "";
            return "= " + r;
        } catch (_) { return ""; }
    }

    readonly property var filteredApps: {
        const q = root.query;
        const visible = DesktopEntries.applications.values.filter(app => !app.noDisplay);
        if (q.length === 0) {
            visible.sort((a, b) => a.name.localeCompare(b.name));
            return visible.slice(0, 8);
        }
        // Tiered fuzzy match: a name hit always outranks a genericName hit, which
        // outranks a comment hit. Within a tier the fuzzy score (then name)
        // orders results. The 1000-point tier gaps dwarf any single score.
        const scored = [];
        for (let i = 0; i < visible.length; ++i) {
            const app = visible[i];
            const sn = Fuzzy.score(q, app.name);
            const sg = Fuzzy.score(q, app.genericName || "");
            const sc = Fuzzy.score(q, app.comment || "");
            let best = null;
            if (sn !== null) best = sn;
            else if (sg !== null) best = sg - 1000;
            else if (sc !== null) best = sc - 2000;
            if (best !== null) scored.push({ app, s: best });
        }
        scored.sort((a, b) => (b.s - a.s) || a.app.name.localeCompare(b.app.name));
        return scored.slice(0, 8).map(x => x.app);
    }

    readonly property var resultRows: {
        const rows = [];
        if (root.isShellCmd && root.shellCmd.length > 0) {
            rows.push({ kind: "shell", primary: "Run: " + root.shellCmd, secondary: "shell command" });
        }
        if (root.isMath && root.mathResult.length > 0) {
            rows.push({ kind: "math", primary: root.mathResult, secondary: root.query });
        }
        const apps = root.filteredApps;
        for (let i = 0; i < apps.length; ++i) {
            rows.push({ kind: "app", app: apps[i], primary: apps[i].name, secondary: apps[i].genericName || "" });
        }
        return rows;
    }

    onResultRowsChanged: root.currentIndex = 0

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function activateSelected(): void {
        const list = root.resultRows;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const row = list[root.currentIndex];
        root.open = false;
        if (row.kind === "app") {
            row.app.execute();
        } else if (row.kind === "shell") {
            Quickshell.execDetached(["sh", "-c", root.shellCmd]);
        } else if (row.kind === "math") {
            copyProc.command = ["sh", "-c", `printf '%s' '${row.primary.substring(2)}' | wl-copy`];
            copyProc.running = true;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.resultRows.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    Process { id: copyProc }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        SearchOverlay {
            opened: root.open
            queryText: root.query
            onQueryEdited: text => root.query = text
            icon: root.isShellCmd ? "terminal" : (root.isMath ? "calculate" : "search")
            placeholder: "Type to search apps, > for shell, or math…"
            cardWidth: 600
            cardHeight: 520

            onEscaped: root.open = false
            onAccepted: root.activateSelected()
            onNavigate: key => {
                if (key === Qt.Key_Down || key === Qt.Key_Tab)
                    root.moveSelection(1);
                else if (key === Qt.Key_Up || key === Qt.Key_Backtab)
                    root.moveSelection(-1);
            }

            resultView: ListView {
                anchors.fill: parent
                clip: true
                keyNavigationEnabled: false
                currentIndex: root.currentIndex
                model: root.resultRows
                spacing: 2

                ScrollBar.vertical: StyledScrollBar {}

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: StyledRect {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 40
                    color: index === root.currentIndex ? Theme.surfaceContainerHighest : "transparent"
                    radius: Theme.radius.normal

                    StateLayer {
                        pressed: rowMa.pressed
                        focused: ListView.isCurrentItem
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.large
                        anchors.rightMargin: Theme.padding.large
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (modelData.kind === "shell") return "terminal";
                                if (modelData.kind === "math") return "calculate";
                                return "apps";
                            }
                            color: Theme.textDim
                            font.pixelSize: Theme.icon.size.small
                            width: 20
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.primary
                            color: Theme.text
                            font.pixelSize: Theme.font.size.normal
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.secondary
                            color: Theme.textDim
                            font.pixelSize: Theme.font.size.small
                            visible: text.length > 0
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.currentIndex = index
                        onClicked: {
                            root.currentIndex = index;
                            root.activateSelected();
                        }
                    }
                }
            }
        }
    }
}
