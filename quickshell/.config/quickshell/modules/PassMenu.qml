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
            id: win
            required property var modelData
            screen: modelData
            visible: root.open

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
                width: 560
                height: 460
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
                            text: "key"
                            color: Theme.textVariant
                            font.pixelSize: Theme.font.size.extraLarge
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search pass entries…"
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
                                    root.copySelected();
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
    }
}
