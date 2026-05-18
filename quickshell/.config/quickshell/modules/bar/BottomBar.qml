// quickshell/.config/quickshell/modules/bar/BottomBar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: 28
    readonly property int edgeMargin: 6
    readonly property int hotZoneHeight: 12
    readonly property int panelHeight: pillHeight + edgeMargin + 2
    readonly property int visibleY: panelHeight - pillHeight - edgeMargin

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: hotZone
        property bool hovered: hotHover.hovered

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: panel.hotZoneHeight

        HoverHandler { id: hotHover }
    }

    Item {
        id: pillRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: panel.edgeMargin
        anchors.rightMargin: panel.edgeMargin
        height: panel.pillHeight
        y: panel.panelHeight

        LauncherPill {
            id: launcher
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacesPill {
            id: workspaces
            anchors.verticalCenter: parent.verticalCenter
            x: launcher.x + launcher.width + 8
        }

        MediaPill {
            id: media
            anchors.verticalCenter: parent.verticalCenter
            x: workspaces.x + workspaces.width + 8
        }

        ClockPill {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width / 2
        }

        TrayPill {
            id: tray
            anchors.verticalCenter: parent.verticalCenter
            x: status.x - width - 8
        }

        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: tray.visible ? (tray.x - width - 8) : (status.x - width - 8)
        }

        StatusPill {
            id: status
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: panel.panelHeight
        slideToY: panel.visibleY
        hotZoneItem: hotZone
        watchedItems: [launcher, workspaces, media, clock, claude, tray, status]
        dwellMs: 600
    }

    Connections {
        target: launcher
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: workspaces
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: media
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: clock
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: claude
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: tray
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: status
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }

    mask: Region {
        x: 0
        y: peek.fullyHidden ? panel.panelHeight - panel.hotZoneHeight : 0
        width: panel.width
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
