// quickshell/.config/quickshell/modules/Power.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components

Scope {
    id: root

    property bool open: false
    property int currentIndex: 0
    property int confirmingIndex: -1     // index of card awaiting confirmation, or -1

    readonly property var actions: [
        { label: "Lock",     icon: "lock",              cmd: ["hyprlock"],                 confirm: false },
        { label: "Logout",   icon: "logout",            cmd: ["hyprctl", "dispatch", "exit"], confirm: false },
        { label: "Suspend",  icon: "bedtime",           cmd: ["systemctl", "suspend"],     confirm: false },
        { label: "Reboot",   icon: "refresh",           cmd: ["systemctl", "reboot"],      confirm: true },
        { label: "Shutdown", icon: "power_settings_new", cmd: ["systemctl", "poweroff"],   confirm: true }
    ]

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.currentIndex = 0;
            root.confirmingIndex = -1;
        }
    }

    function activate(index: int): void {
        if (index < 0 || index >= root.actions.length) return;
        const a = root.actions[index];
        if (a.confirm && root.confirmingIndex !== index) {
            root.confirmingIndex = index;
            return;
        }
        root.open = false;
        root.confirmingIndex = -1;
        Quickshell.execDetached(a.cmd);
    }

    function moveSelection(delta: int): void {
        const len = root.actions.length;
        root.currentIndex = (root.currentIndex + delta + len) % len;
        root.confirmingIndex = -1;
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; root.currentIndex = 0; root.confirmingIndex = -1; }
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

            MouseArea {
                anchors.fill: parent
                focus: true
                onClicked: root.open = false
                Keys.onEscapePressed: root.open = false
                Keys.onLeftPressed: root.moveSelection(-1)
                Keys.onRightPressed: root.moveSelection(1)
                Keys.onReturnPressed: root.activate(root.currentIndex)
                Keys.onEnterPressed: root.activate(root.currentIndex)
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: buttonRow.implicitWidth + Theme.padding.larger * 2
                implicitHeight: buttonRow.implicitHeight + Theme.padding.larger * 2
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: buttonRow
                    anchors.centerIn: parent
                    spacing: Theme.spacing.extraLarge

                    Repeater {
                        model: root.actions

                        StyledRect {
                            id: card
                            required property var modelData
                            required property int index
                            property bool hovered: cardHover.hovered
                            property bool selected: index === root.currentIndex
                            property bool confirming: index === root.confirmingIndex

                            implicitWidth: 160
                            implicitHeight: 160
                            color: card.confirming ? Theme.warning :
                                   (card.hovered || card.selected ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                            border.color: card.confirming ? Theme.warning :
                                          (card.hovered || card.selected ? Theme.primary : Theme.outlineVariant)
                            border.width: 1
                            radius: Theme.radius.large
                            scale: card.hovered || card.selected ? 1.04 : 1.0

                            Behavior on scale { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.small } }
                            Behavior on color { CAnim { duration: Theme.anim.durations.small } }
                            Behavior on border.color { CAnim { duration: Theme.anim.durations.small } }

                            HoverHandler { id: cardHover }

                            StateLayer { id: layer; radius: parent.radius; pressed: cardTap.pressed }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacing.normal

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: card.confirming ? "warning" : card.modelData.icon
                                    color: card.confirming ? Theme.textOnPrimary :
                                           (card.hovered || card.selected ? Theme.primary : Theme.text)
                                    font.pixelSize: 48 // hero glyph, no rung
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: card.confirming ? "Confirm?" : card.modelData.label
                                    color: card.confirming ? Theme.textOnPrimary : Theme.text
                                    font.pixelSize: Theme.font.size.large
                                    font.bold: card.confirming
                                }
                            }

                            MouseArea {
                                id: cardTap
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = card.index
                                onClicked: root.activate(card.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
