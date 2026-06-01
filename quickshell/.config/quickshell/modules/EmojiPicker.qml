// quickshell/.config/quickshell/modules/EmojiPicker.qml
import Quickshell
import Quickshell.Io
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
    readonly property int gridCols: 9

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

        SearchOverlay {
            // `active` already defaults to focused-monitor only (SearchOverlay).
            opened: root.open
            queryText: root.query
            onQueryEdited: text => {
                root.query = text;
                root.currentIndex = 0;
            }
            icon: "search"
            placeholder: "Search emoji…"
            cardWidth: 600
            cardHeight: 560

            onEscaped: root.open = false
            onAccepted: root.copyCurrent()
            onNavigate: key => {
                if (key === Qt.Key_Right)
                    root.moveSelection(1);
                else if (key === Qt.Key_Left)
                    root.moveSelection(-1);
                else if (key === Qt.Key_Down)
                    root.moveSelection(root.gridCols);
                else if (key === Qt.Key_Up)
                    root.moveSelection(-root.gridCols);
            }

            resultView: ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacing.large

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    property int cols: root.gridCols
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
