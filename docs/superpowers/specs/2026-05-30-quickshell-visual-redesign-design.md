# Quickshell visual redesign — design system foundation

Date: 2026-05-30
Status: approved (design), pending implementation plan
Revised: 2026-05-30 after peer review (font facts, migration risk, missing tokens)

## Goal

Raise the quickshell shell's visual quality to match end-4 (dots-hyprland)
while keeping our constraints: pure-black background, no dynamic/wallpaper
theming, no AI. Add three new feature modules (dock, overview, settings GUI).

The visual gap with end-4 is not color — we cannot copy their wallpaper-derived
Material You palette and do not want to. The gap is in typography, rounding,
elevation, motion, state feedback, and spacing. All color-independent, so we can
match end-4's polish while staying monochrome.

## Constraints

- Background stays `#000000`. No wallpaper, no matugen, no dynamic theming.
- Accent is monochrome: white/grey only. The two existing bluish tokens
  (`secondary #b9c8da`, `tertiary #9ccbfb`) are neutralized to greyscale.
- `error` and `warning` remain non-grey as the only semantic exceptions
  (battery critical, recording indicator) — readability over purity.
- No AI features (no sidebarLeft, no chat, no booru/translation/etc.).

## Decomposition

Too large for one spec. Five sub-projects, dependency-ordered. Each later
sub-project gets its own spec → plan → build cycle.

1. **Design-system foundation** (this spec): Theme.qml tokens + shared widgets
   + Anim/CAnim curve refactor. Everything else depends on it.
2. **Re-skin existing modules**: apply new tokens to bar, sidebar, osd,
   notifications, launcher, cheatsheet, media controls, power, etc. Includes
   migrating hardcoded literals onto tokens (see Migration).
3. **Dock**: app dock (new feature module).
4. **Overview**: workspace exposé / grid (new feature module).
5. **Settings GUI**: full multi-page settings app, end-4 "waffle" style
   (Appearance, Bar, Behavior, About).

## Design-system foundation (sub-project 1)

Reference: `~/repo/dots-hyprland/dots/.config/quickshell/ii/modules/common/`
(`Appearance.qml`, `widgets/`).

### Typography

- **UI font: `Rubik`.** Independent choice, not an end-4 match — end-4 uses
  "Google Sans Flex" (Google-internal, not on Google Fonts, not Fedora-
  packaged). Rubik is a rounded, geometric, FOSS sans that suits the soft-
  rounded aesthetic and is Fedora-packaged as `google-rubik-fonts`.
- **Primary change: repoint `Theme.font.family.sans` from `JetBrains Mono`
  → `Rubik`.** Today `sans` is `JetBrains Mono` (Theme.qml:59), so the entire
  UI currently renders monospace — repointing this single token is the
  single most visually impactful change in the foundation.
- **Weights via `font.weight`, not variable axes.** The *Fedora package* is a
  static multi-weight family (no `[wght]` axis) — a variable Rubik build exists
  upstream (Google Fonts / Fontsource) but we target the packaged static faces.
  For static faces use `font.weight: 400` (body) / `600` (title); `font.weight`
  is the correct Qt mechanism for static families. Do NOT use
  `font.variableAxes` (Qt 6.7+; requires a variable font file, no effect on
  static). Note: our `StyledText.qml` currently sets neither — the change is to
  add `font.weight`, not to replace an existing axis.
- **Icon font: `Material Icons Round`** (replaces `Material Icons`).
  Verified installed (`fc-list`). It is the rounded *style variant of the same
  Material Icons project* — identical ligature set to our current font, so all
  46 existing `MaterialIcon` call sites keep working unchanged. This is
  deliberately NOT "Material Symbols Rounded": Symbols is not installed, not
  packaged in Fedora, and renamed/removed ligatures (would break glyphs). We
  forgo the `opsz`/`FILL` axes to get a zero-breakage, zero-new-dep rounded
  icon set.
- **Monospace: `JetBrains Mono`** retained in tokens; not used by default UI.
- **Font size scale** bumped toward end-4 (our rung names are offset from
  end-4's by ~one step; comment the mapping in Theme.qml):

  | token | old | new | ≈ end-4 |
  |-------|-----|-----|---------|
  | smaller | 10 | 12 | smaller 12 |
  | small | 11 | 13 | smallie 13 |
  | normal | 12 | 15 | small 15 |
  | large | 14 | 17 | large 17 |
  | larger | 16 | 19 | larger 19 |
  | extraLarge | 20 | 22 | huge 22 |

- **Icon size scale (new)** — replaces the 10 hardcoded `MaterialIcon`
  pixelSizes: `small 18`, `normal 22`, `large 28`, `larger 36`.

### Color (pure black, monochrome)

- `background #000000`; surface tiers unchanged (`#0a0a0a`→`#202020`).
- `primary #ffffff`, `textOnPrimary #000000` (active = white fill, black text).
- Neutralize `secondary`→`#c0c0c0`, `tertiary`→`#a0a0a0` (no blue).
  **Prerequisite task:** grep current `secondary`/`tertiary` consumers to
  confirm none relied on blue as an info/link *signal* before flattening.
- Keep `warning #ffaa44`, `error #ff4444` as semantic exceptions.
- **No `success` token** — monochrome; convey success via icon/text, not hue.
- **Surface-state ladder (new)** — the foundation must define hover/active/
  disabled surface tints and a disabled-text opacity, since re-skin + dock +
  overview all need them and end-4 derives a full ladder. Concretely add, per
  surface tier used interactively: `*Hover` (≈ +6% white overlay), `*Active`
  (≈ +12%), `*Disabled` (surface mixed 40% toward background), and
  `textDisabled` (text at 38% opacity). Keep these as named tokens, not
  per-call literals.
- **Distinct focus value (M3).** State-layer opacities: hover 8%, focus **12%**,
  pressed 12%, dragged 16%. Keyboard focus is in scope (focus-grab convention
  below), so `focus` is a separate 12% token — do not reuse the 8% hover value,
  or focused and hovered elements look identical.

### Rounding (soft, end-4 style)

  | token | old | new | ≈ end-4 |
  |-------|-----|-----|---------|
  | small | 4 | 8 | verysmall 8 |
  | normal | 8 | 16 | normal 17 |
  | large | 12 | 22 | large 23 |
  | (new) extraLarge | — | 28 | verylarge 30 |
  | full | 9999 | 9999 | full |

### Elevation & z-order (new)

- `elevation.margin` (≈10px, matches end-4 `elevationMargin`) — reserved bleed
  around floating panels for shadow.
- **Shadow via `RectangularShadow`** (QtQuick.Effects, Qt 6.9+; we run 6.10.3)
  — SDF-based, newer and cheaper than Qt5Compat `DropShadow`; model on end-4
  `StyledRectangularShadow`. Soft, low opacity, moderate blur; visible on black
  by darkening/spreading edges. Use `cached: true` for static panels;
  `cached: false` for panels that animate size/radius (spring-resizing sidebar,
  overview) to avoid stale/thrashed cached textures.
- **Z-order scale (new)** — named layers so dock/overview/settings/osd don't
  fight: `z.base 0`, `z.panel 10`, `z.overlay 20`, `z.popup 30`, `z.osd 40`.
- **Focus-grab convention** — document that fullscreen-scrim modules
  (launcher, overview, settings, sidebar) use `WlrLayershell` keyboard focus
  `Exclusive` while open and release on close; pills/OSD never grab focus.

### Motion (adopt end-4 spring curves)

- Add expressive spatial bezier curves with overshoot for element movement,
  a `clickBounce` press curve, and enter (decel) / exit (accel) curves.
- **Anim.qml / CAnim.qml refactor (required):** current code hardcodes a
  4-element curve padded to 6 (`[..[0..3], 1, 1]`), which cannot express
  overshoot (control-point y > 1) or end-4's 12-element multi-segment
  `emphasized`. Refactor both to consume full-length curve arrays from Theme so
  the new springs actually apply. Without this the motion tokens are inert.
- Keep existing durations; add longer expressive durations (350/500ms).

### Shared widgets (components/)

Existing: `StyledRect`, `StyledText`, `MaterialIcon`, `StateLayer`, `Anim`,
`CAnim`.

Add (modeled on end-4 `common/widgets/`):
- `StyledSwitch` — Material toggle (replaces ad-hoc switch rects, e.g.
  NightLightDialog).
- `StyledSlider` — Material slider (replaces custom slider styling in
  QuickSliders).
- `StyledShadow` — wraps `RectangularShadow` (see Elevation).
- `StyledToolTip` — hover tooltip (bar pills, toggle tiles).
- `StyledScrollBar` — themed scrollbar for Flickables/ListViews.
- `StyledProgressBar` — pomodoro ring / battery / download progress.

Upgrade `StateLayer`: read overlay opacities from new Theme tokens
(deliberate values: hover 8%, pressed 12% — a deliberate change from the
current hardcoded 16% pressed, toward M3), not `Qt.rgba` literals.

### Migration approach (honest)

- Token changes (Theme.qml) land first. **This is NOT visually transparent:**
  ~45% of module `font.pixelSize` (53 occurrences) and ~24% of `radius`
  (19 occurrences) are hardcoded literals that bypass Theme. When tokens jump,
  token-reading surfaces grow/round immediately while literal surfaces stay
  put → transient half-migrated look until re-skin. Known desync hotspots:
  `MediaControls.qml`, `ResourcesPill.qml`, `PomodoroWidget.qml`,
  `CalendarWidget.qml`.
- New/upgraded widgets land next, no consumers yet (safe).
- **Re-skin (sub-project 2)** swaps consumers onto new widgets AND migrates the
  53 + 19 hardcoded literals onto tokens, verifying each module visually.
- Therefore the "qs log clean" gate proves only *no QML errors*, not visual
  completeness. Visual acceptance is per-module in sub-project 2.

## Dependencies

- `google-rubik-fonts` (Rubik UI font) — Fedora-packaged, add to dotmachines
  fonts/hyprland role before re-skin lands.
- Icon font: **no new dependency** — `Material Icons Round` already installed.

## Out of scope

- Wallpaper, dynamic theming, matugen, color extraction.
- AI: sidebarLeft, chat, booru, translation, songrec, latex.
- screenCorners (conflicts with sharp solid-black desktop), onScreenKeyboard.
- `opsz`/`FILL` icon axes (Material Symbols only; we use Material Icons Round).
- Re-skin, dock, overview, settings GUI — separate sub-project specs.

## Success criteria

- `qs log` clean after Theme.qml token changes; no QML errors. (Proves no
  breakage; does NOT prove visual completeness — see Migration.)
- Rubik renders (after dep lands); `Material Icons Round` glyphs render for all
  46 existing call sites with no missing-glyph boxes.
- New shared widgets instantiate standalone without errors.
- Anim/CAnim apply an overshoot curve without clamping (visible spring).
- One re-skinned reference component (e.g. a sidebar tile) visibly matches
  end-4 polish: rounded, Rubik, spring motion, state feedback.
