// quickshell/.config/quickshell/modules/EmojiPicker.qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services
import "../components/Fuzzy.js" as Fuzzy

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property var allFiltered: {
        const q = root.query;
        if (q.length === 0) return Emojis.allEmojis;
        // Typing the emoji glyph itself pins an exact match to the top; otherwise
        // fuzzy-match the CLDR name (underscores read as word boundaries).
        const all = Emojis.allEmojis;
        const scored = [];
        for (let i = 0; i < all.length; ++i) {
            const e = all[i];
            if (e.ch === q) { scored.push({ e, s: Infinity, i }); continue; }
            const s = Fuzzy.score(q, e.name);
            if (s !== null) scored.push({ e, s, i });
        }
        scored.sort((a, b) => (b.s - a.s) || (a.i - b.i));
        return scored.map(x => x.e);
    }

    // Single flat list backing both the grid render and keyboard navigation, so
    // currentIndex always maps to a visible cell. In browse mode recents are
    // prepended, so arrow keys reach them too.
    readonly property var displayList: {
        if (root.query.length > 0) return root.allFiltered;
        const rec = Emojis.recents.map(c => ({ ch: c, name: "recent" }));
        return rec.concat(Emojis.allEmojis);
    }

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.displayList.length;
        if (len === 0) return;
        let n = root.currentIndex + delta;
        if (n < 0) n = 0;
        if (n >= len) n = len - 1;
        root.currentIndex = n;
    }

    function copyEntry(ch: string): void {
        if (!ch) return;
        root.open = false;
        Emojis.bumpRecent(ch);
        // Fresh process per copy — avoids the Process.running re-trigger race.
        // $1 carries the emoji so there are no shell quoting/injection issues.
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "emoji", ch]);
    }

    function copyCurrent(): void {
        const l = root.displayList;
        if (root.currentIndex >= 0 && root.currentIndex < l.length)
            root.copyEntry(l[root.currentIndex].ch);
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void { root.toggle(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            // Only on the focused monitor — avoids duplicate cards on other
            // screens and the keyboard-focus split between them.
            visible: root.open && (!Hyprland.focusedMonitor || modelData.name === Hyprland.focusedMonitor.name)

            property bool shown: false
            onVisibleChanged: {
                shown = visible;
                if (visible) {
                    searchField.text = "";
                    searchField.forceActiveFocus();
                }
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
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }
            }

            StyledRect {
                id: card
                anchors.centerIn: parent
                width: 600
                height: 560
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                opacity: win.shown ? 1 : 0
                scale: win.shown ? 1 : 0.96
                transformOrigin: Item.Center
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    Row {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            color: Theme.textVariant
                            font.pixelSize: Theme.font.size.extraLarge
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search emoji…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            renderType: Text.NativeRendering
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            onTextChanged: {
                                root.query = text;
                                root.currentIndex = 0;
                            }
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
                                } else if (event.key === Qt.Key_Right) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(grid.cols);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-grid.cols);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.copyCurrent();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    GridView {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        property int cols: 9
                        cellWidth: Math.floor(width / cols)
                        cellHeight: 50

                        model: root.displayList
                        currentIndex: root.currentIndex
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: Theme.anim.durations.small
                        highlight: Rectangle {
                            radius: Theme.radius.small
                            color: Theme.surfaceContainerHighest
                            border.width: 1
                            border.color: Theme.outline
                        }

                        ScrollBar.vertical: StyledScrollBar {}

                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: grid.cellWidth
                            height: grid.cellHeight

                            Text {
                                anchors.centerIn: parent
                                text: modelData.ch
                                font.pixelSize: 26
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.currentIndex = index
                                onClicked: root.copyEntry(modelData.ch)
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.displayList.length > 0
                        text: "↑ ↓ ← →  navigate      ↵  copy      esc  close"
                        color: Theme.textMuted
                        font.pixelSize: Theme.font.size.smaller
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.displayList.length === 0
                        text: "No emoji found"
                        color: Theme.textMuted
                        font.pixelSize: Theme.font.size.normal
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
