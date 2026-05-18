// quickshell/.config/quickshell/modules/Launcher.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components

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
        const q = root.query.toLowerCase();
        const all = DesktopEntries.applications.values;
        const filtered = all.filter(app => {
            if (app.noDisplay) return false;
            if (q.length === 0) return true;
            return app.name.toLowerCase().includes(q)
                || (app.genericName || "").toLowerCase().includes(q)
                || (app.comment || "").toLowerCase().includes(q);
        });
        filtered.sort((a, b) => a.name.localeCompare(b.name));
        return filtered.slice(0, 8);
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

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 600
                height: 520
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isShellCmd ? "terminal" : (root.isMath ? "calculate" : "search")
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Type to search apps, > for shell, or math…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activateSelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.resultRows
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 40
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

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
                                    font.pixelSize: 18
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
    }
}
