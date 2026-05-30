# Quickshell dock — design

Date: 2026-05-31
Status: approved-by-delegation (decisions made with user via Q&A; autonomous
build per standing directive). Pending implementation plan.
Parent: `2026-05-30-quickshell-visual-redesign-design.md` (sub-project 3 of 5).

## Goal

Add an app dock: a bottom-center, auto-hiding (hover-reveal) panel showing
pinned favorites + running apps, click to focus/cycle/launch. Matches end-4's
dock behavior, styled on our design system (monochrome chrome, grey-tier
elevation, spring motion). Prerequisite: relocate the existing bar from the
bottom edge to the top edge to free the bottom for the dock.

## Decisions (user-confirmed)

- **Bar moves bottom → top.** Frees the bottom edge. Bar keeps its current
  content, peek-on-hover behavior, and styling — only the edge/direction flip.
- **Dock position:** bottom-center, horizontal, content-width.
- **Visibility:** auto-hide, reveal on bottom-edge hover (same peek FSM the bar
  uses). No always-on, no pin toggle in v1 (YAGNI — can add later).
- **Contents:** pinned favorites + running apps, grouped by app, separator
  between pinned and running-only entries (end-4 model).
- **App icons render in their real (colored) form** — they are content/data,
  not chrome, like media artwork. A monochrome-desaturate option is out of scope
  for v1 (documented exception to the monochrome-accent rule).

## Architecture

Reference: `~/repo/dots-hyprland/.../ii/modules/dock/` (Dock, DockApps,
DockAppButton, DockButton, DockSeparator) + `TaskbarApps` singleton.

Confirmed Quickshell APIs (this install, 0.3.0 — exact forms, use verbatim):
- **`Quickshell.Wayland` `ToplevelManager`** — a SINGLETON (use
  `ToplevelManager.toplevels` directly, do NOT instantiate). `.toplevels` is an
  `UntypedObjectModel`: bind it directly as a `model:`, but for any JS
  `.filter`/`.map`/`.length`/grouping use **`ToplevelManager.toplevels.values`**
  (JS array). `.activeToplevel` for the focused window. Each `Toplevel`:
  `appId`, `title`, `activated`, `maximized`/`minimized`/`fullscreen`; methods
  `activate()`, `close()`; signal `closed`. Reactive — no `hyprctl` polling.
- **`DesktopEntries`** (singleton) — `DesktopEntries.applications.values` (also
  an `UntypedObjectModel`), `DesktopEntries.byId(id) -> DesktopEntry|null`,
  `DesktopEntries.heuristicLookup(name) -> DesktopEntry|null`. `DesktopEntry`
  exposes `.icon` (theme icon name, may be empty), `.name`, `.id`,
  `.execute()`.
- **`Quickshell.iconPath(name, fallback)`** — resolves a theme icon name to a
  file path; returns `""` if unresolved and no usable fallback.
- **Persistence: match `services/Todo.qml` (the repo's established pattern).**
  Read via `Process { command: ["cat", storePath] }` + `StdioCollector` →
  `JSON.parse`; write via `Process { command: ["bash","-c","mkdir -p
  ~/.local/state/quickshell && cat > " + storePath] }` with
  `stdinEnabled`/`write`/`closeStdin`. `storePath = Quickshell.env("HOME") +
  "/.local/state/quickshell/dock-pins.json"`. Do NOT use `FileView`/
  `JsonAdapter` — not used anywhere in this repo.

### Components (files)

**Bar relocation:**
- `modules/bar/BottomBar.qml` → **rename to `TopBar.qml`**: flip `anchors`
  `bottom`→`top`; hotZone `anchors.top: parent.top`. Corrected geometry (the
  bottom version's `y: panelHeight` hidden / `visibleY` visible inverts; do NOT
  copy it):
  - `PeekState { slideFromY: -panel.panelHeight; slideToY: panel.edgeMargin }`
    — hidden parks the pillRow fully ABOVE the strip (`-panelHeight`, NOT
    `-pillHeight`, or `edgeMargin+2`px of pill still pokes through); visible
    sits `edgeMargin` below the top edge.
  - pillRow initial `y: panel.slideFromY` (i.e. `-panelHeight`).
  - mask flips to reveal the TOP strip when hidden:
    `Region { x:0; width: panel.width; y: 0;
      height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight }`
    (the bottom version used `y: panelHeight - hotZoneHeight` — wrong for top;
    must be `y: 0`, else the hotzone is unclickable and reveal is dead).
  - `PeekState` is already edge-agnostic ("TopBar / BottomBar") — reuse
    unchanged; it just consumes the new slideFrom/slideTo.
- `modules/Bar.qml`: update the `Variants` delegate reference `BottomBar` →
  `TopBar`.
- `modules/bar/PeekState.qml`: no change (already edge-agnostic; caller supplies
  slideFrom/slideTo).

**Dock data layer:**
- `services/DockService.qml` (new singleton): file starts with
  `pragma Singleton`, root is `Singleton { }`, registered in `services/qmldir`
  as `singleton DockService 1.0 DockService.qml` (per `Todo.qml`). It may hold
  child objects (the persistence `Process` pair, `Connections` on
  ToplevelManager) — singletons in Quickshell host child objects fine. The
  dock's app model, mirroring end-4 `TaskbarApps`:
  - Reads persisted `pinnedApps` (JSON array of desktop ids) on load via the
    Todo persistence pattern above; writes on pin/unpin.
  - Builds an ordered list of `DockEntry` objects: each pinned app first (with
    its matching toplevels, possibly empty), a separator marker, then
    running-only apps (toplevels whose resolved id isn't pinned), grouped by the
    RESOLVED desktop id (group on the resolved id, not raw appId, so two windows
    of the same app don't split).
  - Exposes `entries` (list), `pin(id)`, `unpin(id)`, `isPinned(id)`.
  - Each entry: `{ id, name, iconPath, toplevels: [Toplevel], pinned: bool }`.
  - **appId → DesktopEntry resolution order:** `DesktopEntries.byId(appId)` →
    `DesktopEntries.byId(appId.toLowerCase())` → `DesktopEntries.heuristicLookup(appId)`
    → null. If resolved: `name = entry.name`, `icon = entry.icon`. If null:
    `name = appId`, `icon = ""`.
  - **Icon path:** `iconPath = Quickshell.iconPath(icon, "application-x-executable")`
    where `icon` is the resolved (possibly empty) name. The `DockAppButton`
    `Image` additionally guards `status === Image.Error` / empty source → show a
    fallback `MaterialIcon` glyph (e.g. "terminal"/"window"), so an unresolved
    icon never renders a broken-image box.

**Dock UI:**
- `modules/Dock.qml` (new): root `Scope` + `Variants` over screens →
  `PanelWindow` per screen, bottom-anchored, `WlrLayer.Top`,
  `ExclusionMode.Ignore` (overlay, no reserved space — matches the bar's
  hover-peek model). Hosts the hotzone + the dock card + a `PeekState` reused
  from the bar for bottom-edge reveal. An `IpcHandler` (target `dock`) with
  `toggle()` for optional manual reveal.
- `modules/dock/DockApps.qml` (new): the horizontal `Row`/`ListView` of app
  buttons built from `DockService.entries`, with `DockSeparator` between pinned
  and running sections.
- `modules/dock/DockAppButton.qml` (new): one app — icon `Image`
  (`iconPath`) with the `Image.Error`/empty fallback glyph above, running
  indicator (a small dot/underline when `toplevels.length > 0`), active
  highlight (when any toplevel `activated`), and
  `StateLayer { pressed: <mouseArea>.pressed; focused: <anyActivated> }` (both
  are plain bools — must be bound, no shorthand), `StyledToolTip { text: name;
  visible: <ma>.containsMouse }`. Interactions:
  - **left click:** if running → cycle/activate next toplevel
    (`activate()`); if not running → launch (`DesktopEntry.execute()`).
  - **middle click:** launch a new instance (`execute()`).
  - **right click:** toggle pin (`DockService.pin/unpin`).
- `modules/dock/DockSeparator.qml` (new): a thin `outlineVariant` vertical
  divider between pinned and running groups.

### Styling (design system)

- Dock card: `Theme.surfaceContainer` grey tier on the black desktop (elevation
  by tier, no shadow — same as overlays), `Theme.radius.large`/`extraLarge`
  rounding, `outlineVariant` hairline. `Theme.elevation.margin` reserved bleed
  is unnecessary (no shadow).
- App buttons: ~`Theme.icon.size.larger` (36) icons in a square hit target with
  `Theme.radius.normal`, `StateLayer { pressed; focused: <activated> }`.
- Running indicator + active highlight: monochrome (white dot / white-tint
  state), per the monochrome rule. App icons themselves stay colored (content).
- Motion (curve and duration are SEPARATE — always pair them):
  reveal/hide via the bar's `PeekState` (slide). App launch/press: a subtle
  bounce `Anim { curve: Theme.anim.clickBounce; duration:
  Theme.anim.durations.normal }` on the button scale. Dock width changes on app
  add/remove: needs an explicit `Behavior on implicitWidth { Anim { curve:
  Theme.anim.springFast; duration: Theme.anim.durations.springFast } }` on the
  Row/card (content-width does NOT animate for free). Color → `CAnim`.

### Multi-monitor

Per-screen `Variants` (like the bar). Each dock independent. Running-app
filtering by screen is OUT OF SCOPE for v1 — show all toplevels on every
screen's dock (simpler; revisit if it annoys). Document.

## Out of scope (v1)

- Pin toggle / always-on mode (auto-hide only).
- Live window thumbnails / preview popups (end-4's ScreencopyView) — icons only.
- Per-monitor app filtering.
- Monochrome/desaturated app icons.
- Drag-to-reorder pinned apps.
- Dock on any edge other than bottom.

## Success criteria

- `qs` loads clean (`Configuration Loaded`, zero QML/type errors) after each
  task. `qs ipc show` lists target `dock`.
- Bar renders at the TOP edge, peeks on top-edge hover, all pills work, styling
  unchanged from the re-skin.
- Dock reveals on bottom-edge hover, hides on dwell-out (same feel as the bar).
- Pinned apps show always; running apps appear/disappear as windows open/close
  (ToplevelManager reactive); a separator divides them.
- Left-click cycles/activates a running app or launches a pinned one; middle
  launches a new instance; right toggles pin (persisted across `qs` restart).
- Running indicator + active highlight render; app icons render (real colored
  icons via DesktopEntries/iconPath), no missing-icon boxes for common apps.
- Dock styled on the design system: grey tier, rounding, StateLayer, spring
  reveal. Monochrome chrome; colored app icons the only color (documented).
