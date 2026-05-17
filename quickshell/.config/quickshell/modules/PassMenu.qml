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
    property var entries: []
    property string storeDir: Quickshell.env("PASSWORD_STORE_DIR") || (Quickshell.env("HOME") + "/.password-store")

    readonly property var filteredEntries: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return root.entries;
        return root.entries.filter(e => e.toLowerCase().includes(q));
    }

    onFilteredEntriesChanged: root.currentIndex = 0

    function toggle(): void {
        if (root.open) {
            root.open = false;
        } else {
            root.query = "";
            root.currentIndex = 0;
            listProc.command = ["sh", "-c",
                `cd "${root.storeDir}" 2>/dev/null && find . -type f -name '*.gpg' -printf '%P\n' | sed 's/\\.gpg$//' | LC_ALL=C sort`];
            listProc.running = true;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.filteredEntries.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function copySelected(): void {
        const list = root.filteredEntries;
        if (root.currentIndex < 0 || root.currentIndex >= list.length)
            return;
        const name = list[root.currentIndex];
        root.open = false;
        copyProc.command = ["pass", "show", "-c", name];
        copyProc.running = true;
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = this.text.split("\n").filter(l => l.length > 0);
                root.open = true;
            }
        }
    }

    Process { id: copyProc }

    IpcHandler {
        target: "pass"
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
                width: 540
                height: 440
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
                        placeholderText: "Search pass entries..."
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
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.copySelected();
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
                        model: root.filteredEntries

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 30
                            color: index === root.currentIndex ? "#1f1f1f" : "transparent"
                            radius: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                text: modelData
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                                onClicked: {
                                    root.currentIndex = index;
                                    root.copySelected();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
