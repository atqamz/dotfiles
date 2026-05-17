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

    readonly property var filteredApps: {
        const q = root.query.toLowerCase();
        const all = DesktopEntries.applications.values;
        const filtered = all.filter(app => {
            if (app.noDisplay)
                return false;
            if (q.length === 0)
                return true;
            return app.name.toLowerCase().includes(q)
                || (app.genericName || "").toLowerCase().includes(q)
                || (app.comment || "").toLowerCase().includes(q);
        });
        filtered.sort((a, b) => a.name.localeCompare(b.name));
        return filtered;
    }

    onFilteredAppsChanged: root.currentIndex = 0

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function launchSelected(): void {
        const list = root.filteredApps;
        if (root.currentIndex < 0 || root.currentIndex >= list.length)
            return;
        const app = list[root.currentIndex];
        root.open = false;
        app.execute();
    }

    function moveSelection(delta: int): void {
        const len = root.filteredApps.length;
        if (len === 0)
            return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
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
                height: 480
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
                        placeholderText: "Search applications..."
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
                                root.launchSelected();
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
                        model: root.filteredApps

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
                                    text: modelData.name
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.family: "JetBrains Mono"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.genericName || ""
                                    color: "#666666"
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    visible: text.length > 0
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                                onClicked: {
                                    root.currentIndex = index;
                                    root.launchSelected();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
