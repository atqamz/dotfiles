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
    property var entries: []

    readonly property var filteredEntries: {
        const q = root.query.toLowerCase();
        if (q.length === 0)
            return root.entries;
        return root.entries.filter(e => e.preview.toLowerCase().includes(q));
    }

    onFilteredEntriesChanged: root.currentIndex = 0

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
        if (root.currentIndex < 0 || root.currentIndex >= list.length)
            return;
        const entry = list[root.currentIndex];
        root.open = false;
        copyProc.command = ["sh", "-c", `cliphist decode ${entry.id} | wl-copy`];
        copyProc.running = true;
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
                    if (tabIdx < 0) return { id: line, preview: line };
                    return {
                        id: line.substring(0, tabIdx),
                        preview: line.substring(tabIdx + 1)
                    };
                });
                root.open = true;
            }
        }
    }

    Process { id: copyProc }
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
                width: 680
                height: 520
                color: Theme.surface
                border.color: Theme.outline
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
                            text: "content_paste"
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search clipboard…"
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
                                    root.pasteSelected();
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
                        model: root.filteredEntries
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 32
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

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
                                    width: 44
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.preview
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                    width: parent.width - 44 - parent.spacing
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                                onClicked: {
                                    root.currentIndex = index;
                                    root.pasteSelected();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
