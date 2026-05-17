import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

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

            color: "#cc000000"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 640
                height: 420
                color: "#0a0a0a"
                border.color: "#3a3a3a"
                border.width: 1
                radius: 6

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    TextField {
                        id: searchField
                        width: parent.width
                        placeholderText: "Search windows..."
                        color: "#ffffff"
                        placeholderTextColor: "#888888"
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                        text: root.query
                        onTextChanged: if (text !== root.query) root.query = text
                        background: Rectangle {
                            color: "#1a1a1a"
                            border.color: "#3a3a3a"
                            border.width: 1
                            radius: 4
                        }
                        padding: 8

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.open = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.focusSelected();
                                event.accepted = true;
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.filteredWindows

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 36
                            color: index === root.currentIndex ? "#1f1f1f" : "transparent"
                            radius: 3

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: `[${modelData.workspace}]`
                                    color: "#888888"
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    width: 56
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.cls
                                    color: "#cccccc"
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    width: 140
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    width: parent.width - 220
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
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
    }
}
