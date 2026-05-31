import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import qs.components

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0
    property var windows: []

    readonly property var filteredWindows: {
        const q = root.query.toLowerCase();
        if (q.length === 0)
            return root.windows;
        return root.windows.filter(w =>
            w.title.toLowerCase().includes(q) || w.cls.toLowerCase().includes(q));
    }

    onFilteredWindowsChanged: root.currentIndex = 0

    function toggle(): void {
        if (root.open) {
            root.open = false;
        } else {
            root.query = "";
            root.currentIndex = 0;
            listProc.running = true;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.filteredWindows.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function focusSelected(): void {
        const list = root.filteredWindows;
        if (root.currentIndex < 0 || root.currentIndex >= list.length)
            return;
        const w = list[root.currentIndex];
        root.open = false;
        focusProc.command = ["hyprctl", "dispatch", "focuswindow", `address:${w.address}`];
        focusProc.running = true;
    }

    Process {
        id: listProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed;
                try { parsed = JSON.parse(this.text); }
                catch (e) { parsed = []; }
                root.windows = parsed
                    .filter(c => c.mapped !== false)
                    .map(c => ({
                        address: c.address || "",
                        cls: c.class || "",
                        title: c.title || "",
                        workspace: (c.workspace && c.workspace.name) || ""
                    }));
                root.open = true;
            }
        }
    }

    Process { id: focusProc }

    IpcHandler {
        target: "windows"
        function toggle(): void { root.toggle(); }
    }

    Variants {
        model: Quickshell.screens

        SearchOverlay {
            opened: root.open
            queryText: root.query
            onQueryEdited: text => root.query = text
            icon: "tab"
            placeholder: "Search windows…"
            cardWidth: 680
            cardHeight: 440

            onEscaped: root.open = false
            onAccepted: root.focusSelected()
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
                model: root.filteredWindows
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

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `[${modelData.workspace}]`
                            color: Theme.textMuted
                            font.pixelSize: Theme.font.size.small
                            width: 56
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.cls
                            color: Theme.textVariant
                            font.pixelSize: Theme.font.size.normal
                            width: 160
                            elide: Text.ElideRight
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            color: Theme.text
                            font.pixelSize: Theme.font.size.normal
                            width: parent.width - 56 - 160 - parent.spacing * 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.currentIndex = index
                        onClicked: {
                            root.currentIndex = index;
                            root.focusSelected();
                        }
                    }
                }
            }
        }
    }
}
