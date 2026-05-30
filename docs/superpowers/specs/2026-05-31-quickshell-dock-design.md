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

Confirmed Quickshell APIs (this install, 0.3.0):
- **`Quickshell.Wayland` `ToplevelManager`** — `.toplevels` (reactive list),
  `.activeToplevel`; each `Toplevel` has `appId`, `title`, `activated`,
  `maximized`; methods `activate()`, `close()`; signal `closed`. Use this for
  running apps — reactive, no `hyprctl` polling (the WindowPicker's approach).
- **`DesktopEntries`** — `.applications`, heuristic lookup by id/name; each
  `DesktopEntry` exposes `.icon` (theme icon name), `.name`, `.execute()`.
- **`Quickshell.iconPath(name, fallback)`** — resolves a theme icon name to a
  file path for an `Image`.
- **`Quickshell.Io`** (`FileView`) — for pinned-app persistence.

### Components (files)

**Bar relocation:**
- `modules/bar/BottomBar.qml` → **rename to `TopBar.qml`**: flip `anchors`
  `bottom`→`top`; hotZone anchored top; pillRow slides from above
  (`y: -pillHeight` hidden) down to `edgeMargin` visible; mask reveals the top
  hotzone strip when hidden. Recompute `visibleY`/slide offsets for the top
  edge. `PeekState` is already generic ("TopBar / BottomBar") — reuse unchanged.
- `modules/Bar.qml`: update the `Variants` delegate reference `BottomBar` →
  `TopBar`.
- `modules/bar/PeekState.qml`: no change (already edge-agnostic; caller supplies
  slideFrom/slideTo).

**Dock data layer:**
- `services/DockService.qml` (new singleton, `pragma Singleton` + qmldir entry):
  the dock's app model. Mirrors end-4 `TaskbarApps`:
  - Reads persisted `pinnedApps` (array of desktop ids) from a state file.
  - Builds an ordered list of `DockEntry` objects: each pinned app first (with
    its matching toplevels, possibly empty), a separator marker, then
    running-only apps (toplevels whose appId isn't pinned), grouped by appId.
  - Exposes `entries` (list), `pin(id)`, `unpin(id)`, `isPinned(id)`.
  - Each entry: `{ id, name, iconPath, toplevels: [Toplevel], pinned: bool }`.
  - Icon: `DesktopEntries` heuristic lookup on `appId` → `.icon` →
    `Quickshell.iconPath(icon, "application-x-executable")`. Fallback to a
    generic glyph if unresolved.
  - appId→desktop matching: try exact id, then lowercase, then
    `DesktopEntries` heuristic (handles `org.foo.Bar` ↔ `foo`). Document the
    matching order; imperfect matches fall back to the raw appId as the name.
- `services/DockPins.qml` OR fold into DockService: persistence via `FileView`
  on `~/.local/state/quickshell/dock-pins.json` (or
  `$XDG_STATE_HOME`). Read on load, write on pin/unpin. JSON array of ids.
  (Keep persistence isolated so the model logic stays testable/clear.)

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
  (`iconPath`), running indicator (a small dot/underline when `toplevels.length
  > 0`), active highlight (when any toplevel `activated`), `StateLayer` for
  hover/press, `StyledToolTip` with the app name. Interactions:
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
- Motion: reveal/hide via the bar's `PeekState` (slide), durations/curves
  through `Theme.anim`. App launch/open: a subtle `clickBounce`
  (`Theme.anim.clickBounce`) on the button. Width changes on app
  add/remove animate via `Theme.anim.springFast`.

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
