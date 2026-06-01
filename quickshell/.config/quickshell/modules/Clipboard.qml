// quickshell/.config/quickshell/modules/Clipboard.qml
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

    readonly property var filteredEntries: Fuzzy.rank(root.query, root.entries, e => e.preview)

    onFilteredEntriesChanged: root.currentIndex = 0

    function detectKind(preview: string): string {
        if (/^\[\[\s*binary data.*image/i.test(preview)) return "image";
        if (/^https?:\/\//.test(preview.trim())) return "link";
        return "text";
    }

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
        const len = root.filteredEntries.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function pasteSelected(): void {
        const list = root.filteredEntries;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const entry = list[root.currentIndex];
        root.open = false;
        copyProc.command = ["sh", "-c", `cliphist decode ${entry.id} | wl-copy`];
        copyProc.running = true;
    }

    function deleteEntry(id: string): void {
        deleteProc.command = ["sh", "-c", `echo '${id}' | cliphist delete`];
        deleteProc.running = true;
    }

    function clearAll(): void {
        root.open = false;
        wipeProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.length > 0);
                root.entries = lines.map(line => {
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx < 0) return { id: line, preview: line, kind: "text" };
                    const id = line.substring(0, tabIdx);
                    const preview = line.substring(tabIdx + 1);
                    return { id: id, preview: preview, kind: root.detectKind(preview) };
                });
                root.open = true;
            }
        }
    }

    Process { id: copyProc }
    Process {
        id: deleteProc
        onExited: listProc.running = true
    }
    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle(); }
        function clear(): void { root.clearAll(); }
    }

    Variants {
        model: Quickshell.screens

        SearchOverlay {
            opened: root.open
            queryText: root.query
            onQueryEdited: text => root.query = text
            icon: "content_paste"
            placeholder: "Search clipboard…"
            cardWidth: 680
            cardHeight: 520
            captureDelete: true

            onEscaped: root.open = false
            onAccepted: root.pasteSelected()
            onNavigate: key => {
                if (key === Qt.Key_Down || key === Qt.Key_Tab) {
                    root.moveSelection(1);
                } else if (key === Qt.Key_Up || key === Qt.Key_Backtab) {
                    root.moveSelection(-1);
                } else if (key === Qt.Key_Delete) {
                    const list = root.filteredEntries;
                    if (root.currentIndex >= 0 && root.currentIndex < list.length)
                        root.deleteEntry(list[root.currentIndex].id);
                }
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
                    height: 48
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
                            text: modelData.id
                            color: Theme.textDim
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family.mono
                            width: 44
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (modelData.kind === "image") return "image";
                                if (modelData.kind === "link") return "link";
                                return "subject";
                            }
                            color: Theme.textDim
                            font.pixelSize: Theme.icon.size.small
                            width: 22
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.kind === "image" ? "[image]" : modelData.preview
                            color: Theme.text
                            font.pixelSize: Theme.font.size.normal
                            width: parent.width - 44 - 22 - parent.spacing * 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: root.currentIndex = index
                        onClicked: function(mouse) {
                            root.currentIndex = index;
                            if (mouse.button === Qt.RightButton) {
                                root.deleteEntry(modelData.id);
                            } else {
                                root.pasteSelected();
                            }
                        }
                    }
                }
            }
        }
    }
}
