// quickshell/.config/quickshell/modules/bar/TopBar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: 28
    readonly property int edgeMargin: 6      // gap between pill and screen edge
    readonly property int hotZoneHeight: 4
    readonly property int panelHeight: pillHeight + edgeMargin + 2   // 36

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Hot-zone: thin invisible strip at the very top of the panel. Hover
    // here triggers the peek FSM to slide pills in.
    Item {
        id: hotZone
        property bool hovered: hotHover.hovered

        anchors.top: parent.top
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
        y: -panel.pillHeight       // start collapsed (offscreen, above panel top)

        LauncherPill {
            id: launcher
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacesPill {
            id: workspaces
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width - 4
        }

        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 + 4
        }

        ClockPill {
            id: clock
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: -panel.pillHeight
        slideToY: panel.edgeMargin
        hotZoneItem: hotZone
        watchedItems: [launcher, workspaces, claude, clock]
        dwellMs: 150
    }

    // Wire pill hover changes back into peek FSM.
    Connections {
        target: launcher
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: workspaces
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: claude
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: clock
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }

    // Input mask: collapsed = top hot-zone strip; otherwise = full panel
    // (acceptable cost — user is actively hovering during this state).
    mask: Region {
        x: 0
        y: 0
        width: panel.width
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
