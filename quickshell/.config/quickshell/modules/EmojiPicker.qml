// quickshell/.config/quickshell/modules/EmojiPicker.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property var allFiltered: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return Emojis.allEmojis;
        return Emojis.allEmojis.filter(e => e.name.includes(q) || e.ch === q);
    }

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.allFiltered.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function copySelected(): void {
        const list = root.allFiltered;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const e = list[root.currentIndex];
        root.open = false;
        Emojis.bumpRecent(e.ch);
        copyProc.command = ["sh", "-c", `printf '%s' '${e.ch}' | wl-copy`];
        copyProc.running = true;
    }

    Process { id: copyProc }

    IpcHandler {
        target: "emoji"
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
                width: 560
                height: 520
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: "mood"
                            color: Theme.textVariant
                            font.pixelSize: 22
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search emoji…"
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
                                } else if (event.key === Qt.Key_Right) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(12);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-12);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.copySelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout {
                            width: searchField.parent.parent.width - Theme.padding.larger * 2
                            spacing: Theme.spacing.normal

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.small
                                visible: root.query.length === 0 && Emojis.recents.length > 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: "RECENT"
                                    color: Theme.textVariant
                                    font.pixelSize: Theme.font.size.small
                                    font.bold: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 12
                                    columnSpacing: 4
                                    rowSpacing: 4

                                    Repeater {
                                        model: Emojis.recents

                                        StyledRect {
                                            required property string modelData
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            color: recHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                                            radius: Theme.radius.small

                                            HoverHandler { id: recHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                font.pixelSize: 22
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    root.open = false;
                                                    Emojis.bumpRecent(parent.modelData);
                                                    copyProc.command = ["sh", "-c", `printf '%s' '${parent.modelData}' | wl-copy`];
                                                    copyProc.running = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.query.length === 0 ? Emojis.categories : [{ name: "Results", items: root.allFiltered }]

                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing.small

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name.toUpperCase()
                                        color: Theme.textVariant
                                        font.pixelSize: Theme.font.size.small
                                        font.bold: true
                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 12
                                        columnSpacing: 4
                                        rowSpacing: 4

                                        Repeater {
                                            model: modelData.items

                                            StyledRect {
                                                required property var modelData
                                                Layout.preferredWidth: 36
                                                Layout.preferredHeight: 36
                                                color: gridHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                                                radius: Theme.radius.small

                                                HoverHandler { id: gridHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: parent.modelData.ch
                                                    font.pixelSize: 22
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        root.open = false;
                                                        Emojis.bumpRecent(parent.modelData.ch);
                                                        copyProc.command = ["sh", "-c", `printf '%s' '${parent.modelData.ch}' | wl-copy`];
                                                        copyProc.running = true;
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
            }
        }
    }
}
