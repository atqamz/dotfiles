import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.modules.bar as BarModules
import "dock"

Scope {
    id: root

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: Config.options.dock.enable

            readonly property int dockHeight: Config.options.dock.height
            readonly property int edgeMargin: Theme.elevation.margin
            readonly property int hotZoneHeight: 12
            readonly property int panelHeight: dockHeight + edgeMargin + 2

            anchors { bottom: true; left: true; right: true }
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
                id: dockSlide
                anchors.horizontalCenter: parent.horizontalCenter
                width: card.width
                height: panel.dockHeight
                y: peek.slideFromY                 // start hidden (below)

                StyledRect {
                    id: card
                    anchors.centerIn: parent
                    implicitWidth: apps.implicitWidth + 2 * Theme.padding.large
                    implicitHeight: panel.dockHeight
                    Behavior on implicitWidth { Anim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
                    color: Theme.surfaceContainer
                    border.color: Theme.outlineVariant
                    border.width: 1
                    radius: Theme.radius.large

                    property bool hovered: cardHover.hovered
                    HoverHandler { id: cardHover }

                    DockApps { id: apps; anchors.centerIn: parent }
                }
            }

            BarModules.PeekState {
                id: peek
                slideTarget: dockSlide
                slideFromY: panel.panelHeight                                   // hidden (below)
                slideToY: panel.panelHeight - panel.dockHeight - panel.edgeMargin  // visible
                hotZoneItem: hotZone
                watchedItems: [card]                  // keep open while hovering the card
                dwellMs: 600
                pinned: !Config.options.dock.autoHide
            }
            Connections {
                target: card
                function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
            }

            mask: Region {
                x: 0
                width: panel.width
                y: peek.fullyHidden ? panel.panelHeight - panel.hotZoneHeight : 0
                height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
            }
        }
    }
}
