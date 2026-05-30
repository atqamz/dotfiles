// quickshell/.config/quickshell/modules/Clipboard.qml
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
        if (q.length === 0) return root.entries;
        return root.entries.filter(e => e.preview.toLowerCase().includes(q));
    }

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

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.open

            // Recipe D: drive enter animation off `shown`; the visible property
            // is already final when the window appears, so a plain Behavior on
            // it won't animate. Exit is instant (window hides) — exit animation
            // out of scope (re-skin).
            property bool shown: false
            onVisibleChanged: {
                shown = visible;
                if (visible) searchField.forceActiveFocus();
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.shown ? 1 : 0
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }
            }

            StyledRect {
                id: card
                anchors.centerIn: parent
                width: 680
                height: 520
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                opacity: win.shown ? 1 : 0
                scale: win.shown ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }

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
                            font.pixelSize: Theme.font.size.extraLarge
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
                                radius: Theme.radius.small
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: searchField.activeFocus ? Theme.primary : Theme.outline
                                Behavior on border.color { CAnim {} }
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
                                } else if (event.key === Qt.Key_Delete) {
                                    const list = root.filteredEntries;
                                    if (root.currentIndex >= 0 && root.currentIndex < list.length) {
                                        root.deleteEntry(list[root.currentIndex].id);
                                    }
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
                                    width: parent.width - 44 - 22 - parent.spacing * 3
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
    }
}
