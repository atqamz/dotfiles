import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.services

Item {
    id: root
    required property var screen
    property bool overviewOpen: false
    property int draggingTargetWorkspace: -1
    signal requestClose()

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var monitorData: HyprlandData.monitors.find(function (m) { return m.id === (root.monitor ? root.monitor.id : -1); })

    readonly property real wsScale: Config.options.overview.scale
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property int spacing: 6
    readonly property int activeWsId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

    readonly property bool rotated: monitorData ? (monitorData.transform % 2 === 1) : false
    readonly property real cellWidth: (monitorData && monitor)
        ? (((rotated ? monitor.height : monitor.width) - monitorData.reserved[0] - monitorData.reserved[2]) * wsScale / monitor.scale)
        : 200
    readonly property real cellHeight: (monitorData && monitor)
        ? (((rotated ? monitor.width : monitor.height) - monitorData.reserved[1] - monitorData.reserved[3]) * wsScale / monitor.scale)
        : 120

    function wsInCell(r, c) { return r * columns + c + 1; }

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    StyledRect {
        id: bg
        anchors.fill: parent
        implicitWidth: cellCol.implicitWidth + 2 * Theme.padding.large
        implicitHeight: cellCol.implicitHeight + 2 * Theme.padding.large
        color: Theme.surfaceContainer
        radius: Theme.radius.large
        border.color: Theme.outlineVariant
        border.width: 1

        Column {
            id: cellCol
            anchors.centerIn: parent
            spacing: root.spacing
            Repeater {
                model: root.rows
                delegate: Row {
                    required property int index
                    readonly property int rowIdx: index
                    spacing: root.spacing
                    Repeater {
                        model: root.columns
                        delegate: Rectangle {
                            id: cell
                            required property int index
                            readonly property int wsId: root.wsInCell(rowIdx, index)
                            implicitWidth: root.cellWidth
                            implicitHeight: root.cellHeight
                            radius: Theme.radius.normal
                            color: wsId === root.draggingTargetWorkspace ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                            border.color: wsId === root.activeWsId ? Theme.primary : "transparent"
                            border.width: 2

                            StyledText {
                                anchors.centerIn: parent
                                text: cell.wsId
                                color: Theme.textDim
                                font.pixelSize: Theme.font.size.larger
                            }
                            MouseArea {
                                id: cellMa
                                anchors.fill: parent
                                onClicked: { Hyprland.dispatch("hl.dsp.focus({workspace=" + cell.wsId + "})"); root.requestClose(); }
                            }
                            DropArea {
                                anchors.fill: parent
                                onEntered: root.draggingTargetWorkspace = cell.wsId
                                onExited: if (root.draggingTargetWorkspace === cell.wsId) root.draggingTargetWorkspace = -1
                            }
                            StateLayer { pressed: cellMa.pressed }
                        }
                    }
                }
            }
        }

        Item {
            id: windowSpace
            anchors.centerIn: parent
            width: cellCol.implicitWidth
            height: cellCol.implicitHeight
            Repeater {
                model: ScriptModel {
                    values: ToplevelManager.toplevels.values.filter(function (t) {
                        var c = HyprlandData.clientForToplevel(t);
                        return c && c.workspace && c.workspace.id >= 1 && c.workspace.id <= root.rows * root.columns;
                    })
                }
                delegate: OverviewWindow {
                    required property var modelData
                    readonly property var wd: HyprlandData.clientForToplevel(modelData)
                    readonly property int wsId: wd ? wd.workspace.id : 1
                    readonly property int col: (wsId - 1) % root.columns
                    readonly property int rowI: Math.floor((wsId - 1) / root.columns) % root.rows
                    toplevel: modelData
                    windowData: wd
                    monitorData: HyprlandData.monitors.find(function (m) { return m.id === (wd ? wd.monitor : -1); })
                    widgetMonitor: root.monitorData
                    scale: root.wsScale
                    overviewOpen: root.overviewOpen
                    xOffset: (root.cellWidth + root.spacing) * col
                    yOffset: (root.cellHeight + root.spacing) * rowI
                    dropTarget: root.draggingTargetWorkspace
                    onRequestClose: root.requestClose()
                }
            }
        }
    }
}
