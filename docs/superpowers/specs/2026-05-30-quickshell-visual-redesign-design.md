# Quickshell visual redesign — design system foundation

Date: 2026-05-30
Status: approved (design), pending implementation plan

## Goal

Raise the quickshell shell's visual quality to match end-4 (dots-hyprland)
while keeping our constraints: pure-black background, no dynamic/wallpaper
theming, no AI. Add three new feature modules (dock, overview, settings GUI).

The visual gap with end-4 is not color — we cannot copy their wallpaper-derived
Material You palette and do not want to. The gap is in typography, rounding,
elevation, motion, state feedback, and spacing. All of these are
color-independent, so we can match end-4's polish while staying monochrome.

## Constraints

- Background stays `#000000`. No wallpaper, no matugen, no dynamic theming.
- Accent is monochrome: white/grey only. The two existing bluish tokens
  (`secondary #b9c8da`, `tertiary #9ccbfb`) are neutralized to greyscale.
- `error` and `warning` remain non-grey as the only semantic exceptions
  (battery critical, recording indicator) — readability over purity.
- No AI features (no sidebarLeft, no chat, no booru/translation/etc.).

## Decomposition

This redesign is too large for one spec. Five sub-projects, dependency-ordered.
Each later sub-project gets its own spec → plan → build cycle.

1. **Design-system foundation** (this spec): Theme.qml tokens + shared widgets.
   Everything else depends on it.
2. **Re-skin existing modules**: apply new tokens to bar, sidebar, osd,
   notifications, launcher, cheatsheet, media controls, power, etc. Mechanical.
3. **Dock**: app dock (new feature module).
4. **Overview**: workspace exposé / grid (new feature module).
5. **Settings GUI**: full multi-page settings app, end-4 "waffle" style
   (Appearance, Bar, Behavior, About).

## Design-system foundation (sub-project 1)

### Theme.qml token changes

Reference: `~/repo/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml`.

**Typography**
- UI font family: `Rubik` (proportional sans, matches end-4 `main`).
- Icon font: `Material Symbols Rounded` (replaces `Material Icons` — rounded
  variant is softer, matches the rounded aesthetic).
- Monospace: `JetBrains Mono` retained in tokens but not used by default UI;
  available for any future code/terminal surface.
- Font sizes bumped toward end-4 scale:

  | token | old | new |
  |-------|-----|-----|
  | smaller | 10 | 12 |
  | small | 11 | 13 |
  | normal | 12 | 15 |
  | large | 14 | 17 |
  | larger | 16 | 19 |
  | extraLarge | 20 | 22 |

- Optional weight tokens for variable Rubik: body 450, title 550.

**Color** (anchored to pure black, monochrome)
- `background #000000`, surface tiers unchanged (`#0a0a0a`→`#202020`).
- `primary #ffffff`, `textOnPrimary #000000` (active = white fill, black text).
- Neutralize `secondary` and `tertiary` to neutral greys
  (e.g. `secondary #c0c0c0`, `tertiary #a0a0a0`) — no blue.
- Keep `warning #ffaa44`, `error #ff4444` as semantic exceptions.
- `success` added (grey-green or kept minimal) only if a component needs it.

**Rounding** (soft, end-4 style)

  | token | old | new |
  |-------|-----|-----|
  | small | 4 | 8 |
  | normal | 8 | 16 |
  | large | 12 | 22 |
  | (new) extraLarge | — | 28 |
  | full | 9999 | 9999 |

**Elevation** (new)
- `elevation.margin` (≈10px) reserve for shadow bleed around floating panels.
- Shadow tokens: soft drop shadow, low opacity, moderate blur. Visible even on
  black because it darkens edges and adds spread separation.

**Motion** (adopt end-4 spring curves)
- Add expressive spatial bezier curves with overshoot for element movement.
- Add `clickBounce` curve for press feedback.
- Add enter (decel) / exit (accel) curves for panel show/hide.
- Keep existing duration scale, add longer expressive durations (350/500ms).

**Bar** sizing reviewed during re-skin (sub-project 2), not changed here.

### Shared widgets (components/)

Existing: `StyledRect`, `StyledText`, `MaterialIcon`, `StateLayer`, `Anim`,
`CAnim`.

Add (modeled on end-4 `common/widgets/`):
- `StyledSwitch` — Material toggle switch (replaces ad-hoc switch rectangles in
  NightLightDialog etc.).
- `StyledSlider` — Material slider with track/handle (replaces custom slider
  styling in QuickSliders).
- `StyledShadow` — reusable drop shadow for floating panels.
- `StyledToolTip` — hover tooltip (bar pills, toggle tiles).
- `StyledScrollBar` — themed scrollbar for Flickables/ListViews.
- `StyledProgressBar` — for pomodoro ring / battery / download progress.

Upgrade `StateLayer` to proper Material state layers:
hover overlay ~8% opacity, pressed ~12%, using the layer's `onColor`.

### Migration approach

- Token changes land first (Theme.qml) — visually breaks nothing because
  component code reads tokens by name.
- New/upgraded widgets land next, with no consumers yet.
- Re-skin (sub-project 2) swaps consumers onto new widgets and verifies each
  module visually.

## Dependencies

Add to dotmachines (`hyprland`/fonts role) before re-skin lands:
- `rubik-fonts` (Rubik UI font)
- `google-material-symbols-fonts` or equivalent (Material Symbols Rounded)

File as dotmachines issue if not packaged.

## Out of scope

- Wallpaper, dynamic theming, matugen, any color extraction.
- AI: sidebarLeft, chat, booru, translation, songrec, latex.
- screenCorners (conflicts with sharp solid-black desktop), onScreenKeyboard.
- Re-skin work, dock, overview, settings GUI — separate sub-project specs.

## Success criteria

- `qs log` clean after Theme.qml token changes; no QML errors.
- Rubik + Material Symbols Rounded render in a smoke module.
- New shared widgets instantiate standalone without errors.
- A single re-skinned reference component (e.g. one sidebar tile) visibly
  matches end-4 polish: rounded, proper sans, spring motion, state feedback.
