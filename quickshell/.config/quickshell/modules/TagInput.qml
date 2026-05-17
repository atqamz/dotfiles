import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components

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

            color: Theme.scrim
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

            StyledRect {
                anchors.centerIn: parent
                width: 440
                implicitHeight: column.implicitHeight + Theme.padding.larger * 2
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Column {
                    id: column
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.normal

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "label"
                            color: Theme.textVariant
                            font.pixelSize: 18
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "tag window  (prefix - to remove)"
                            color: Theme.textMuted
                            font.pixelSize: Theme.font.size.small
                        }
                    }

                    TextField {
                        id: field
                        width: parent.width
                        placeholderText: "tag name"
                        color: Theme.text
                        placeholderTextColor: Theme.textDim
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.family.sans
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
