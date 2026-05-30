import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.services

Item {
    id: win
    property var toplevel
    property var windowData
    property var monitorData       // the window's own monitor (for origin/reserved)
    property var widgetMonitor     // the grid's monitor (JSON from HyprlandData.monitors)
    property real scale: 0.18
    property real xOffset: 0
    property real yOffset: 0
    property bool overviewOpen: false
    property int dropTarget: -1
    signal requestClose()

    // ADAPT end-4 OverviewWindow.qml:20-31 — ratio handles monitor transform
    // (swap w/h when transform & 1) and per-monitor scale. Both monitorData and
    // widgetMonitor are JSON objects from `hyprctl monitors -j`.
    readonly property real widthRatio: {
        if (!monitorData || !widgetMonitor) return 1;
        const widgetWidth = widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width;
        const monitorWidth = monitorData.transform & 1 ? monitorData.height : monitorData.width;
        return (widgetWidth * monitorData.scale) / (monitorWidth * widgetMonitor.scale);
    }
    readonly property real heightRatio: {
        if (!monitorData || !widgetMonitor) return 1;
        const widgetHeight = widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height;
        const monitorHeight = monitorData.transform & 1 ? monitorData.width : monitorData.height;
        return (widgetHeight * monitorData.scale) / (monitorHeight * widgetMonitor.scale);
    }
    readonly property real xWithin: windowData
        ? Math.max((windowData.at[0] - (monitorData ? monitorData.x : 0) - (monitorData ? monitorData.reserved[0] : 0)) * scale * widthRatio, 0)
        : 0
    readonly property real yWithin: windowData
        ? Math.max((windowData.at[1] - (monitorData ? monitorData.y : 0) - (monitorData ? monitorData.reserved[1] : 0)) * scale * heightRatio, 0)
        : 0

    property real radius: Theme.radius.small

    x: xWithin + xOffset
    y: yWithin + yOffset
    z: clickMa.drag.active ? 9999 : (win.active ? 2 : 1)
    width: windowData ? windowData.size[0] * scale * widthRatio : 100
    height: windowData ? windowData.size[1] * scale * heightRatio : 80
    Behavior on x { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on y { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on width { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on height { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }

    readonly property string addr: windowData ? windowData.address : ""
    readonly property bool active: (toplevel && toplevel.HyprlandToplevel) ? toplevel.HyprlandToplevel.activated : false

    clip: true

    Image {                          // icon fallback / identity (behind capture)
        anchors.centerIn: parent
        width: Math.min(win.width, win.height) * 0.3
        height: width
        source: {
            if (!win.windowData) return "";
            // 3-step resolve (byId → lowercase → heuristic), matching DockService.
            var e = DockService.resolve(win.windowData.class || "");
            return Quickshell.iconPath(e ? e.icon : "", "image-missing");
        }
        visible: !capture.hasContent
        fillMode: Image.PreserveAspectFit
    }

    ScreencopyView {
        id: capture
        anchors.fill: parent
        captureSource: win.overviewOpen ? win.toplevel : null
        live: true
    }

    Rectangle {                      // border (active highlight)
        anchors.fill: parent
        color: "transparent"
        radius: win.radius
        border.color: win.active ? Theme.primary : Theme.outlineVariant
        border.width: win.active ? 2 : 1
    }
    StateLayer { pressed: clickMa.pressed }

    Timer {
        id: resnap
        interval: 120; repeat: false
        onTriggered: { win.x = Math.round(win.xWithin + win.xOffset); win.y = Math.round(win.yWithin + win.yOffset); }
    }

    MouseArea {
        id: clickMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: win
        onPressed: function (mouse) {
            win.Drag.active = true;
            win.Drag.source = win;
            win.Drag.hotSpot = Qt.point(mouse.x, mouse.y);
        }
        onReleased: {
            win.Drag.active = false;
            var target = win.dropTarget;
            if (target !== -1 && win.windowData && target !== win.windowData.workspace.id) {
                Hyprland.dispatch("movetoworkspacesilent " + target + ",address:" + win.addr);
            }
            resnap.restart();
        }
        onClicked: function (mouse) {
            if (!win.windowData) return;
            if (mouse.button === Qt.LeftButton) {
                Hyprland.dispatch("focuswindow address:" + win.addr);
                win.requestClose();
            } else if (mouse.button === Qt.MiddleButton) {
                Hyprland.dispatch("closewindow address:" + win.addr);
            }
        }
    }
    StyledToolTip { text: win.windowData ? win.windowData.title : ""; visible: clickMa.containsMouse }
}
