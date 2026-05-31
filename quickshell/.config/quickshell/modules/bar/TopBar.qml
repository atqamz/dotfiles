// quickshell/.config/quickshell/modules/bar/TopBar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: Config.options.bar.height
    readonly property int edgeMargin: 0
    readonly property int topMargin: 4
    readonly property int hotZoneHeight: 12
    // Dock the islands flush to the bottom/side edges with a small top float:
    // pillRow sits at y = topMargin and its bottom lands on the screen bottom.
    readonly property int panelHeight: pillHeight + topMargin

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    // Reserve the bar's strip only while it is revealed; when fully hidden the
    // zone collapses to 0 so tiled windows reclaim the bottom edge and the bar
    // peeks back over them on hover.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: peek.fullyHidden ? 0 : panel.panelHeight
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

        // Whole-bar hover region (end-4 model): a parent MouseArea keeps the
        // bar revealed while the pointer is anywhere over it, including the
        // gaps between groups. It accepts no buttons, so clicks fall through to
        // the child groups.
        MouseArea {
            id: hoverRegion
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            property bool hovered: containsMouse

            // LEFT: launcher + workspace numbers + focused-window title
            BarGroup {
                id: leftGroup
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                LauncherPill {
                    chrome: false
                    visible: Config.options.bar.showLauncher
                    anchors.verticalCenter: parent.verticalCenter
                }
                Workspaces {
                    id: workspaces
                    visible: Config.options.bar.showWorkspaces
                    anchors.verticalCenter: parent.verticalCenter
                }
                ActiveWindow {
                    id: activeWindow
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // CENTER: clock only
            BarGroup {
                id: centerGroup
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.options.bar.showClock

                ClockPill {
                    chrome: false
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // RIGHT: usage + media + tray + status
            BarGroup {
                id: rightGroup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                ResourcesPill {
                    chrome: false
                    visible: Config.options.bar.showResources
                    anchors.verticalCenter: parent.verticalCenter
                }
                MediaPill {
                    chrome: false
                    visible: Config.options.bar.showMedia && MprisService.hasPlayer
                    anchors.verticalCenter: parent.verticalCenter
                }
                TrayPill {
                    chrome: false
                    visible: Config.options.bar.showTray && TrayService.count > 0
                    anchors.verticalCenter: parent.verticalCenter
                }
                StatusPill {
                    chrome: false
                    visible: Config.options.bar.showStatus
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: panel.panelHeight
        slideToY: panel.topMargin
        hotZoneItem: hotZone
        watchedItems: [hoverRegion]
        dwellMs: 600
    }

    Connections {
        target: hoverRegion
        function onContainsMouseChanged() { peek.notifyWatchedHoverChanged(); }
    }

    mask: Region {
        x: 0
        width: panel.width
        y: peek.fullyHidden ? panel.panelHeight - panel.hotZoneHeight : 0
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
