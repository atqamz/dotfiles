# Quickshell settings GUI — design

Date: 2026-05-31
Status: approved-by-delegation (decisions via user Q&A; autonomous build).
Parent: `2026-05-30-quickshell-visual-redesign-design.md` (sub-project 5 of 5, final).

## Goal

A settings overlay for the shell: an in-shell panel with a left nav rail and
pages of toggles/sliders/selectors that read **and write** a new persisted
`Config` singleton. Changes apply **live** (modules bind reactively to
`Config.options.*`). Pages: Appearance, Bar, Dock, Overview, Behavior, About.
Triggered by Super+comma + IPC + a sidebar gear button.

**The real work is the prerequisite, not the UI.** The shell currently hardcodes
every tunable as `readonly property`. Sub-project 5 = (1) introduce a mutable,
persisted `Config` singleton, (2) rewire the specific consumers of each exposed
setting to bind to it, (3) build the settings UI on top. Blast radius is bounded
to the settings we choose to expose.

## Decisions (user-confirmed)

- **Scope: Behavior + light Appearance.** Appearance = typography / roundness /
  motion speed only — **NO color picker** (the monochrome design language is
  locked; a color editor would reopen a settled constraint). Pages: Appearance,
  Bar, Dock, Overview, Behavior, About.
- **Config store: FileView + JsonAdapter** (end-4's native pattern — reactive
  two-way binding, debounced persist, `watchChanges` for external edits).
  **Confirmed present in this Quickshell** (0.3.0 / Qt 6.10.3):
  `/usr/lib64/qt6/qml/Quickshell/Io/quickshell-io.qmltypes` exports
  `qs::io::JsonAdapter`/`qs::io::JsonObject` and `FileView` with
  `writeAdapter`/`reload`/`watchChanges`/`adapterUpdated`/`loaded`/`loadFailed`/
  `blockWrites`/`blockLoading`; `FileViewError.FileNotFound` exists. No probe or
  fallback path needed — use it directly.
- **Window model: in-shell overlay** (`PanelWindow` + IPC), matching every other
  module (Launcher/SidebarRight/Overview): scrim, enter-spring, Esc / scrim /
  IPC close. NOT a standalone `ApplicationWindow`.
- **Trigger:** `bind = $mainMod, comma` (verified free) + IPC target `settings`
  (`toggle`/`open`/`close`) + a gear button added to SidebarRight.
- **Live-apply:** settings take effect immediately via reactive bindings — no
  shell reload. This is the whole point of the reactive store.

## Architecture

Reference (study, adapt — do NOT lift verbatim; end-4 uses `Appearance.*`
theming, `RippleButton`, `MaterialSymbol`, and an `ApplicationWindow` we are not
copying): `~/repo/dots-hyprland/dots/.config/quickshell/ii/settings.qml`,
`ii/modules/common/Config.qml`, `ii/modules/common/widgets/{ConfigSwitch,
ConfigSlider,ConfigSelectionArray,ContentPage,ContentSection}.qml`.

### Layer placement (verified)

- `Theme` is `singleton` in `qs.components` (`components/qmldir`); it imports only
  QtQuick. Components see sibling singletons via self-module import (e.g.
  `StyledSwitch.qml` does `import qs.components` and uses `Theme`). Services never
  import components.
- **`Config` is registered in `components/qmldir`** (`singleton Config 1.0
  Config.qml`), co-located with `Theme`. `Theme` reads `Config.options.appearance.*`
  via `import qs.components` (same self-module pattern). **`Config` never imports
  `Theme`** → no cycle. Modules/services read `Config` via their existing
  `import qs.components`.

### 1. `components/Config.qml` (new singleton — the store)

`pragma Singleton` + `pragma ComponentBehavior: Bound`. Structure adapted from
end-4 `Config.qml`:

- `property string filePath`: `Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"`.
  **Must be `~/.local/state/quickshell/`, NOT `~/.config/quickshell/`** — the latter
  is a Stow symlink into this dotfiles git repo (`readlink -f` resolves to
  `/home/atqa/dotfiles/quickshell/.config/quickshell`), so a debounce-written
  runtime file there would land in version control. `~/.local/state/quickshell/`
  is the established home for `dock-pins.json` and `todo.json` — XDG state, outside
  the repo, never tracked. The `FileView`'s `onLoadFailed` path must `mkdir -p` the
  dir before first write (FileView won't create missing parent dirs); do this with a
  tiny `Process` (`bash -c "mkdir -p ~/.local/state/quickshell"`) run in
  `Component.onCompleted` before relying on `writeAdapter()`, matching DockService.
- `property alias options: jsonAdapter` + `property bool ready: false`.
- `FileView { path; watchChanges: true; blockLoading: true; onFileChanged →
  reloadTimer.restart(); onAdapterUpdated → writeTimer.restart(); onLoaded →
  ready = true; onLoadFailed: if FileNotFound → writeAdapter() }` (`blockLoading:
  true` loads config synchronously before windows paint, avoiding a default→real
  reflow flash; writes defaults on first run). Two single-shot debounce `Timer`s
  (~50ms) calling `reload()` / `writeAdapter()` — the debounce is the guard against
  a write→watchChanges→reload re-entry loop.
- `JsonAdapter { id: jsonAdapter ... }` holding the options tree below, each
  group a nested `JsonObject` with **default values inline** (JsonAdapter exposes
  defaults immediately, even before the file loads — so consumers reading
  `Config.options.x` before `ready` get the default, never undefined).
- `function setNestedValue(path, value)` (adapt end-4's — dotted-path traverse +
  JSON.parse type coercion) for programmatic writes; the UI widgets mostly write
  directly (`Config.options.bar.height = v`).

**Options tree (v1 scope):**

```
appearance:
  fontFamily:  "Rubik"     # UI sans family (mono/icon families stay fixed)
  fontScale:   1.0         # 0.85 .. 1.25 — multiplies Theme.font.size.* and icon.size.*
  radiusScale: 1.0         # 0.5  .. 1.5  — multiplies Theme.radius.{small,normal,large,extraLarge}; radius.full stays 9999
  motionScale: 1.0         # 0.5  .. 2.0  — multiplies Theme.anim.durations.* (1=default, <1 faster, >1 slower)
bar:
  height:      28          # px
  clock24h:    true         # HH:mm vs hh:mm AP
  pills:       {}           # bool per pill, keys enumerated in the plan from TopBar.qml (e.g. showClock, showWorkspaces, ...)
dock:
  enable:      true
  height:      60          # px
  iconSize:    36          # px (Theme.icon.size.larger baseline)
  autoHide:    true         # false = always visible (no peek-reveal)
overview:
  scale:       0.18        # 0.10 .. 0.30
  rows:        2           # 1 .. 3
  columns:     5           # 3 .. 8
behavior:
  notifTimeout:    5000    # ms, on-screen notification dwell
  notifMaxVisible: 5       # stacked on-screen notifications
  notifHistoryMax: 50      # history retention
  dndDefault:      false   # do-not-disturb on startup
  nightTemp:       4000    # K, Hyprsunset default temperature
```

### 2. `components/Theme.qml` (modified — Appearance hooks)

Convert the four Appearance-driven token groups from literals to computed
`readonly property` bindings that read `Config.options.appearance.*` (still
`readonly`, just computed). Add `import qs.components` so Theme sees `Config`.

- `font.family.sans: Config.options.appearance.fontFamily` (mono/material fixed).
- `font.size.*`: each `Math.round(<base> * Config.options.appearance.fontScale)`
  (base = current literal: smaller 12 … extraLarge 22).
- `icon.size.*`: same `fontScale` multiplier (keeps icons aligned with text).
- `radius.{small,normal,large,extraLarge}`: each
  `Math.round(<base> * Config.options.appearance.radiusScale)`; **`radius.full`
  stays `9999`** (pill/circle, must not scale).
- `anim.durations.*`: each `Math.round(<base> * Config.options.appearance.motionScale)`
  with a floor (e.g. `Math.max(1, ...)`) so motionScale near 0 never yields 0.
  Anim **curves** (bezier arrays) are unchanged.

Because JsonAdapter serves defaults pre-`ready`, these bindings are safe at load.

### 3. Settings UI

**`modules/Settings.qml`** (new): root `Scope` + `IpcHandler` (target `settings`:
`toggle()`/`open()`/`close()`) + `Variants` over screens → fullscreen
`PanelWindow` — exact same skeleton as `modules/Overview.qml`:
- `WlrLayershell.layer: WlrLayer.Overlay`, `keyboardFocus: Exclusive` while open,
  `ExclusionMode.Ignore`.
- `property bool shown` driven by `onVisibleChanged`; scrim opacity (`CAnim`) +
  card `scale 0.94→1`/opacity spring (established overlay-enter pattern). Exit
  instant (consistent with other overlays — out of scope to animate exit).
- Esc closes (put `Keys.onEscapePressed` on a **focused child Item** with
  `focus: true` + `forceActiveFocus()` on show — NOT on the PanelWindow; the
  PanelWindow-Esc gotcha learned in Overview). Scrim click → close. IPC → close.
- Hosts one centered `SettingsContent`. `z: Theme.z.overlay`.

**`modules/settings/SettingsContent.qml`** (new): the card.
- Fixed size centered (≈ 900×620, clamp to screen), `Theme.surfaceContainer`
  background, `Theme.radius.large` (outer), elevation by tier (no shadow on black).
- Header row: `MaterialIcon` gear + "Settings" title (`Theme.font` / title weight)
  + close button (`MaterialIcon` "close" in a StateLayer'd MouseArea → `requestClose()`).
- Left **nav rail**: a `Column` of `NavButton`s (one per page), `width ≈ 150`,
  background `Theme.surfaceContainer`. Active page highlighted (tier
  `surfaceContainerHigh` + `Theme.primary` left-accent or text). Adapts end-4's
  NavigationRail concept, minus collapse/FAB.
- Content area: a `Loader` (or `StackLayout`) showing the current page; fade/slide
  page-switch via `Theme.anim` (adapt end-4 settings.qml switchAnim, simplified).
  Content scrolls via `StyledScrollBar` if it overflows.
- `property int currentPage`; nav buttons set it.

**`modules/settings/pages/`** (new, one file per page): `AppearancePage.qml`,
`BarPage.qml`, `DockPage.qml`, `OverviewPage.qml`, `BehaviorPage.qml`,
`AboutPage.qml`. Each is a scrolling `Column` of `SettingSection`s. Every control
two-way-binds to `Config.options.*` (`value: Config.options.x` +
`onMoved/onToggled: Config.options.x = v`).
- **About**: shell name, Quickshell/Qt version (static text), the config file path
  (`~/.local/state/quickshell/settings.json`) with a copy-to-clipboard affordance
  (`Quickshell.clipboardText = path`), note that the file is hand-editable and
  `watchChanges` picks edits up live. No reset button in v1 (YAGNI — delete the file
  to restore defaults; document this on the About page).

**`modules/settings/widgets/`** (new, shared setting controls):
- **Two-way binding rule (mandatory):** controls read via a declarative binding
  (`value: Config.options.x`, `checked: Config.options.x`) and write back **only
  from a user-action signal** — `Slider.onMoved`, `Switch.onToggled`,
  `SettingSelect.selected`. **Never** write from `onValueChanged`/`onCheckedChanged`
  (those fire on programmatic/reload changes too → write→reload→write re-entry).
  User-action signals fire only on direct interaction, so the read-binding and the
  write-back never fight.
- `SettingSection.qml`: header label (`Theme.font` title) + a `Column` of rows.
- `SettingSwitch.qml`: row = label + optional icon + `StyledSwitch`. Props
  `label`, `checked` (alias), `onToggled`. Adapts end-4 `ConfigSwitch` to our
  `StyledSwitch` (standard `Switch` API: `checked`).
- `SettingSlider.qml`: row = label + `StyledSlider` + live value readout. Props
  `label`, `from`, `to`, `stepSize`, `value` (alias), `onMoved`, optional
  `suffix`/format. Adapts end-4 `ConfigSlider` to our `StyledSlider` (standard
  `Slider`: `from`/`to`/`value`/`stepSize`).
- `SettingSelect.qml`: segmented button group for enum choices (e.g. clock
  12h/24h). Adapts end-4 `ConfigSelectionArray` (`options:[{label,value}]`,
  `currentValue`, `selected(v)`) with our monochrome styling + StateLayer; tier
  highlight for the selected segment.
- `SettingText.qml`: labeled single-line text field (font family) — reuse the
  existing TextField styling from TodoWidget (focus border `Theme.primary` per the
  re-skin fix), two-way bound.
- `NavButton.qml`: nav-rail entry (icon + label, toggled highlight).

**qmldir + import style (be consistent).** Register `modules/settings/qmldir`
(`module qs.modules.settings`) listing `SettingsContent` + pages, and
`modules/settings/widgets/qmldir` (`module qs.modules.settings.widgets`) listing the
shared controls. `Settings.qml` imports the subdir the way `Overview.qml` does its
own — relative `import "settings"` (Overview uses `import "overview"`). Pages import
the widgets via relative `import "../widgets"` (or the module path
`import qs.modules.settings.widgets` — module-path imports are proven to work, e.g.
`Dock.qml` does `import qs.modules.bar as BarModules`). **Pick relative imports
throughout settings** to match the Overview precedent; do not mix the two styles.

### 4. Consumer rewiring (the prerequisite refactor)

Each exposed setting requires binding its consumer to `Config`. Exact `file:line`
in the plan (inventory already gathered). Summary:

- **Theme.qml** — Appearance hooks (§2). Easy (computed readonly bindings).
- **shell.qml** — **add `Settings {}` to `ShellRoot`** (beside `Overview {}`).
  `modules/` is NOT auto-loaded; every module is hand-instantiated in `shell.qml`.
  Without this the `IpcHandler` never registers and Super+comma is a no-op. This is
  a one-line add but it is load-bearing — call it out as its own step.
- **bar/TopBar.qml** — `pillHeight`/`panelHeight` (`readonly property int`) ←
  `Config.options.bar.height` (still readonly-computed; safe). Also bind the pills'
  `implicitHeight` to track so they don't float in empty space when the strip grows.
  **Per-pill visibility:** the pills are currently positioned by a manual
  `x: prev.x + prev.width + 8` chain plus a `watchedItems`/`Connections` block —
  setting a pill `visible:false` leaves a gap. **Convert the pill container to a
  QtQuick `Row { spacing: <bar spacing> }`** (QtQuick positioners automatically
  exclude `visible:false` children and collapse the gap), replacing the manual
  x-chain. Then each pill's `visible: Config.options.bar.pills.<key>` "just works".
  The plan must read TopBar fully, enumerate the exact pill ids as the `pills` keys,
  and preserve any reveal/peek behavior the x-chain machinery provided (if that
  machinery is essential and can't move to a Row, fall back to gating only pills
  that already guard on `.visible`, e.g. tray/resources, and document the
  limitation). **ClockPill.qml** format (`"HH:mm"` literal) ←
  `Config.options.bar.clock24h ? "HH:mm" : "hh:mm AP"` — trivial reactive bind.
- **modules/Dock.qml** — `dockHeight` ← `dock.height` (easy). **enable:** gate the
  inner `panel.visible` (the dock body is inside `Variants`; do NOT wrap `Variants`
  in a Loader) on `Config.options.dock.enable`. **autoHide false ⇒ always shown:**
  this is NOT a one-liner — it requires forcing the `PeekState` to its revealed
  position (`peek.slideFromY`/`slideToY`) AND overriding the input `mask` Region
  (computed from `peek.fullyHidden`) so the dock stays interactive. Treat as its own
  step. **dock/DockAppButton.qml** — icon size is hardcoded `Theme.icon.size.larger`
  in ~4 sites; route them through `Config.options.dock.iconSize` (thread a prop from
  Dock or read Config directly in DockAppButton — pick one and apply to all sites).
- **modules/overview/OverviewGrid.qml** — `wsScale`/`rows`/`columns`
  (`readonly property`) ← `overview.scale`/`rows`/`columns`. Re-lays-out reactively;
  clean. Keep `rows`/`columns` typed `int`.
- **modules/Notifications.qml** — `maxVisible` (`readonly property int`) ←
  `behavior.notifMaxVisible`; the on-screen dwell fallback literal `5000`
  (`expireTimeout > 0 ? expireTimeout : 5000`) ← `behavior.notifTimeout` (reactive,
  `interval` re-binds). **services/NotificationHistory.qml** — `historyLimit`
  (`readonly property int`) ← `behavior.notifHistoryMax` (clean);
  `doNotDisturb` (mutable `property bool`) — **seed only** from `behavior.dndDefault`
  in `Component.onCompleted` (binding it would fight live toggles elsewhere).
- **services/Hyprsunset.qml** — `temperature` is a plain `property int` that is
  **imperatively reassigned** inside `setTemperature()`; a declarative binding would
  be destroyed on first call AND it is only applied via `execDetached` while
  `active`. **Do NOT bind.** Instead: seed `temperature` from
  `Config.options.behavior.nightTemp` in `Component.onCompleted`, and add a
  `Connections`/handler on the Config value that calls
  `setTemperature(Config.options.behavior.nightTemp)` so a live change re-applies
  when night light is active.
- **modules/SidebarRight.qml** — add a gear button that opens settings (call the
  IPC handler / `qs ipc call settings toggle`) so the sidebar has an entry point.

### 5. Keybind

`hypr/.config/hypr/hyprland.conf`, in the `qs ipc call` block (~line 148, beside
the `overview` bind): `bind = $mainMod, comma, exec, qs ipc call settings toggle`.
`$mainMod, comma` is verified free (`$mainMod CTRL, comma` and `$mainMod, period`
are the only `comma`/`period` binds).

## Out of scope (v1)

- Color / palette editing, wallpaper, dynamic theming (monochrome locked).
- Per-page or global "reset to defaults" button (delete the JSON file instead;
  documented on About).
- Settings for purely-internal values (service poll intervals, etc.) — only
  UX-facing tunables are exposed.
- Standalone `ApplicationWindow`, multi-window, client-side decorations.
- i18n/translation of labels (end-4's `Translation.tr` — we hardcode English).
- Idle/lock timeouts (owned by hypridle, not the shell).

## Success criteria

- `qs` loads clean after each task; `ipc show` lists `settings`.
- Super+comma toggles the overlay; Esc / scrim-click / IPC / sidebar gear all
  open-or-close it.
- `~/.local/state/quickshell/settings.json` is created on first run with defaults,
  is valid JSON, survives a shell restart, reflects UI changes (debounced write),
  and is NOT in `git status` (outside the dotfiles repo).
- Editing the JSON file by hand updates the live UI (`watchChanges`).
- Every exposed setting changes the shell **live**: drag the bar-height slider →
  bar resizes; toggle dock auto-hide → dock pins open; change overview
  rows/columns → grid re-lays-out; change font scale → text rescales; change
  motion scale → animations speed up/slow down; change night-light temp → applies.
- Appearance never exposes color; monochrome chrome preserved.
- No QML errors; controls reflect persisted state on open (bindings, not stale
  snapshots).
