// quickshell/.config/quickshell/modules/bar/TopBar.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: Config.options.bar.height
    readonly property int edgeMargin: 6
    readonly property int hotZoneHeight: 12
    readonly property int panelHeight: pillHeight + edgeMargin + 2

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    // Reserve the bar's strip so tiled windows never sit underneath it; the
    // peek bar slides within this always-present bottom gap.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: panel.panelHeight
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
        y: peek.slideFromY

        // One cohesive island centered at the bottom edge. Pills are grouped
        // by purpose (navigation / now-playing + time / system) with a wider
        // gap between groups than within them, so the cluster reads as
        // intentional instead of three things stranded across an empty bar.
        Row {
            id: island
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                LauncherPill   { id: launcher;   visible: Config.options.bar.showLauncher;   anchors.verticalCenter: parent.verticalCenter }
                WorkspacesPill { id: workspaces; visible: Config.options.bar.showWorkspaces; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                MediaPill { id: media; visible: Config.options.bar.showMedia && MprisService.hasPlayer; anchors.verticalCenter: parent.verticalCenter }
                ClockPill { id: clock; visible: Config.options.bar.showClock;                            anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                ResourcesPill { id: resources; visible: Config.options.bar.showResources;                 anchors.verticalCenter: parent.verticalCenter }
                TrayPill      { id: tray;      visible: Config.options.bar.showTray && TrayService.count > 0; anchors.verticalCenter: parent.verticalCenter }
                StatusPill    { id: status;    visible: Config.options.bar.showStatus;                    anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: panel.panelHeight
        slideToY: 2
        hotZoneItem: hotZone
        watchedItems: [launcher, workspaces, media, clock, resources, tray, status]
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
        target: resources
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
        width: panel.width
        y: peek.fullyHidden ? panel.panelHeight - panel.hotZoneHeight : 0
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
