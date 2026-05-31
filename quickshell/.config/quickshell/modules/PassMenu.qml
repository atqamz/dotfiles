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
    property var entries: []
    property string storeDir: Quickshell.env("PASSWORD_STORE_DIR") || (Quickshell.env("HOME") + "/.password-store")

    readonly property var filteredEntries: Fuzzy.rank(root.query, root.entries)

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

        SearchOverlay {
            opened: root.open
            queryText: root.query
            onQueryEdited: text => root.query = text
            icon: "vpn_key"
            placeholder: "Search pass entries…"
            cardWidth: 560
            cardHeight: 460

            onEscaped: root.open = false
            onAccepted: root.copySelected()
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
                model: root.filteredEntries
                spacing: 2

                ScrollBar.vertical: StyledScrollBar {}

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: StyledRect {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 32
                    color: index === root.currentIndex ? Theme.surfaceContainerHighest : "transparent"
                    radius: Theme.radius.normal

                    StateLayer {
                        pressed: rowMa.pressed
                        focused: ListView.isCurrentItem
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.padding.large
                        text: modelData
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal
                    }

                    MouseArea {
                        id: rowMa
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
