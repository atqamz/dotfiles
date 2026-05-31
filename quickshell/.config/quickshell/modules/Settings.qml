import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import "settings"

Scope {
    id: root
    property bool open: false
    function toggle(): void { open = !open; }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open; }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.open
            property bool shown: false
            onVisibleChanged: shown = visible
            onShownChanged: if (shown) content.forceActiveFocus()

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: panel.shown ? 1 : 0
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
                MouseArea { anchors.fill: parent; onClicked: root.open = false }
            }

            SettingsContent {
                id: content
                focus: true
                Keys.onEscapePressed: root.open = false
                anchors.centerIn: parent
                opacity: panel.shown ? 1 : 0
                scale: panel.shown ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }
                onRequestClose: root.open = false
            }
        }
    }
}
