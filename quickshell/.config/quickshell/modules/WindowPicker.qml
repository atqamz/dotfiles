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
                height: 440
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
                            text: "tab"
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search windows…"
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
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.filteredWindows
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 40
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

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
