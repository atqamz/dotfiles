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
        y: peek.slideFromY

        RowLayout {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            LauncherPill   { id: launcher;   visible: Config.options.bar.showLauncher;   Layout.alignment: Qt.AlignVCenter }
            WorkspacesPill { id: workspaces; visible: Config.options.bar.showWorkspaces; Layout.alignment: Qt.AlignVCenter }
            MediaPill      { id: media;      visible: Config.options.bar.showMedia && MprisService.hasPlayer; Layout.alignment: Qt.AlignVCenter }
        }

        ClockPill {
            id: clock
            visible: Config.options.bar.showClock
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width / 2
        }

        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            ResourcesPill { id: resources; visible: Config.options.bar.showResources; Layout.alignment: Qt.AlignVCenter }
            TrayPill      { id: tray;      visible: Config.options.bar.showTray && TrayService.count > 0; Layout.alignment: Qt.AlignVCenter }
            StatusPill    { id: status;    visible: Config.options.bar.showStatus;    Layout.alignment: Qt.AlignVCenter }
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
