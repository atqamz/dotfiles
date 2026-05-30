# Quickshell dock — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add a bottom-center, auto-hiding (hover-reveal) dock showing pinned + running apps; relocate the bar from bottom to top to free the bottom edge.

**Architecture:** Reuse the bar's edge-agnostic `PeekState` FSM for both the relocated top bar and the bottom dock. A `DockService` singleton merges `ToplevelManager` (reactive running apps) with persisted pins (Todo-pattern file) and resolves icons via `DesktopEntries`/`Quickshell.iconPath`. Dock UI is a `Scope`+`Variants`+`PanelWindow` per screen, styled on the design system.

**Tech Stack:** Quickshell 0.3.0 / Qt 6.10.3 QML. No offline validator — launch `qs`, grep log, kill.

**Spec:** `docs/superpowers/specs/2026-05-31-quickshell-dock-design.md` (read it; this operationalizes it).

---

## VERIFY BLOCK (end of EVERY task)

```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
qs kill 2>/dev/null; sleep 1
timeout 9 qs -p "$CFG" >/tmp/qs-dock.log 2>&1 &
sleep 5
grep -q "Configuration Loaded" /tmp/qs-dock.log && echo "LOADED OK" || echo "LOAD FAIL"
grep -iE "error|warning|is not a type|cannot|undefined|null|reference" /tmp/qs-dock.log | grep -v "BAT0\|\.desktop\|layershell\|Keys\|GreetdState" || echo "NO RELEVANT ERRORS"
qs kill 2>/dev/null
```
Expected `LOADED OK` + `NO RELEVANT ERRORS`. Fix and re-run on any QML/type error.

---

## Task 1: Relocate bar bottom → top

**Files:**
- Rename: `quickshell/.config/quickshell/modules/bar/BottomBar.qml` → `modules/bar/TopBar.qml`
- Modify: `modules/Bar.qml` (the `Variants` delegate that instantiates it)

- [ ] **Step 1: Rename the file**
```bash
cd /home/atqa/dotfiles/quickshell/.config/quickshell/modules/bar
git mv BottomBar.qml TopBar.qml
```

- [ ] **Step 2: Flip anchors + hotZone to the top**
In `TopBar.qml`: the panel `anchors` block `bottom: true` → `top: true` (keep `left`/`right`). The hotZone Item `anchors.bottom: parent.bottom` → `anchors.top: parent.top`. Update the file's header comment path.

- [ ] **Step 3: Correct the slide geometry (the load-bearing fix)**
The bottom version parks pillRow at `y: panelHeight` (below) and slides to `visibleY`. For the top edge invert it. Set the pillRow initial `y` and the PeekState offsets:
```qml
Item {
    id: pillRow
    // ...existing anchors.left/right + margins, height: panel.pillHeight...
    y: panel.slideFromY        // start hidden (above)
}
// ...
PeekState {
    id: peek
    slideTarget: pillRow
    slideFromY: -panel.panelHeight   // fully ABOVE the strip (NOT -pillHeight)
    slideToY: panel.edgeMargin       // sits edgeMargin below the top edge
    hotZoneItem: hotZone
    watchedItems: [launcher, workspaces, media, clock, resources, tray, status]
    dwellMs: 600
}
```
Add the helper props if referenced: keep `panelHeight`, `edgeMargin`, `hotZoneHeight` as today. Remove/ignore the old `visibleY` (no longer used) — or repurpose, but do NOT leave it driving the slide.

- [ ] **Step 4: Flip the mask to reveal the TOP hotzone strip when hidden**
```qml
mask: Region {
    x: 0
    width: panel.width
    y: 0
    height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
}
```
(Bottom version used `y: panelHeight - hotZoneHeight` — wrong for top; must be `y: 0` or the hotzone is unclickable and reveal is dead.)

- [ ] **Step 5: Update Bar.qml reference**
In `modules/Bar.qml`, the `Variants` delegate `BottomBar { ... }` → `TopBar { ... }`. (If it imports by relative path/component name, update accordingly.)

- [ ] **Step 6: VERIFY** (run the VERIFY BLOCK). Then manually confirm reveal: the log clean is the hard gate; visually the bar should sit at the top and peek on top-edge hover.

- [ ] **Step 7: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/modules/bar/TopBar.qml quickshell/.config/quickshell/modules/Bar.qml
git commit -m "relocate bar from bottom to top edge"
```

---

## Task 2: DockService singleton (app model + pins + icons)

**Files:**
- Create: `quickshell/.config/quickshell/services/DockService.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir` (add registration)

- [ ] **Step 1: Register the singleton**
Append to `services/qmldir`:
```
singleton DockService 1.0 DockService.qml
```

- [ ] **Step 2: Write DockService.qml**
Mirrors the `Todo.qml` persistence pattern (read first: `services/Todo.qml`). `DesktopEntries` + `ToplevelManager` are singletons; `.toplevels`/`.applications` are `UntypedObjectModel` → use `.values` for JS arrays.
```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property var pinned: []   // array of desktop ids (strings)
    readonly property string storePath: Quickshell.env("HOME") + "/.local/state/quickshell/dock-pins.json"

    // appId -> DesktopEntry | null  (exact id, lowercase, then heuristic)
    function resolve(appId): var {
        if (!appId) return null;
        return DesktopEntries.byId(appId)
            || DesktopEntries.byId(appId.toLowerCase())
            || DesktopEntries.heuristicLookup(appId)
            || null;
    }
    function resolvedId(appId): string {
        var e = resolve(appId);
        return e ? e.id : appId;
    }

    // Ordered dock model: pinned (with their toplevels) → separator → running-only.
    readonly property var entries: {
        var tl = ToplevelManager.toplevels.values;
        var groups = ({});                       // resolvedId -> [Toplevel]
        for (var i = 0; i < tl.length; ++i) {
            var t = tl[i];
            var rid = root.resolvedId(t.appId);
            if (!groups[rid]) groups[rid] = [];
            groups[rid].push(t);
        }
        var out = [];
        for (var p = 0; p < root.pinned.length; ++p) {
            var pid = root.pinned[p];
            var pe = DesktopEntries.byId(pid) || root.resolve(pid);
            out.push({
                id: pid,
                name: pe ? pe.name : pid,
                iconPath: Quickshell.iconPath(pe ? pe.icon : "", "application-x-executable"),
                toplevels: groups[pid] || [],
                pinned: true
            });
            delete groups[pid];
        }
        var runIds = Object.keys(groups);
        if (root.pinned.length > 0 && runIds.length > 0) out.push({ separator: true });
        for (var r = 0; r < runIds.length; ++r) {
            var e = root.resolve(runIds[r]);
            out.push({
                id: runIds[r],
                name: e ? e.name : runIds[r],
                iconPath: Quickshell.iconPath(e ? e.icon : "", "application-x-executable"),
                toplevels: groups[runIds[r]],
                pinned: false
            });
        }
        return out;
    }

    function isPinned(id: string): bool { return root.pinned.indexOf(id) >= 0; }
    function pin(id: string): void {
        if (root.isPinned(id)) return;
        var next = root.pinned.slice(); next.push(id); root.pinned = next; root.save();
    }
    function unpin(id: string): void {
        root.pinned = root.pinned.filter(function (x) { return x !== id; });
        root.save();
    }

    function save(): void {
        writeProc.running = false;
        writeProc.command = ["bash", "-c", "mkdir -p ~/.local/state/quickshell && cat > " + root.storePath];
        writeProc.running = true;
    }

    Process {
        id: readProc
        command: ["cat", root.storePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pinned = JSON.parse(this.text); }
                catch (e) { root.pinned = []; }
            }
        }
    }

    Process {
        id: writeProc
        onRunningChanged: {
            if (running) { write(JSON.stringify(root.pinned)); closeStdin(); }
        }
    }

    Component.onCompleted: readProc.running = true
}
```
Note on the writer: this uses `onRunningChanged` → `write`/`closeStdin` (cleaner than Todo's repeated `stdinReady.connect`, which stacks handlers). If `write`/`closeStdin` require the `stdinReady` signal in this Quickshell version, fall back to Todo's exact `stdinReady.connect` form — verify against `Todo.qml` behavior when you run VERIFY (pin something, check the file writes).

- [ ] **Step 3: VERIFY** (VERIFY BLOCK). Then functional check — confirm the service loads and the model is reactive:
```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
qs kill 2>/dev/null; sleep 1; timeout 9 qs -p "$CFG" >/tmp/qs-dock2.log 2>&1 & sleep 5
grep -iE "DockService|DesktopEntries|ToplevelManager|Singleton" /tmp/qs-dock2.log | grep -iE "error|not a type|cannot" || echo "DockService clean"
qs kill 2>/dev/null
```
(No consumer yet, so this only proves the singleton compiles + registers. The model is exercised in Task 3.)

- [ ] **Step 4: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/services/DockService.qml quickshell/.config/quickshell/services/qmldir
git commit -m "add DockService: toplevel grouping, pins, icon resolution"
```

---

## Task 3: Dock UI

**Files:**
- Create: `quickshell/.config/quickshell/modules/Dock.qml`
- Create: `quickshell/.config/quickshell/modules/dock/DockApps.qml`
- Create: `quickshell/.config/quickshell/modules/dock/DockAppButton.qml`
- Create: `quickshell/.config/quickshell/modules/dock/DockSeparator.qml`
- Modify: whatever root file instantiates top-level modules (the shell entry — find it: it instantiates `Bar`, `SidebarRight`, overlays). Add `Dock {}` there.

- [ ] **Step 1: Find + read the shell entry point**
```bash
cd /home/atqa/dotfiles/quickshell/.config/quickshell
grep -rln "SidebarRight\s*{\|Bar\s*{\|Launcher\s*{" --include=*.qml | grep -v modules/
```
Read it to learn how top-level modules are instantiated (likely `shell.qml` or a root `ShellRoot`). `Dock {}` gets added there alongside `Bar {}`.

- [ ] **Step 2: DockSeparator.qml**
```qml
import QtQuick
import qs.components

Rectangle {
    implicitWidth: 1
    implicitHeight: Theme.icon.size.larger
    radius: Theme.radius.full
    color: Theme.outlineVariant
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
```

- [ ] **Step 3: DockAppButton.qml**
One app: icon Image with Error/empty fallback glyph, running dot, active highlight via StateLayer.focused, tooltip, interactions. `entry` is a DockService entry object.
```qml
import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: btn
    required property var entry            // { id, name, iconPath, toplevels, pinned }
    property real radius: Theme.radius.normal
    readonly property var tops: entry.toplevels || []
    readonly property bool running: tops.length > 0
    readonly property bool active: tops.some(function (t) { return t.activated; })
    property int cycleIdx: 0

    implicitWidth: Theme.icon.size.larger + 2 * Theme.padding.small
    implicitHeight: Theme.icon.size.larger + 2 * Theme.padding.small
    scale: ma.pressed ? 0.92 : 1
    Behavior on scale { Anim { curve: Theme.anim.clickBounce; duration: Theme.anim.durations.normal } }

    StateLayer { pressed: ma.pressed; focused: btn.active }

    Image {
        id: icon
        anchors.centerIn: parent
        width: Theme.icon.size.larger
        height: width
        sourceSize.width: width
        sourceSize.height: width
        source: btn.entry.iconPath
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectFit
    }
    MaterialIcon {           // fallback when icon missing/broken
        anchors.centerIn: parent
        text: "widgets"
        font.pixelSize: Theme.icon.size.large
        color: Theme.text
        visible: icon.status !== Image.Ready
    }

    // running indicator dot
    Rectangle {
        visible: btn.running
        width: btn.active ? 6 : 4
        height: width
        radius: Theme.radius.full
        color: Theme.text
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        Behavior on width { Anim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                if (btn.entry.pinned) DockService.unpin(btn.entry.id);
                else DockService.pin(btn.entry.id);
            } else if (mouse.button === Qt.MiddleButton) {
                var e = DockService.resolve(btn.entry.id); if (e) e.execute();
            } else { // left
                if (btn.running) {
                    btn.cycleIdx = (btn.cycleIdx + 1) % btn.tops.length;
                    btn.tops[btn.cycleIdx].activate();
                } else {
                    var de = DockService.resolve(btn.entry.id); if (de) de.execute();
                }
            }
        }
    }
    // NOTE: single MouseArea drives clicks AND ma.pressed (scale + StateLayer).
    // Do NOT add a sibling TapHandler — the MouseArea grabs the press, so the
    // TapHandler's pressed would never fire.

    StyledToolTip { text: btn.entry.name; visible: ma.containsMouse }
}
```

- [ ] **Step 4: DockApps.qml**
The horizontal row built from `DockService.entries`; separator entries render `DockSeparator`, others `DockAppButton`.
```qml
import QtQuick
import qs.components
import qs.services

Row {
    id: row
    spacing: Theme.spacing.small
    Behavior on implicitWidth { Anim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }

    Repeater {
        model: DockService.entries
        delegate: Loader {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: modelData.separator ? sepComp : btnComp
            Component { id: sepComp; DockSeparator {} }
            Component { id: btnComp; DockAppButton { entry: modelData } }
        }
    }
}
```

- [ ] **Step 5: Dock.qml**
`Scope` + `Variants` over screens → bottom-anchored `PanelWindow`, hotzone + dock card + reused `PeekState` for bottom-edge reveal, IpcHandler.
```qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import "bar" as Bar          // to reuse PeekState.qml from modules/bar/

Scope {
    id: root
    IpcHandler {
        target: "dock"
        function toggle(): void { /* optional manual reveal hook */ }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            readonly property int dockHeight: 60
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
                y: panel.panelHeight                 // hidden (below)

                StyledRect {
                    id: card
                    anchors.centerIn: parent
                    implicitWidth: apps.implicitWidth + 2 * Theme.padding.large
                    implicitHeight: panel.dockHeight
                    color: Theme.surfaceContainer
                    border.color: Theme.outlineVariant
                    border.width: 1
                    radius: Theme.radius.large

                    DockApps {
                        id: apps
                        anchors.centerIn: parent
                    }
                    HoverHandler { id: cardHover }
                }
            }

            Bar.PeekState {
                id: peek
                slideTarget: dockSlide
                slideFromY: panel.panelHeight        // hidden below
                slideToY: panel.panelHeight - panel.dockHeight - panel.edgeMargin  // visible
                hotZoneItem: hotZone
                watchedItems: [cardHover]            // keep open while hovering the card
                dwellMs: 600
            }
            Connections {
                target: cardHover
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
```
Note: `watchedItems` expects items with a `.hovered` bool. `cardHover` is a HoverHandler (has `.hovered`). If PeekState reads `watchedItems[i].hovered`, a HoverHandler works. If it needs an Item, wrap: expose `property bool hovered: cardHover.hovered` on `card` and watch `card`. Verify against `PeekState.qml`'s `_maybeExit` (it reads `watchedItems[i].hovered`) — a HoverHandler exposes `hovered`, so passing `cardHover` is valid; if not, watch an Item with a `hovered` alias.

- [ ] **Step 6: Register dock/ if a qmldir is needed**
`modules/dock/` is referenced via relative path or `qs.modules.dock`? Check how `modules/sidebar/` and `modules/bar/` are imported by their consumers (relative `import "sidebar"` vs a qmldir). Match that convention for `modules/dock/` (likely `import "dock"` from Dock.qml, or the components resolve by being in the same dir). Adjust imports in Dock.qml/DockApps.qml accordingly.

- [ ] **Step 7: Add `Dock {}` to the shell entry point** (from Step 1).

- [ ] **Step 8: VERIFY** (VERIFY BLOCK). Then confirm the IPC target + reveal:
```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
qs kill 2>/dev/null; sleep 1; timeout 9 qs -p "$CFG" >/tmp/qs-dock3.log 2>&1 & sleep 5
qs -p "$CFG" ipc show 2>/dev/null | grep -A2 "target dock" && echo "dock IPC OK"
qs kill 2>/dev/null
```
Visually (hard gate is log-clean): hover the bottom edge → dock slides up; pinned + running apps show; left-click cycles/launches; right-click pins (survives restart).

- [ ] **Step 9: Commit**
```bash
cd /home/atqa/dotfiles
git add quickshell/.config/quickshell/modules/Dock.qml quickshell/.config/quickshell/modules/dock/ <shell-entry-file>
git commit -m "add bottom dock: hover-reveal, pinned + running apps"
```

---

## Final review + merge

- [ ] Dispatch a final code-quality reviewer over `git diff master..HEAD`.
- [ ] Full-shell smoke: VERIFY BLOCK; confirm bar at top peeks, dock at bottom reveals, `ipc show` lists `dock`, pin persists across restart.
- [ ] Use superpowers:finishing-a-development-branch (push, PR, merge).
