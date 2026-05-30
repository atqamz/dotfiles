# Quickshell overview (workspace exposé) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Fullscreen workspace exposé — grid of workspaces, each painting its windows as live ScreencopyView thumbnails at real scaled geometry; click to switch/focus, middle-click close, drag to move between workspaces. Super+grave / IPC trigger.

**Architecture:** `HyprlandData` singleton parses `hyprctl clients/monitors -j` (reactive on `Hyprland.rawEvent`). `Overview.qml` is the per-screen fullscreen overlay (scrim + spring, IPC, keybind). `OverviewGrid.qml` lays out workspace cells; `OverviewWindow.qml` is one window tile (Toplevel↔hyprctl paired via `toplevel.HyprlandToplevel.address`, captured by ScreencopyView).

**Tech Stack:** Quickshell 0.3.0 / Qt 6.10.3 QML. No offline validator — launch `qs`, grep log, kill.

**Spec:** `docs/superpowers/specs/2026-05-31-quickshell-overview-design.md` (read it — esp. the linchpin API + the review corrections).

**Reference (proven math — adapt, don't blind-copy):** `~/repo/dots-hyprland/dots/.config/quickshell/ii/`:
- `modules/ii/overview/OverviewWindow.qml:20-43` — widthRatio/heightRatio/initX/initY/target size formulas.
- `modules/ii/overview/OverviewWidget.qml:175-245` — ScriptModel filter, window delegate offsets, drag MouseArea, DropArea.
- `services/HyprlandData.qml` — hyprctl parse + `clientForToplevel`/`toplevelsForWorkspace` + rawEvent refresh.
**When adapting: substitute our Theme tokens, use CLASSIC dispatch strings (NOT their `hl.dsp.*` Lua), and apply the spec's review corrections (ScriptModel, single-MouseArea drag, deferred re-snap Timer, rawEvent skip-list, `HyprlandToplevel.activated`).**

---

## VERIFY BLOCK (end of EVERY task)

```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
qs kill 2>/dev/null; sleep 1
timeout 9 qs -p "$CFG" >/tmp/qs-ov.log 2>&1 &
sleep 5
grep -q "Configuration Loaded" /tmp/qs-ov.log && echo "LOADED OK" || echo "LOAD FAIL"
grep -iE "error|warning|is not a type|cannot|undefined|null|reference" /tmp/qs-ov.log | grep -v "BAT0\|\.desktop\|layershell\|Keys\|GreetdState" || echo "NO RELEVANT ERRORS"
qs kill 2>/dev/null
```
Expected `LOADED OK` + `NO RELEVANT ERRORS`.

---

## Task 1: HyprlandData service

**Files:**
- Create: `quickshell/.config/quickshell/services/HyprlandData.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

READ FIRST: `services/Todo.qml` (Process+StdioCollector+JSON.parse pattern), end-4 `services/HyprlandData.qml` (the reference — adapt its structure).

- [ ] **Step 1: Register** — append to `services/qmldir`: `singleton HyprlandData 1.0 HyprlandData.qml`

- [ ] **Step 2: Write HyprlandData.qml**
```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []
    property var monitors: []

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) return null;
        return root.windowByAddress["0x" + toplevel.HyprlandToplevel.address] || null;
    }

    function refresh() { clientsProc.running = true; monitorsProc.running = true; }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var list = JSON.parse(this.text).filter(function (c) { return c.mapped !== false; });
                    var byAddr = ({});
                    for (var i = 0; i < list.length; ++i) byAddr[list[i].address] = list[i];
                    root.windowList = list;
                    root.windowByAddress = byAddr;
                    root.addresses = list.map(function (c) { return c.address; });
                } catch (e) { /* keep last good */ }
            }
        }
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(this.text); } catch (e) {}
            }
        }
    }

    // Debounced refresh on Hyprland events; skip noisy ones (screencast is
    // emitted BY ScreencopyView → would feedback-loop while overview is open).
    Timer {
        id: debounce
        interval: 100; repeat: false
        onTriggered: root.refresh()
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].indexOf(event.name) !== -1) return;
            debounce.restart();
        }
    }

    Component.onCompleted: root.refresh()
}
```

- [ ] **Step 3: VERIFY** (VERIFY BLOCK). Confirm no `HyprlandData`/`Hyprland`/`Process` type errors. (No consumer yet — proves it compiles + registers + refreshes on load.)

- [ ] **Step 4: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/services/HyprlandData.qml quickshell/.config/quickshell/services/qmldir
git commit -m "add HyprlandData service: reactive hyprctl clients + monitors"
```

---

## Task 2: Overview shell + grid skeleton + keybind

**Files:**
- Create: `quickshell/.config/quickshell/modules/Overview.qml`
- Create: `quickshell/.config/quickshell/modules/overview/OverviewGrid.qml`
- Create: `quickshell/.config/quickshell/modules/overview/qmldir`
- Modify: `quickshell/.config/quickshell/shell.qml` (add `Overview {}`)
- Modify: `hypr/.config/hypr/hyprland.conf` (keybind)

READ FIRST: `modules/Launcher.qml` or any just-merged overlay (the `shown` scrim+spring pattern), `modules/bar/WorkspacesPill.qml` (Hyprland.workspaces + dispatch).

- [ ] **Step 1: `modules/overview/qmldir`**
```
OverviewGrid 1.0 OverviewGrid.qml
OverviewWindow 1.0 OverviewWindow.qml
```
(OverviewWindow added in Task 3; listing it now is harmless if the file lands then — but to avoid a load error, add the OverviewWindow line in Task 3, not now. For Task 2 list ONLY OverviewGrid.)

- [ ] **Step 2: `modules/Overview.qml`** — Scope + IPC + per-screen overlay with scrim+spring:
```qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services
import "overview"

Scope {
    id: root
    property bool open: false
    function toggle(): void { open = !open; if (open) HyprlandData.refresh(); }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; HyprlandData.refresh(); }
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

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            Keys.onEscapePressed: root.open = false

            Rectangle {                  // scrim
                anchors.fill: parent
                color: Theme.scrim
                opacity: panel.shown ? 1 : 0
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
                MouseArea { anchors.fill: parent; onClicked: root.open = false }
            }

            OverviewGrid {
                id: grid
                anchors.centerIn: parent
                screen: panel.modelData
                overviewOpen: root.open
                opacity: panel.shown ? 1 : 0
                scale: panel.shown ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }
                onRequestClose: root.open = false
                // exit animation out of scope (re-skin/overlay convention)
            }
        }
    }
}
```

- [ ] **Step 3: `modules/overview/OverviewGrid.qml`** — workspace cells (NO window tiles yet):
```qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.services

Item {
    id: root
    required property var screen
    property bool overviewOpen: false
    signal requestClose()

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var monitorData: HyprlandData.monitors.find(function (m) { return m.id === (root.monitor ? root.monitor.id : -1); })

    // Tunables (no Config system here):
    readonly property real wsScale: 0.18
    readonly property int rows: 2
    readonly property int columns: 5            // → workspaces 1..10
    readonly property int spacing: 6
    readonly property int activeWsId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

    // Cell size from scaled monitor dims (swap w/h when transform is odd).
    readonly property bool rotated: monitorData ? (monitorData.transform % 2 === 1) : false
    readonly property real cellWidth: monitorData
        ? (((rotated ? monitor.height : monitor.width) - monitorData.reserved[0] - monitorData.reserved[2]) * wsScale / monitor.scale)
        : 200
    readonly property real cellHeight: monitorData
        ? (((rotated ? monitor.width : monitor.height) - monitorData.reserved[1] - monitorData.reserved[3]) * wsScale / monitor.scale)
        : 120

    function wsInCell(r, c) { return r * columns + c + 1; }   // 1-indexed ws

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
                            required property int index
                            readonly property int wsId: root.wsInCell(rowIdx, index)
                            implicitWidth: root.cellWidth
                            implicitHeight: root.cellHeight
                            radius: Theme.radius.normal
                            color: Theme.surfaceContainerHigh
                            border.color: wsId === root.activeWsId ? Theme.primary : "transparent"
                            border.width: 2

                            StyledText {
                                anchors.centerIn: parent
                                text: wsId
                                color: Theme.textDim
                                font.pixelSize: Theme.font.size.larger
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { Hyprland.dispatch("workspace " + wsId); root.requestClose(); }
                            }
                            StateLayer { pressed: false }   // hover affordance on the cell
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 4: shell.qml** — add `Overview {}` after `Dock {}`.

- [ ] **Step 5: Keybind** — add to `hypr/.config/hypr/hyprland.conf` near the `qs ipc call` binds (~line 147):
```
bind = $mainMod, grave, exec, qs ipc call overview toggle
```
(`grave` = backtick. Do NOT use `$mainMod, Tab` — bound to `submap, wsrows`.)

- [ ] **Step 6: VERIFY** (VERIFY BLOCK) + IPC + open test:
```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
qs kill 2>/dev/null; sleep 1; timeout 9 qs -p "$CFG" >/tmp/qs-ov2.log 2>&1 & sleep 5
qs -p "$CFG" ipc show 2>/dev/null | grep -i overview && echo "overview IPC OK"
qs -p "$CFG" ipc call overview toggle 2>/dev/null && echo "toggle ok"
sleep 1; qs kill 2>/dev/null
```
Visually: super+grave opens a grid of empty workspace cells, active one bordered; click a cell switches workspace + closes.

- [ ] **Step 7: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/modules/Overview.qml quickshell/.config/quickshell/modules/overview/ quickshell/.config/quickshell/shell.qml hypr/.config/hypr/hyprland.conf
git commit -m "add overview shell: workspace grid, scrim, keybind, IPC"
```

---

## Task 3: OverviewWindow tile + thumbnails

**Files:**
- Create: `quickshell/.config/quickshell/modules/overview/OverviewWindow.qml`
- Modify: `quickshell/.config/quickshell/modules/overview/qmldir` (add OverviewWindow line)
- Modify: `quickshell/.config/quickshell/modules/overview/OverviewGrid.qml` (add the window Repeater)

READ FIRST (the proven math to adapt): end-4 `modules/ii/overview/OverviewWindow.qml:20-43` (ratios/initX/initY/target) and `OverviewWidget.qml:175-245` (delegate offsets). Substitute our tokens; classic dispatch; corrections per spec.

- [ ] **Step 1: `OverviewWindow.qml`** — props `toplevel`, `windowData`, `monitorData`, `widgetMonitor`, `scale`, `xOffset`, `yOffset`, `overviewOpen`. Compute (ADAPT from end-4 lines above):
  - `widthRatio`/`heightRatio` (handle `transform & 1` swap + scale).
  - in-cell pos `xWithin = max((windowData.at[0] - (monitorData.x||0) - monitorData.reserved[0]) * scale, 0)`, `yWithin` analogous.
  - `x: xWithin + xOffset`, `y: yWithin + yOffset` (with `Behavior` via `Theme.anim.standardDecel`).
  - `width: windowData.size[0] * scale * widthRatio`, `height` analogous.
  Body:
```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

Item {
    id: win
    property var toplevel
    property var windowData
    property var monitorData
    property var widgetMonitor
    property real scale: 0.18
    property real xOffset: 0
    property real yOffset: 0
    property bool overviewOpen: false
    signal requestClose()

    // --- ratios + position: ADAPT end-4 OverviewWindow.qml:20-43 ---
    // Define these as readonly properties (T4's re-snap Timer references xWithin/yWithin):
    //   widthRatio  = (widgetW * monitorData.scale) / (monW * widgetMonitor.scale), W swapped when transform&1
    //   heightRatio = analogous
    //   xWithin = Math.max((windowData.at[0] - (monitorData.x||0) - monitorData.reserved[0]) * scale, 0)
    //   yWithin = Math.max((windowData.at[1] - (monitorData.y||0) - monitorData.reserved[1]) * scale, 0)
    readonly property real widthRatio: /* ADAPT */ 1
    readonly property real heightRatio: /* ADAPT */ 1
    readonly property real xWithin: windowData ? Math.max((windowData.at[0] - (monitorData ? monitorData.x : 0) - (monitorData ? monitorData.reserved[0] : 0)) * scale, 0) : 0
    readonly property real yWithin: windowData ? Math.max((windowData.at[1] - (monitorData ? monitorData.y : 0) - (monitorData ? monitorData.reserved[1] : 0)) * scale, 0) : 0

    x: xWithin + xOffset
    y: yWithin + yOffset
    width: windowData ? windowData.size[0] * scale * widthRatio : 100
    height: windowData ? windowData.size[1] * scale * heightRatio : 80
    Behavior on x { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on y { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on width { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }
    Behavior on height { Anim { curve: Theme.anim.standardDecel; duration: Theme.anim.durations.normal } }

    readonly property string addr: windowData ? windowData.address : ""
    readonly property bool active: toplevel && toplevel.HyprlandToplevel ? toplevel.HyprlandToplevel.activated : false

    clip: true

    ScreencopyView {
        id: capture
        anchors.fill: parent
        captureSource: win.overviewOpen ? win.toplevel : null
        live: true
    }

    // icon overlay (fallback / identity)
    Image {
        anchors.centerIn: parent
        width: Math.min(win.width, win.height) * 0.3
        height: width
        source: {
            var e = DesktopEntries.heuristicLookup(win.windowData ? win.windowData.class : "");
            return Quickshell.iconPath(e ? e.icon : "", "image-missing");
        }
        visible: !capture.hasContent
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {                 // border + state tint
        anchors.fill: parent
        color: "transparent"
        radius: Theme.radius.small
        border.color: win.active ? Theme.primary : Theme.outlineVariant
        border.width: win.active ? 2 : 1
    }
    StateLayer { pressed: clickMa.pressed }

    MouseArea {
        id: clickMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
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
```
(Drag added in Task 4 — this task is click/middle only.)

- [ ] **Step 2: qmldir** — add `OverviewWindow 1.0 OverviewWindow.qml`.

- [ ] **Step 3: Wire the window Repeater into OverviewGrid** — add an overlay `Item` (anchored over the cells) containing a Repeater with a `ScriptModel` (ADAPT end-4 OverviewWidget.qml:175-200):
```qml
import Quickshell  // for ScriptModel
// ... inside bg, as a sibling of cellCol, an Item the same size as cellCol:
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
            onRequestClose: root.requestClose()
        }
    }
}
```
Need `import Quickshell.Wayland` (ToplevelManager) + `import Quickshell` (ScriptModel) at the top of OverviewGrid.qml.

- [ ] **Step 4: VERIFY** (VERIFY BLOCK). Open the overview (`qs ipc call overview toggle`) with windows open on workspaces 1-10; confirm thumbnails render at scaled positions, active window bordered, left-click focuses + closes, middle-click closes a window. (Hard gate = log clean; visual confirm if possible.)

- [ ] **Step 5: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/modules/overview/
git commit -m "add overview window tiles: live thumbnails, focus and close"
```

---

## Task 4: Drag window → workspace

**Files:**
- Modify: `quickshell/.config/quickshell/modules/overview/OverviewWindow.qml` (drag on the MouseArea)
- Modify: `quickshell/.config/quickshell/modules/overview/OverviewGrid.qml` (DropArea per cell + drag-target state)

ADAPT end-4 `OverviewWidget.qml:150-245` (DropArea + drag MouseArea + updateWindowPosition Timer). Single MouseArea (no DragHandler). Classic dispatch.

- [ ] **Step 1: OverviewGrid drag state + DropArea** — add to root: `property int draggingTargetWorkspace: -1`. Add a `DropArea { anchors.fill: parent }` inside each workspace cell:
```qml
DropArea {
    anchors.fill: parent
    onEntered: root.draggingTargetWorkspace = wsId
    onExited: if (root.draggingTargetWorkspace === wsId) root.draggingTargetWorkspace = -1
}
```
Optionally tint the cell while it's the drop target (`color: wsId === root.draggingTargetWorkspace ? mix(...) : surfaceContainerHigh`).

- [ ] **Step 2: OverviewWindow drag** — extend the MouseArea with `drag.target: win`, `Drag.hotSpot`, raise z while dragging, and a deferred re-snap Timer:
```qml
property int draggingTargetWorkspace: -1   // bound from grid (pass a callback or read grid)
z: win.Drag.active ? 9999 : 1

Timer {
    id: resnap
    interval: 120; repeat: false
    onTriggered: { win.x = Math.round(win.xWithin + win.xOffset); win.y = Math.round(win.yWithin + win.yOffset); }
}

// in the MouseArea:
drag.target: win
onPressed: function (mouse) {
    win.Drag.active = true; win.Drag.source = win;
    win.Drag.hotSpot = Qt.point(mouse.x, mouse.y);
}
onReleased: {
    win.Drag.active = false;
    var target = /* grid.draggingTargetWorkspace */ ;
    if (target !== -1 && win.windowData && target !== win.windowData.workspace.id) {
        Hyprland.dispatch("movetoworkspacesilent " + target + ",address:" + win.addr);
    }
    resnap.restart();   // re-snap to computed position (hyprctl refresh races release)
}
```
Pass the grid's `draggingTargetWorkspace` into the tile (add a `property int dropTarget: -1` on OverviewWindow, bind `dropTarget: root.draggingTargetWorkspace` in the delegate, read it in `onReleased`). Keep the existing `onClicked` (a real drag suppresses `onClicked`, so click vs drag is disambiguated by Qt).

- [ ] **Step 3: VERIFY** (VERIFY BLOCK). Drag a window tile onto another cell → it moves to that workspace (`hyprctl`), tile re-snaps. Dropping outside → re-snaps home.

- [ ] **Step 4: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/modules/overview/
git commit -m "add overview drag-to-move windows between workspaces"
```

---

## Final review + merge

- [ ] Dispatch a final code-quality reviewer over `git diff master..HEAD` (quickshell + hyprland.conf).
- [ ] Full-shell smoke: VERIFY BLOCK; `ipc show` lists `overview`; super+grave opens; thumbnails render; click/middle/drag work; Esc/scrim close; ScreencopyView stops on close (captureSource null).
- [ ] Use superpowers:finishing-a-development-branch (push, PR, merge).
