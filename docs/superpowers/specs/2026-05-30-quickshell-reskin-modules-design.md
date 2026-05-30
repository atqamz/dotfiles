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

### R1 — Elevation on floating surfaces
Every panel that floats over content (bar pills, sidebar panel, all 6 overlay
cards, OSD, notification cards, dialogs) gets a `StyledShadow` sibling placed
before the panel rect, `target:` the rect. Keep `cached: true` for
static-size panels; `cached: false` for panels that animate size/radius
(sidebar, overview later, any spring-resizing rect). Reserve `Theme.elevation.margin`
bleed in the parent so the shadow is not clipped. Replace decorative hard 1px
borders with shadow elevation; keep a border only where it carries meaning
(e.g. a faint `outlineVariant` hairline on the sidebar panel edge is fine).

### R2 — State feedback on every interactive surface
Any element with a `MouseArea`/`onClicked` (bar pills that act, ListView/
GridView delegates, dialog rows, calendar nav, mode selectors, dismiss/clear
buttons, power buttons) gets a `StateLayer { pressed: <mouseArea>.pressed }`
child. StateLayer already reads `Theme.state.*`. Delegates additionally show a
`Theme.state.focus` (12%) tint when they are the current/selected item, so
keyboard navigation is visible — distinct from hover (8%).

### R3 — Swap raw Qt.Controls onto shared widgets
- `Slider` → `StyledSlider` (QuickSliders ×2; MediaControls seek bar).
- ad-hoc toggle Rectangle → `StyledSwitch` (NightLightDialog).
- raw `ScrollBar`/unstyled Flickable/ListView scroll → attach `StyledScrollBar`
  (all 6 overlays, NotificationHistory, sidebar lists).
- custom progress Rectangle / ring → `StyledProgressBar` (Osd level bar,
  MediaControls position, download/battery progress where present).
- hover affordances that warrant a label → `StyledToolTip` (bar pills).
- TextField: not a foundation widget; keep inline but normalize to tokens
  (Rubik via StyledText-equivalent font, `Theme.radius.small`, surface color,
  `Theme.state.focus` border on `activeFocus`). Do NOT add a new shared widget
  for it in this sub-project (YAGNI — 8 sites, all simple search fields).

### R4 — Scrim fade + panel motion on overlays
The 6 overlays + sidebar set `color: Theme.scrim` instantly. Add
`Behavior on opacity { CAnim {} }` (or a fade via a `states`/`Loader.opacity`)
so the scrim fades in/out over `Theme.anim.durations.normal`. The panel card
itself enters with a spring (`Theme.anim.spring`) on scale/opacity — model on
end-4's overlay open. Closing reverses. Pills/OSD keep their existing
enter/exit but route durations/curves through `Theme.anim`.

### R5 — Literal → token migration (mechanical, every file)
Migrate the known hardcoded literals onto tokens. Mapping table:

**font.pixelSize (52 sites)** — map by role, not by raw number:
- body/label text → `Theme.font.size.normal` (15) or `.small` (13) for captions.
- section titles / dialog headers → `Theme.font.size.large` (17) /
  `.larger` (19).
- big numerals (Power `48`, MediaControls `40`, PomodoroWidget `24`) →
  `Theme.font.size.extraLarge` (22) is too small for hero numerals; these are
  legitimately large display text — keep as explicit large sizes but pull from
  a local `readonly property int` at top of the file with a comment, OR accept
  they exceed the scale (hero numerals are an intentional exception, like
  `warning`/`error` colors). Implementer picks per-site; document the choice.
- MaterialIcon `font.pixelSize` → `Theme.icon.size.*` (18/22/28/36), nearest
  rung. (e.g. Osd `28`→`icon.size.large`; TagInput `18`→`icon.size.small`.)

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
   except documented hero-numeral exceptions; no hardcoded `radius` numeric
   literals except where a shared widget owns the shape.
4. Floating panels in the batch cast a shadow.
5. Implementer states which files changed and confirms the grep for residual
   literals in those files is clean (or lists the documented exceptions).

## Migration order (dependency-aware)

1. `StyledSlider` `fillColor` enhancement (unblocks QuickSliders).
2. Bar pills (most-visible, smallest surfaces, proves the shadow+tooltip+state
   pattern on a contained scope).
3. Sidebar widgets (uses StyledSlider, sets the panel-shadow pattern).
4. Sidebar dialogs (uses StyledSwitch).
5. Overlays (scrim fade + spring + delegate state, repeated 6×).
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
