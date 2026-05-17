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
                width: 600
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
                            text: "search"
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search applications…"
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
                                    root.launchSelected();
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
                        model: root.filteredApps
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

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "apps"
                                    color: Theme.textDim
                                    font.pixelSize: 18
                                    width: 20
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.genericName || ""
                                    color: Theme.textDim
                                    font.pixelSize: Theme.font.size.small
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
