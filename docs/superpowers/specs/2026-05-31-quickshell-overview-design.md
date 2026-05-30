# Quickshell overview (workspace exposé) — design

Date: 2026-05-31
Status: approved-by-delegation (decisions via user Q&A; autonomous build).
Parent: `2026-05-30-quickshell-visual-redesign-design.md` (sub-project 4 of 5).

## Goal

A workspace exposé: a fullscreen overlay showing a grid of workspaces, each
painting its windows as **live thumbnails** at their **real scaled geometry**
(a mini-map of the desktop). Click a workspace to switch, click a window to
focus, middle-click to close, drag a window onto another workspace to move it.
Triggered by a Super-key bind + IPC. Matches end-4's overview minus the search
widget (we already have a Launcher).

## Decisions (user-confirmed)

- **Live thumbnails** via `ScreencopyView` (confirmed installed:
  `Quickshell/Wayland/_Screencopy`). Icon overlay; icon-only fallback if capture
  is null.
- **Real-geometry mini-map**: windows positioned/sized from `hyprctl` geometry,
  scaled into each workspace cell (end-4's math).
- **In scope v1:** drag window→workspace (move), Super-key trigger (hyprland.conf
  bind), middle-click close window.
- **No search** in overview (Launcher covers it). Pure exposé.

## Architecture

Reference (study, don't copy blindly): `~/repo/dots-hyprland/.../ii/modules/ii/overview/`
(`Overview.qml`, `OverviewWidget.qml`, `OverviewWindow.qml`) +
`.../ii/services/HyprlandData.qml`.

### Linchpin API (verified)
- A Wayland `Toplevel` (from `ToplevelManager.toplevels.values`) exposes
  **`.HyprlandToplevel.address`** — the Hyprland window address. So
  `` `0x${t.HyprlandToplevel?.address}` `` keys a Toplevel into the hyprctl
  client map. The `Toplevel` itself is the `ScreencopyView.captureSource`; the
  hyprctl client gives geometry/workspace. This pairing is the whole design.
- `ScreencopyView` (`import Quickshell.Wayland`): `captureSource: <Toplevel>`,
  `live: true`. Set `captureSource: null` when the overview is closed to stop
  capturing (perf).
- Dispatch (classic syntax, matches `WorkspacesPill`/`WindowPicker`):
  `Hyprland.dispatch("workspace " + id)`,
  `Hyprland.dispatch("focuswindow address:" + addr)`,
  `Hyprland.dispatch("movetoworkspacesilent " + id + ",address:" + addr)`,
  `Hyprland.dispatch("closewindow address:" + addr)`. (`addr` includes the
  `0x` prefix, e.g. `0x55...`.)
- Workspaces: `Hyprland.workspaces.values` (id/active). Monitor-for-screen:
  `Hyprland.monitorFor(screen)` → `HyprlandMonitor` (id/name/activeWorkspace).

### Components (files)

**`services/HyprlandData.qml`** (new singleton; register in `services/qmldir`):
- Parses `hyprctl clients -j` → `windowList` (array) + `windowByAddress` (map
  address→client) + `addresses`. Each client used: `address`, `at` `[x,y]`,
  `size` `[w,h]`, `class`, `title`, `workspace.id`, `monitor`, `xwayland`,
  `floating`, `fullscreen`, `mapped`.
- Parses `hyprctl monitors -j` → `monitors` (array of `{ id, name, x, y, width,
  height, scale, transform, reserved:[l,t,r,b], activeWorkspace }`).
- Refresh: run both Processes on load, and re-run on Hyprland events. Connect to
  `Hyprland.rawEvent` (Quickshell.Hyprland emits this for every Hyprland IPC
  event) → debounced refresh (a short Timer to coalesce bursts). Also expose a
  `refresh()` the overview calls on open. Use the `Todo.qml`-style `Process` +
  `StdioCollector` + `JSON.parse` (try/catch → keep last good).
- Helpers: `clientForToplevel(t)` → `windowByAddress["0x"+t.HyprlandToplevel?.address]`;
  `toplevelsForWorkspace(wsId)` → filter `ToplevelManager.toplevels.values` by
  the client's `workspace.id`.

**`modules/Overview.qml`** (new): root `Scope` + `IpcHandler` (target
`overview`: `toggle()`/`open()`/`close()`) + `Variants` over screens →
fullscreen `PanelWindow`:
- `WlrLayershell.layer: WlrLayer.Overlay`, `keyboardFocus: Exclusive` while open.
- Scrim + enter spring via the established `shown` pattern (the overlays batch:
  `property bool shown`, `onVisibleChanged: shown = visible`, scrim opacity
  `CAnim`, content `scale 0.94→1`/opacity spring). `Keys.onEscapePressed:
  close`. Click scrim → close.
- On open: call `HyprlandData.refresh()`.
- Hosts one `OverviewGrid { screen: modelData }` centered.
- `z: Theme.z.overlay` (or higher) so it's above bar/dock.

**`modules/overview/OverviewGrid.qml`** (new): the per-monitor workspace grid.
- `required property var screen`; `monitor: Hyprland.monitorFor(screen)`;
  `monitorData: HyprlandData.monitors.find(m => m.id === monitor?.id)`.
- Layout constants (local props, no Config system here): `scale: 0.18`,
  `rows: 2`, `columns: 5` (→ workspaces 1–10), `workspaceSpacing: 6`. Comment
  them as the overview's tunables.
- Workspace cells: `Column` of `rows` × `Row` of `columns` `Rectangle`s. Cell
  `implicitWidth = (monitor.width - reserved.l - reserved.r) * scale /
  monitor.scale`, height analogous (account for `transform & 1` swapping w/h —
  see end-4 `OverviewWindow.widthRatio`). Cell color `Theme.surfaceContainerHigh`
  (on the grid's `surfaceContainer` background), rounded (`Theme.radius.normal`,
  outer corners `Theme.radius.large`). Dim workspace-number label behind.
- Active workspace: highlight border `Theme.primary` (the monochrome accent).
- Click a cell's empty area → `Hyprland.dispatch("workspace " + wsId)` + close
  overview.
- Window tiles: a `Repeater` over `ToplevelManager.toplevels.values` filtered to
  this grid's shown workspaces. For each toplevel, resolve `windowData` via
  `HyprlandData.clientForToplevel`; skip if no client (unmapped). Instantiate
  `OverviewWindow { toplevel; windowData; monitorData; scale; ... }`, positioned
  ABSOLUTELY within the grid: `x = (cellWidth + spacing) * col + initX`,
  `y = (cellHeight + spacing) * row + initY` where `row/col` come from the
  window's workspace id and `initX/initY` are the scaled in-cell offsets.
- `DropArea` over each workspace cell for drag-to-move (see OverviewWindow drag).

**`modules/overview/OverviewWindow.qml`** (new): one window tile.
- Props: `toplevel`, `windowData`, `monitorData`, `scale`, `widgetMonitor`
  (the grid's monitor for ratio math).
- Scaling (from end-4): `widthRatio`/`heightRatio` (handle transform & scale),
  `initX/initY = max((windowData.at[i] - monitor.origin[i] - reserved[i]) *
  ratio * scale, 0)`, `targetWidth/Height = windowData.size[i] * scale * ratio`.
  Set `x/y/width/height` from these with `Behavior` (`Theme.anim.emphasized` or
  `standardDecel`) for smooth re-layout.
- `ScreencopyView { captureSource: <overview open> ? toplevel : null; live: true;
  anchors.fill: parent }` + a rounded clip. Icon overlay
  (`Quickshell.iconPath(<resolve class>, "image-missing")` — resolve via
  `DesktopEntries.heuristicLookup(windowData.class)?.icon` then iconPath; or
  reuse a small icon helper). `StateLayer` hover/press tint over the capture.
- Interactions (single MouseArea, `Qt.LeftButton | Qt.MiddleButton`, + a
  `DragHandler`/manual drag):
  - left click (no drag) → `Hyprland.dispatch("focuswindow address:" +
    windowData.address)` + close overview.
  - middle click → `Hyprland.dispatch("closewindow address:" +
    windowData.address)` (HyprlandData refresh will drop the tile).
  - drag → raise z, follow cursor; on release over a workspace cell's DropArea →
    `Hyprland.dispatch("movetoworkspacesilent " + targetWs + ",address:" +
    windowData.address)`; snap back if dropped outside.

**Keybind:** add to `hypr/.config/hypr/hyprland.conf` (near the other
`qs ipc call` binds, ~line 147): `bind = $mainMod, Tab, exec, qs ipc call
overview toggle`. (Verify `$mainMod, Tab` is unbound; `ALT, Tab` is taken by
`windows`. If taken, use `$mainMod, grave`.)

### Styling
- Grid background `Theme.surfaceContainer`; cells `surfaceContainerHigh`; active
  cell border `Theme.primary`. Rounding per Theme. Window tiles: rounded clip,
  `outlineVariant` hairline, `StateLayer` hover/press. Active window (its
  `toplevel.activated`) gets a `Theme.primary` border. Motion through
  `Theme.anim`. App icons render colored (content, like the dock).
- Elevation by tier (no shadow on the black desktop).

## Out of scope (v1)
- Search/launch in overview (Launcher covers it).
- Multi-monitor window filtering nuance beyond per-monitor grids (show each
  monitor's grid; windows on other monitors dimmed or omitted — keep simple:
  show windows whose `monitor` matches the grid, dim others like end-4).
- Workspace paging beyond 10 (fixed 2×5; revisit if user uses >10 workspaces).
- Special/named workspaces, floating-window in-cell drag-reposition (only
  drag-to-another-workspace in v1).

## Success criteria
- `qs` loads clean after each task; `ipc show` lists `overview`.
- Super+Tab toggles the overview; Esc / scrim-click / IPC close it.
- Each workspace cell shows its windows as live thumbnails at scaled real
  positions; active workspace highlighted.
- Click workspace → switch + close; click window → focus + close; middle-click →
  close window; drag window → moves to the dropped workspace.
- `ScreencopyView` stops capturing when closed (captureSource null).
- Styled on the design system; monochrome chrome, colored thumbnails/icons.
- No QML errors; the `toplevel.HyprlandToplevel.address` → hyprctl pairing
  resolves for real windows (no unmatched tiles for mapped windows).
