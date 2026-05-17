import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    function submit(tag: string): void {
        const t = tag.trim();
        root.open = false;
        if (t.length === 0) return;
        tagProc.command = ["hyprctl", "dispatch", "tagwindow", t];
        tagProc.running = true;
    }

    Process { id: tagProc }

    IpcHandler {
        target: "tag"
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

            onVisibleChanged: {
                if (visible) {
                    field.text = "";
                    field.forceActiveFocus();
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 420
                implicitHeight: column.implicitHeight + 24
                color: "#0a0a0a"
                border.color: "#3a3a3a"
                border.width: 1
                radius: 6

                MouseArea { anchors.fill: parent }

                Column {
                    id: column
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "tag window  (prefix - to remove)"
                        color: "#888888"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                    }

                    TextField {
                        id: field
                        width: parent.width
                        placeholderText: "tag name"
                        color: "#ffffff"
                        placeholderTextColor: "#666666"
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
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
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.submit(field.text);
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
