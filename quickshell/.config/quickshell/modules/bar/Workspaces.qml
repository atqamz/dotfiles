// quickshell/.config/quickshell/modules/bar/Workspaces.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components

// end-4-style workspace strip: a fixed row of slots, occupied slots get a
// filled highlight, and a single bright indicator slides to the active one.
// Adapted to the locked monochrome palette (active = white pill, black number).
Item {
    id: root

    property alias hovered: hover.hovered
    readonly property int shown: 5
    readonly property int slot: 22
    readonly property int activeMargin: 3

    readonly property int activeId: {
        const vals = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < vals.length; ++i)
            if (vals[i].active)
                return vals[i].id;
        return 1;
    }
    readonly property int group: Math.floor((activeId - 1) / shown)
    readonly property int indexInGroup: (activeId - 1) % shown

    property var occupied: []
    function updateOccupied() {
        const vals = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        const arr = [];
        for (let i = 0; i < shown; ++i) {
            const id = group * shown + i + 1;
            arr.push(vals.some(w => w.id === id));
        }
        occupied = arr;
    }

    Component.onCompleted: updateOccupied()
    onGroupChanged: updateOccupied()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.updateOccupied(); }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.updateOccupied(); }
    }

    implicitWidth: slot * shown
    implicitHeight: Config.options.bar.height

    HoverHandler { id: hover }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch("workspace r+1");
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch("workspace r-1");
        }
    }

    // Right-click anywhere on the strip toggles the overview (end-4 behaviour).
    // Per-cell TapHandlers only accept LeftButton, so the right-click falls
    // through to here.
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "overview", "toggle"])
    }

    // Occupied highlights
    Row {
        anchors.centerIn: parent
        spacing: 0
        Repeater {
            model: root.shown
            StyledRect {
                required property int index
                implicitWidth: root.slot
                implicitHeight: root.slot
                radius: root.slot / 2
                color: Theme.surfaceContainerHighest
                opacity: (root.occupied[index] ?? false) ? 1 : 0
                Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
            }
        }
    }

    // Sliding active indicator
    StyledRect {
        id: indicator
        radius: Theme.radius.full
        color: Theme.primary
        y: (root.height - height) / 2
        x: root.indexInGroup * root.slot + root.activeMargin
        implicitWidth: root.slot - root.activeMargin * 2
        implicitHeight: root.slot - root.activeMargin * 2
        Behavior on x { Anim { curve: Theme.anim.decel; duration: Theme.anim.durations.normal } }
    }

    // Numbers + click targets
    Row {
        anchors.centerIn: parent
        spacing: 0
        Repeater {
            model: root.shown
            Item {
                id: cell
                required property int index
                readonly property int wsId: root.group * root.shown + index + 1
                readonly property bool isActive: root.activeId === wsId
                width: root.slot
                height: root.slot
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    anchors.centerIn: parent
                    text: cell.wsId
                    font.pixelSize: Theme.font.size.smaller
                    font.bold: cell.isActive
                    color: cell.isActive ? Theme.textOnPrimary
                         : ((root.occupied[cell.index] ?? false) ? Theme.textVariant : Theme.textDim)
                }

                TapHandler { onTapped: Hyprland.dispatch("workspace " + cell.wsId); }
            }
        }
    }
}
