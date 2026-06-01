import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components
import qs.services

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
            id: win
            required property var modelData
            screen: modelData
            visible: root.open && HyprlandData.isFocusedScreen(modelData)

            property bool shown: false
            onVisibleChanged: {
                shown = visible;
                if (visible) {
                    field.text = "";
                    field.forceActiveFocus();
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
                width: 440
                implicitHeight: column.implicitHeight + Theme.padding.larger * 2
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                opacity: win.shown ? 1 : 0
                scale: win.shown ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }

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
                            font.pixelSize: Theme.icon.size.small
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
                        placeholderTextColor: Theme.textMuted
                        renderType: Text.NativeRendering
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.family.sans
                        background: Rectangle {
                            radius: Theme.radius.small
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: field.activeFocus ? Theme.primary : Theme.outline
                            Behavior on border.color { CAnim {} }
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
