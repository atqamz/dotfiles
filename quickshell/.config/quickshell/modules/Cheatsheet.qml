// quickshell/.config/quickshell/modules/Cheatsheet.qml
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

    readonly property var filteredCategories: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return HyprlandKeybinds.categories;
        const out = [];
        for (let i = 0; i < HyprlandKeybinds.categories.length; ++i) {
            const cat = HyprlandKeybinds.categories[i];
            const binds = cat.binds.filter(b =>
                b.key.toLowerCase().includes(q)
                || b.mods.toLowerCase().includes(q)
                || b.action.toLowerCase().includes(q));
            if (binds.length > 0) out.push({ name: cat.name, binds: binds });
        }
        return out;
    }

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            HyprlandKeybinds.reload();
        }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; HyprlandKeybinds.reload(); }
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
                width: 640
                height: 480
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
                            text: "keyboard"
                            color: Theme.textVariant
                            font.pixelSize: 22
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: "Keybinds"
                            color: Theme.text
                            font.pixelSize: Theme.font.size.larger
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        TextField {
                            id: searchField
                            Layout.preferredWidth: 240
                            placeholderText: "Filter…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.normal
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
                            spacing: Theme.spacing.large

                            Repeater {
                                model: root.filteredCategories

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
                                    Repeater {
                                        model: modelData.binds

                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: Theme.spacing.normal

                                            StyledRect {
                                                Layout.preferredWidth: 180
                                                implicitHeight: 24
                                                color: Theme.surfaceContainer
                                                border.color: Theme.outlineVariant
                                                border.width: 1
                                                radius: Theme.radius.small

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: modelData.mods.length > 0
                                                          ? (modelData.mods + " + " + modelData.key)
                                                          : modelData.key
                                                    color: Theme.text
                                                    font.pixelSize: Theme.font.size.small
                                                    font.family: Theme.font.family.mono
                                                }
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.action
                                                color: Theme.textVariant
                                                font.pixelSize: Theme.font.size.small
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                visible: root.filteredCategories.length === 0
                                StyledText {
                                    anchors.centerIn: parent
                                    text: HyprlandKeybinds.categories.length === 0
                                          ? "No keybinds parsed (add # Section: headers to hyprland.conf)"
                                          : "No matches"
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.font.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
