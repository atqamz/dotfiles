# Quickshell re-skin existing modules — design

Date: 2026-05-30
Status: approved-by-delegation (design language locked in foundation spec;
this scopes application). Pending implementation plan.
Parent: `2026-05-30-quickshell-visual-redesign-design.md` (sub-project 2 of 5).

## Goal

Apply the landed design-system foundation (tokens, motion curves, shared
widgets) to every existing module so the shell visibly matches end-4 polish:
soft-rounded elevated panels, consistent Rubik typography, state feedback on
every interactive surface, spring motion, and zero hardcoded design literals.

The foundation (sub-project 1, merged) changed *tokens and widgets*; this
sub-project changes *consumers*. No new design decisions — only application of
the approved monochrome / soft-rounded / Rubik / end-4-motion language.

## Scope

37 module QML files under `modules/`. Grouped into 5 re-skin batches that map
to implementation tasks:

1. **Bar pills** — `bar/Pill.qml` (base) + ClockPill, LauncherPill, MediaPill,
   ResourcesPill, StatusPill, TrayPill, WorkspacesPill, PeekState, Bar.qml,
   BottomBar.qml.
2. **Sidebar widgets** — QuickSliders, QuickToggles/Tile/Model, CalendarWidget,
   TodoWidget, PomodoroWidget, NotificationList, SidebarRightContent,
   SidebarRight.
3. **Sidebar dialogs** — BluetoothDialog, WiFiDialog, NightLightDialog.
4. **Overlays** — Launcher, Clipboard, EmojiPicker, Cheatsheet, PassMenu,
   WindowPicker, TagInput.
5. **Feedback / status** — Osd, Notifications, NotificationHistory,
   RecordingIndicator, MediaControls, Power.

## Cross-cutting re-skin rules (apply in every batch)

These are the shared structural gaps the audit found. Every batch task applies
the relevant subset.

### R1 — Elevation by surface tier (not drop shadow) on a pure-black desktop
**Correction over the foundation spec's shadow-centric elevation.** The desktop
is `#000000`. A drop shadow is `Theme.shadow` (`#66000000`, semi-transparent
*black*); black-on-black is invisible, so a `StyledShadow` on any surface that
sits directly on the black desktop produces zero visual change. This is exactly
the M3 dark-theme model: **elevation is conveyed by a lighter surface tier and
soft rounding, not by shadows.** Apply that:

- **Top-level panels that sit on the black desktop** (bar pills, sidebar panel,
  all 6 overlay cards, OSD, dialogs, notification cards) read as elevated by
  using a **grey surface tier**, not `Theme.background`. Today many are
  `Theme.background` (`Pill.qml:19`, `SidebarRight.qml` panel) distinguished
  only by a 1px border. Move them to `surfaceContainerLow`/`surfaceContainer`
  (the panel) so the grey-on-black contrast *is* the elevation. Keep soft
  rounding. Keep a faint `outlineVariant` hairline where it sharpens the edge
  (meaningful, not decorative) — bar pills keep their border; it is what reads
  the capsule on black.
- **`StyledShadow` is reserved for NESTED elevation only** — a surface that
  floats over an already-grey surface, so the shadow has a lighter backdrop to
  darken: a dialog over the grey sidebar panel, a hovered/selected list row
  lifting off a grey list, a future menu over a grey panel. There the shadow
  reads. Use `cached: true` for static-size, `cached: false` for size/radius-
  animating targets. Because nested targets that live in a Layout cannot take a
  sibling `StyledShadow` (see `StyledShadow.qml` header — anchors fight the
  Layout), wrap such a target in a plain `Item` and put shadow + rect inside it.
- **Do NOT** blanket-add shadows or reserve `elevation.margin` bleed on the
  black-backdrop top-level panels — there is nothing to clip and nothing to
  show. `elevation.margin` bleed is reserved only where R1 actually places a
  `StyledShadow` (nested cases).

**Explicit tier ladder (mandatory — removes per-subagent guessing).** Subtle
tiers (`#101010`/`#141414` on `#000`) are only ~6-8% luminance, so the tier
*assignment* must be deterministic and give ≥3 readable steps. Today many
surfaces (sidebar panel, all 3 dialog roots, overlay cards) are
`Theme.background` (black) — re-skin moves each to the rung below:

  | layer | surface | tier (Theme) | hex |
  |-------|---------|--------------|-----|
  | desktop backdrop | wallpaper/root | `background` | `#000000` |
  | top-level panel / overlay card / OSD / pill body | sidebar panel, Launcher/Clipboard/Emoji/Cheatsheet/PassMenu/WindowPicker card, OSD, notification card | `surfaceContainer` | `#141414` |
  | card / dialog nested in a panel | the 3 dialog roots (today `background`→ fix), CalendarWidget/TodoWidget/PomodoroWidget/QuickSliders/NotificationList widget surfaces | `surfaceContainerHigh` | `#1a1a1a` |
  | selected / hovered list row inside a card | Bluetooth/WiFi connected rows, launcher current item | `surfaceContainerHighest` | `#202020` |

Net stack `#000 < #141414 < #1a1a1a < #202020` — four readable steps. The 3 dialog
roots (`NightLightDialog.qml:12`, `WiFiDialog.qml:12`, `BluetoothDialog.qml:11`)
are currently `color: Theme.background` (black) — they nest inside the grey
sidebar panel, so leaving them black inverts the elevation. Move them to
`surfaceContainerHigh` (batch 4), then a `StyledShadow` under the dialog (Item-
wrapped per the Layout rule) reads against the panel grey. Pill bodies move off
`Theme.background` to `surfaceContainer` too (`Pill.qml:19`), keeping the
`outlineVariant` hairline. Note: the `shown`/enter mechanism (R4) relies on the
card item persisting (windows toggle `visible`, not `Loader.active`).

### R2 — State feedback on every interactive surface
Any element with a `MouseArea`/`onClicked` (bar pills that act, ListView/
GridView delegates, dialog rows, calendar nav, mode selectors, dismiss/clear
buttons, power buttons) gets a `StateLayer { pressed: <mouseArea>.pressed }`
child. StateLayer already reads `Theme.state.*`. Delegates additionally show a
`Theme.state.focus` (12%) tint when they are the current/selected item, so
keyboard navigation is visible — distinct from hover (8%).

### R3 — Swap raw Qt.Controls onto shared widgets
- **`Slider` → `StyledSlider`**: QuickSliders ×2 (brightness, volume) — the only
  *interactive* sliders re-skinned here. The NightLightDialog temperature slider
  (`NightLightDialog.qml:110-140`) is a raw `Slider` with a **gradient track**
  that visualizes warmth; `StyledSlider` has no gradient hook and the gradient
  is semantic data-viz (see R5). **Leave it a raw `Slider`, normalized to
  tokens** (token rounding/colors/font, bright solid `Theme.primary` focus
  border), gradient kept. Document it as the one non-`StyledSlider` slider.
- ad-hoc toggle Rectangle → `StyledSwitch` (NightLightDialog enable toggle;
  bind `checked: Hyprsunset.active`, `onToggled: Hyprsunset.toggle()`).
- raw `ScrollBar`/unstyled Flickable/ListView scroll → attach
  `ScrollBar.vertical: StyledScrollBar {}` (all 6 overlays, NotificationHistory,
  sidebar lists).
- **display-only** progress Rectangles / rings → `StyledProgressBar`: Osd level
  bar (`Osd.qml:152`), MediaControls position indicator
  (`MediaControls.qml:127-143`, a non-interactive 2-rect fill — NOT a seek
  slider; do not make it seekable). **Range note:** `StyledProgressBar` uses
  `from`/`to`/`value` (`visualPosition`). The Osd volume kind reaches 150, so
  set `to: 150` (or normalize `value` to 0..1) — do not leave the default 0..1
  or the bar clips. MediaControls position: `from:0 to:length value:position`.
- hover affordances that warrant a label → `StyledToolTip` (bar pills).
- TextField: not a foundation widget; keep inline but normalize to tokens
  (Rubik font, `Theme.radius.small`, surface color, and a **bright solid** focus
  border `border.color: activeFocus ? Theme.primary : Theme.outline` — never use
  the `state.focus` opacity as a border color, it composites dimmer than the
  unfocused outline and reads backwards). Do NOT add a new shared widget for it
  (YAGNI — 8 sites, all simple search fields).

### R4 — Scrim fade + panel enter motion on overlays
The 6 overlays + sidebar toggle the whole `PanelWindow` via `visible: root.open`,
so a plain `Behavior on opacity` never plays — when the window appears the
property is already at its final value. Use a deterministic **enter** mechanism,
identical across all overlays:

- Give the scrim and the card a `shown` driver: a local `property bool shown`
  on the PanelWindow, set `false` initially and flipped `true` via
  `onVisibleChanged: if (visible) shown = true; else shown = false`.
- Scrim `opacity: shown ? 1 : 0` with `Behavior on opacity { CAnim { duration:
  Theme.anim.durations.normal } }`.
- Card `opacity: shown ? 1 : 0` and `scale: shown ? 1 : 0.94` with
  `Behavior on scale { Anim { curve: Theme.anim.spring; duration:
  Theme.anim.durations.spring } }` + a matching opacity Behavior. Because the
  card item persists between opens, flipping `shown` on each `visible` re-fires
  the spring — the enter plays every time.
- **Exit animation is OUT OF SCOPE** (decoupling window `visible` from `open`
  to hold the window alive during a close tween is a behavioral change, not a
  re-skin). Close stays instant. Document this per overlay.
- Pills/OSD keep their existing enter/exit but route durations/curves through
  `Theme.anim` (R6).

### R5 — Literal → token migration (mechanical, every file)
Migrate the known hardcoded literals onto tokens. Mapping table:

**font.pixelSize (52 sites)** — map by role, not by raw number:
- **Text** (`StyledText`/`Text`): body/label → `Theme.font.size.normal` (15) or
  `.small` (13) for captions; section titles / dialog headers →
  `.large` (17) / `.larger` (19); largest text numerals →
  `.extraLarge` (22). No text site needs to exceed 22 — the values the audit
  called "hero numerals" (Power 48, MediaControls 40, PomodoroWidget 24) are all
  `MaterialIcon` glyph sizes, not text. Every text `font.pixelSize` maps to a
  rung; no text exception exists.
- **`MaterialIcon` `font.pixelSize`** → `Theme.icon.size.*` (18/22/28/36),
  nearest rung (Osd `28`→`icon.size.large`; TagInput `18`→`icon.size.small`;
  MediaControls `40`→`icon.size.larger` 36; PomodoroWidget `24`→`icon.size.normal`
  22 or `.large` 28 by visual fit). **The single allowed inline exception:**
  Power's action glyph (`Power.qml:141`, `48`) is a deliberate hero size with no
  matching rung — keep an explicit numeric with a `// hero glyph, no rung`
  comment. Every other icon size snaps to a rung. This is the only per-file
  judgement call; it is named here so each batch subagent does the same thing.

**radius (19 sites)**:
- circle/pill shapes where `radius == width/2 == height/2`
  (PomodoroWidget 100/50, CalendarWidget 28/14, TodoWidget 36/18,
  NightLightDialog 20/10 & 16/8) → `Theme.radius.full`.
- slider track `radius: 2` → handled by StyledSlider swap (R3); delete.
- NightLightDialog toggle `48/28/14` → deleted by StyledSwitch swap (R3).
- RecordingIndicator `radius: 6` → `Theme.radius.small`.
- NightLightDialog gradient bar `radius: 2` → `Theme.radius.small`.

**colors (the non-semantic ones)**:
- WorkspacesPill `"#444444"` (inactive dot) → `Theme.textDim`.
- PomodoroWidget `"#ffffff"` (running label) → `Theme.text`.
- QuickToggleTile toggled label `Qt.rgba(0,0,0,0.6)` → keep as-is OR
  `Theme.textOnPrimary` at reduced opacity; it is on-primary (white tile, black
  text) so a literal black-alpha is defensible — implementer may keep it with a
  comment. (Audit flagged it; it is correct, just undocumented.)
- **Keep** NightLightDialog warmth gradient (`#ff8800`→`#ffcc88`→`#ffffff`):
  it visualizes color temperature, a semantic data viz, not chrome. Document.

### R6 — Motion consistency
No raw millisecond literals in animations. RecordingIndicator's `700`ms pulse →
`Theme.anim.durations.spring` (500) or a named local. All `Behavior`/`*Animation`
route `duration` + `easing.bezierCurve` through `Theme.anim`. Color transitions
use `CAnim`; geometry uses `Anim`/`NumberAnimation` with a Theme curve.

## Widget enhancement needed (do first, before batches)

`StyledSlider` currently hardcodes `Theme.primary` for fill+handle. QuickSliders
volume slider must turn `Theme.error` when muted. Add an optional override:

```qml
// StyledSlider.qml
property color fillColor: Theme.primary
// use root.fillColor for the fill Rectangle and handle color
```

Default unchanged (primary), so the brightness slider and any other consumer
keep working. This is a 3-line additive change, no behavior change for existing
callers. It belongs here (re-skin surfaced the need), committed as the first
task so the QuickSliders swap can use it.

## Per-batch acceptance (visual, not just "log clean")

The foundation spec established that "qs log clean" proves *no QML errors*, not
visual completeness. Each batch task's done-definition:

1. `qs -p <config>` launches, log shows `Configuration Loaded`, zero QML/type
   errors (the hard gate — kill the instance after).
2. Every interactive surface in the batch has visible hover + press feedback.
3. No hardcoded `font.pixelSize` numeric literals remain in the batch's files
   except the one documented Power hero-glyph; no hardcoded `radius` numeric
   literals except where a shared widget owns the shape.
4. Panels in the batch read as elevated — grey surface tier on the black
   desktop (R1), soft rounding, hairline where meaningful. `StyledShadow` only
   where a surface nests over a grey surface.
5. Implementer states which files changed and confirms the grep for residual
   literals in those files is clean (or lists the documented exceptions).

## Migration order (dependency-aware)

1. `StyledSlider` `fillColor` enhancement (unblocks QuickSliders).
2. Bar pills (most-visible, contained; proves the tier+tooltip+state pattern on
   a small scope).
3. Sidebar widgets (uses StyledSlider; sets the grey-tier + nested-shadow
   pattern for cards inside the panel).
4. Sidebar dialogs (uses StyledSwitch; dialogs nest over the grey sidebar →
   first real `StyledShadow` use).
5. Overlays (scrim fade + enter spring + delegate state, repeated 6×).
6. Feedback/status (StyledProgressBar, motion cleanup).

Bar first because it is always on screen and contained; overlays later because
the scrim/spring pattern is the most code and benefits from the pattern being
proven on simpler surfaces first.

## Out of scope

- New feature modules (dock, overview, settings) — sub-projects 3/4/5.
- Adding a shared `StyledTextField` (YAGNI; normalize inline).
- Any layout/behavioral change beyond styling — re-skin only. If a module has a
  functional bug, note it, do not fix it here.
- Wallpaper/dynamic theming/AI (excluded project-wide).

## Success criteria

- All 5 batches pass their per-batch acceptance.
- Repo-wide: `grep -rn 'font.pixelSize:\s*[0-9]' modules` returns only
  documented hero-numeral exceptions; `grep -rn 'radius:\s*[0-9]' modules`
  returns only shapes owned by shared widgets or `radius.full` circle math that
  was intentionally left (none expected — all migrate).
- Every overlay fades its scrim and springs its panel on open.
- Every interactive surface shows hover + press state.
- Final whole-shell smoke: open bar, sidebar, each overlay, trigger an OSD and a
  notification — no QML errors, consistent Rubik + rounding + elevation
  throughout.
