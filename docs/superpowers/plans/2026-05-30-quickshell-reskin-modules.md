# Quickshell re-skin existing modules — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Apply the landed design-system foundation (tokens, motion curves, shared widgets) to all 37 existing module QML files so the shell matches end-4 polish: grey-tier elevation on the black desktop, Rubik typography, state feedback on every interactive surface, spring enter motion, zero hardcoded design literals.

**Architecture:** Re-skin only — no behavioral/layout changes. Consumers move onto Theme tokens and shared widgets. Elevation is conveyed by surface tier (M3 dark model), not shadows, because the desktop is pure black. Work proceeds in dependency order: a 3-line widget enhancement first, then 6 module batches.

**Tech Stack:** Quickshell 0.3.0 / Qt 6.10.3 QML. No offline QML validator — validation = launch `qs`, grep log for `Configuration Loaded` + errors, then kill.

**Spec:** `docs/superpowers/specs/2026-05-30-quickshell-reskin-modules-design.md` (read the cross-cutting rules R1-R6 and the tier ladder; this plan operationalizes them).

---

## RE-SKIN RECIPE (shared transformations — referenced by every task)

Each task says which recipe items apply to which file/lines. Implementer reads the file, applies, verifies.

### Recipe A — Surface tier (R1)
Replace `color: Theme.background` (black) on an elevated surface with its rung from the ladder:
- top-level panel / overlay card / OSD / pill body → `Theme.surfaceContainer`
- card / dialog nested in a panel → `Theme.surfaceContainerHigh`
- selected / hovered list row inside a card → `Theme.surfaceContainerHighest`

Keep a `border.color: Theme.outlineVariant; border.width: 1` hairline only where it sharpens the edge (pill capsules, panel edge). Drop borders that were faking elevation elsewhere.

### Recipe B — StateLayer on interactive surfaces (R2)
Any element with a `MouseArea`/`onClicked`/`TapHandler` gets a `StateLayer` child that clips to the surface radius. Pattern:

```qml
Rectangle {
    id: row
    radius: Theme.radius.small
    // ...content...
    MouseArea { id: ma; anchors.fill: parent; onClicked: doThing() }
    StateLayer { pressed: ma.pressed }   // reads Theme.state.* automatically
}
```

`StateLayer` (already built) exposes `hovered` (auto via its own HoverHandler), `pressed` (wire from a MouseArea), `focused`, and `tint`. Its color picks pressed > focused > hovered > transparent at `Theme.state.*` opacities, with a `CAnim` Behavior. So you only wire `pressed`, and for delegates the current-item tint maps directly to `focused`:

```qml
StateLayer {
    pressed: ma.pressed
    focused: ListView.isCurrentItem    // GridView.isCurrentItem for grids
}
```

No fallback Rectangle needed — `focused` already renders the 12% tint, distinct from the 8% hover.

### Recipe C — Literal → token (R5)
- text `font.pixelSize: N` → `Theme.font.size.{smaller12,small13,normal15,large17,larger19,extraLarge22}` by role (body→normal, caption→small, header→large/larger, big text→extraLarge).
- `MaterialIcon` `font.pixelSize: N` → `Theme.icon.size.{small18,normal22,large28,larger36}` nearest rung. **Only inline exception:** `Power.qml:141` `48` → keep `48` with `// hero glyph, no rung`.
- circle/pill `radius: N` where `N == width/2 == height/2` → `Theme.radius.full`.
- other `radius: N` → nearest of `Theme.radius.{small8,normal16,large22,extraLarge28}`.
- colors: `"#444444"`→`Theme.textDim`; `"#ffffff"`→`Theme.text`; keep documented semantic literals (NightLight warmth gradient, QuickToggleTile on-primary `Qt.rgba(0,0,0,0.6)` with a comment).

### Recipe D — Scrim fade + card enter spring (R4, overlays only)
On each overlay's `PanelWindow` (toggled by `visible: root.open`):

```qml
PanelWindow {
    id: win
    visible: root.open
    property bool shown: false
    onVisibleChanged: shown = visible

    Rectangle {                       // scrim
        anchors.fill: parent
        color: Theme.scrim
        opacity: win.shown ? 1 : 0
        Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
    }

    Rectangle {                       // the card
        id: card
        // ...existing anchors/size...
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.94
        Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
        Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }
    }
}
```

Exit is instant (window hides) — OUT OF SCOPE, leave a `// exit animation out of scope (re-skin)` comment. Relies on the card item persisting (visible-toggled, not `Loader.active`-toggled); if a module uses `Loader { active: root.open }` for the card, drive `shown` off the Loader's `onLoaded`/keep the window visible instead — note it.

### Recipe E — Widget swaps (R3)
- raw `Slider` → `StyledSlider` (keep `from/to/value/onMoved`; set `fillColor:` where color must vary, e.g. muted→error).
- ad-hoc toggle Rectangle → `StyledSwitch { checked: <bind>; onToggled: <action>() }`.
- display-only progress Rectangles → `StyledProgressBar { from; to; value }` (set `to` to the real max — Osd volume `to: 150`).
- `ListView`/`Flickable` scroll → add `ScrollBar.vertical: StyledScrollBar {}`.
- bar pill hover label → `StyledToolTip` shown on hover. It is a `ToolTip` subclass; instantiate as a child and bind visibility to a hover source:
  ```qml
  MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: ... }
  StyledToolTip { text: "Apps"; visible: ma.containsMouse }
  ```
- raw `Slider` that must keep a gradient track (NightLight temp) → leave raw, normalize to tokens only.
- **TextField normalize** (no shared widget — do inline): set background `Rectangle { radius: Theme.radius.small; color: Theme.surfaceContainerHigh; border.width: 1; border.color: <field>.activeFocus ? Theme.primary : Theme.outline; Behavior on border.color { CAnim {} } }`, text/placeholder colors to `Theme.text`/`Theme.textMuted`, font via the default StyledText family (Rubik). **Focus border is a bright SOLID color (`Theme.primary`), never the `Theme.state.focus` opacity** — 12% white composites dimmer than the unfocused outline and reads backwards.

### Recipe F — Motion tokens (R6)
No raw ms literals in animations. Route every `Behavior`/`*Animation` `duration` through `Theme.anim.durations.*` and `easing.bezierCurve` through a `Theme.anim` curve. Color → `CAnim`; geometry → `Anim`/`NumberAnimation` with a Theme curve. (e.g. RecordingIndicator `700`ms → `Theme.anim.durations.spring`.)

---

## VERIFY BLOCK (run at the end of EVERY task)

```bash
CFG=/home/atqa/dotfiles/quickshell/.config/quickshell
# 1. launch headless, capture log
qs kill 2>/dev/null; sleep 1
timeout 8 qs -p "$CFG" >/tmp/qs-verify.log 2>&1 &
sleep 5
# 2. assert clean load
grep -q "Configuration Loaded" /tmp/qs-verify.log && echo "LOADED OK" || echo "LOAD FAIL"
grep -iE "error|warning|is not a type|cannot|undefined|null" /tmp/qs-verify.log || echo "NO ERRORS"
qs kill 2>/dev/null
```

Expected: `LOADED OK` and `NO ERRORS`. Any QML/type error = task not done; fix and re-run.

Then per-file literal grep for the files this task touched:
```bash
grep -nE 'font.pixelSize:\s*[0-9]|radius:\s*[0-9]' <touched files>
```
Expected: empty, except documented exceptions (Power 48; radii owned by a shared widget; `radius.full` circle math that was migrated). List any remaining and justify.

---

## Task 0: StyledSlider `fillColor` enhancement

**Files:**
- Modify: `quickshell/.config/quickshell/components/StyledSlider.qml`

- [ ] **Step 1: Add the fillColor property and use it in both fill + handle**

Current file hardcodes `Theme.primary` at the fill rect and the handle. Change to:

```qml
import QtQuick
import QtQuick.Controls
import qs.components

Slider {
    id: root
    implicitHeight: 24
    property color fillColor: Theme.primary

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: Theme.radius.full
        color: Theme.surfaceContainerHighest

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.radius.full
            color: root.fillColor
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: Theme.radius.full
        color: root.fillColor
        border.color: Theme.background
        border.width: root.pressed ? 3 : 0

        Behavior on border.width { Anim { duration: Theme.anim.durations.small } }
    }
}
```

- [ ] **Step 2: VERIFY** (run the VERIFY BLOCK). Default `fillColor` = primary, so no consumer changes behavior. Expected `LOADED OK` / `NO ERRORS`.

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledSlider.qml
git commit -m "add fillColor override to StyledSlider"
```

---

## Task 1: Bar pills

**Files (modify):** `modules/bar/Pill.qml`, `ClockPill.qml`, `LauncherPill.qml`, `MediaPill.qml`, `ResourcesPill.qml`, `StatusPill.qml`, `TrayPill.qml`, `WorkspacesPill.qml`, `PeekState.qml`, `modules/Bar.qml`, `modules/bar/BottomBar.qml`

**Apply:** Recipe A (pill body `Theme.background`→`Theme.surfaceContainer`, keep `outlineVariant` hairline), Recipe B (TrayPill, LauncherPill, ClockPill, WorkspacesPill — any pill with a MouseArea gets StateLayer; WorkspacesPill dots get hover tint), Recipe C (all font/radius/color literals), Recipe E (StyledToolTip on interactive pills), Recipe F (WorkspacesPill width Anim → Theme curve).

- [ ] **Step 1: Pill.qml base** — `color: Theme.background` → `Theme.surfaceContainer`; keep border. This re-tiers all pills at once.
- [ ] **Step 2: ClockPill** — `font.pixelSize: 14` (`:18`) → `Theme.font.size.small` (13) or `.normal` (15) by fit. If clickable, add StateLayer.
- [ ] **Step 3: LauncherPill** — `font.pixelSize: 18` (`:19`) is the MaterialIcon launcher glyph → `Theme.icon.size.small` (18). Add `StateLayer { pressed: <ma>.pressed }` + `StyledToolTip { text: "Apps" }`.
- [ ] **Step 4: MediaPill** — `font.pixelSize: 14`/`12` (`:43,:49`) → `Theme.font.size.small`/`.smaller`.
- [ ] **Step 5: ResourcesPill** — 8 sizes (`14`×4 → icon glyphs `Theme.icon.size.small`; `11`×4 → label text `Theme.font.size.smaller`). Verify which are MaterialIcon vs Text.
- [ ] **Step 6: StatusPill** — sizes `16`×5 (MaterialIcon glyphs → `Theme.icon.size.small`) + `11`×2 (text → `Theme.font.size.smaller`). Add StateLayer where a glyph is clickable.
- [ ] **Step 7: TrayPill** — raw MouseArea per tray item → wrap each with StateLayer.
- [ ] **Step 8: WorkspacesPill** — `"#444444"` (`:39`) → `Theme.textDim`; dot size Anim → route through `Theme.anim` (Recipe F); add hover tint on dots.
- [ ] **Step 9: PeekState/Bar/BottomBar** — pure logic/containers; touch only if they carry a literal. BottomBar places pills in a plain Item (Layout-safe) — no change needed unless literals present.
- [ ] **Step 10: VERIFY** (VERIFY BLOCK + grep the 11 files). Expected clean.
- [ ] **Step 11: Commit** — `git commit -m "re-skin bar pills onto tokens and grey tier"`

---

## Task 2: Sidebar widgets

**Files (modify):** `modules/sidebar/QuickSliders.qml`, `QuickToggles.qml`, `QuickToggleTile.qml`, `CalendarWidget.qml`, `TodoWidget.qml`, `PomodoroWidget.qml`, `NotificationList.qml`, `SidebarRightContent.qml`, `modules/SidebarRight.qml`. (`QuickToggleModel.qml` = pure data, skip.)

**Apply:** Recipe A (panel `SidebarRight.qml` rect → `surfaceContainer`; widget cards → `surfaceContainerHigh`), Recipe B (CalendarWidget nav buttons, PomodoroWidget mode selector, TodoWidget items/tabs, NotificationList rows if interactive), Recipe C (all literals incl. circle radii → `radius.full`), Recipe E (QuickSliders ×2 → StyledSlider; volume `fillColor: Audio.muted ? Theme.error : Theme.primary`; lists → StyledScrollBar; PomodoroWidget ring → StyledProgressBar if it maps cleanly, else leave as token-migrated arcs).

- [ ] **Step 1: SidebarRight.qml** — panel rect (`:56`) `color: Theme.background` → `Theme.surfaceContainer`; keep `outlineVariant` hairline. Scrim already present.
- [ ] **Step 2: QuickSliders.qml** — replace both raw `Slider` blocks with `StyledSlider` (keep `from/to/value/onMoved`); brightness default fill, volume `fillColor: Audio.muted ? Theme.error : Theme.primary`. Deletes the `radius: 2`/`radius: 8`/handle literals. Widget card → `surfaceContainerHigh`.
- [ ] **Step 3: QuickToggleTile.qml** — already polished; only add a `// on-primary black text` comment to the `Qt.rgba(0,0,0,0.6)` (`:48`). Confirm tile color uses tokens (it does).
- [ ] **Step 4: CalendarWidget.qml** — nav `Rectangle`s (`:41,:57,:119`, `28/14`) → `radius.full` + StateLayer + MouseArea. Card → `surfaceContainerHigh`.
- [ ] **Step 5: TodoWidget.qml** — `font.pixelSize: 18`×2 (`:103,:114`) → role rung; item delete button `36/18` (`:200`) → `radius.full` + StateLayer; tab bar height literal → token; TextField normalize (Recipe C/E TextField bullet). List → StyledScrollBar.
- [ ] **Step 6: PomodoroWidget.qml** — `font.pixelSize: 24` (`:160`, MaterialIcon) → `icon.size.normal`/`.large`; `"#ffffff"` (`:159`) → `Theme.text`; ring circles `100/50` (`:103,:112`) → `radius.full`; mode/control buttons `36/18`,`48/24` → `radius.full` + StateLayer. Card → `surfaceContainerHigh`.
- [ ] **Step 7: NotificationList.qml** — `font.pixelSize: 18` (`:40`) → role rung; per-item rects → `surfaceContainerHigh` card tier; add StateLayer if rows are interactive. List → StyledScrollBar.
- [ ] **Step 8: SidebarRightContent.qml** — container; ensure widget children get the `surfaceContainerHigh` card tier consistently; no literals expected.
- [ ] **Step 9: VERIFY** (VERIFY BLOCK + grep). Open the sidebar manually if possible (`qs ipc call sidebarRight toggle`) — but the headless gate is the hard requirement.
- [ ] **Step 10: Commit** — `git commit -m "re-skin sidebar widgets onto tokens, tiers, and shared widgets"`

---

## Task 3: Sidebar dialogs

**Files (modify):** `modules/sidebar/dialogs/BluetoothDialog.qml`, `WiFiDialog.qml`, `NightLightDialog.qml`.

**Apply:** Recipe A (dialog root `Theme.background`→`Theme.surfaceContainerHigh` — they nest in the grey panel; connected rows → `surfaceContainerHighest`), R1 nested `StyledShadow` (Item-wrapped — dialog floats over grey panel, so it reads), Recipe B (device/network rows get StateLayer), Recipe C (all `font.pixelSize: 18/14` → role rungs), Recipe E (NightLight enable toggle → StyledSwitch; NightLight temp slider stays raw + token-normalized, gradient kept), Recipe F (scan/refresh icon animations → Theme curves).

- [ ] **Step 1: NightLightDialog.qml** — root (`:12`) → `surfaceContainerHigh`; toggle Rectangle (`:66,:72`, `48/28/14`,`20/10`) → `StyledSwitch { checked: Hyprsunset.active; onToggled: Hyprsunset.toggle() }`; temp slider (`:110-140`) stays raw `Slider`, normalize colors/radius to tokens, KEEP gradient (`#ff8800`→`#ffcc88`→`#ffffff`) with `// warmth data-viz` comment; gradient bar `radius: 2` (`:124`) → `radius.small`; bottom `16/8` (`:137`) → `radius.full`; `font.pixelSize: 18` (`:39`) → role rung.
- [ ] **Step 2: WiFiDialog.qml** — root → `surfaceContainerHigh`; network rows + connected row tiers + StateLayer; `font.pixelSize: 18`×4 + `14` (`:41,:59,:97,:111,:118`) → role rungs; refresh `RotationAnimation` → Theme duration.
- [ ] **Step 3: BluetoothDialog.qml** — root → `surfaceContainerHigh`; device rows + StateLayer; `font.pixelSize: 18`×3 (`:41,:55,:96`) → role rungs; scan icon opacity anim → Theme curve.
- [ ] **Step 4: Nested shadow** — wrap each dialog body in a plain `Item` and add `StyledShadow { target: <body> }` so it lifts off the grey panel (R1 nested case; Item-wrap required because the dialog Loader sits in the sidebar ColumnLayout).
- [ ] **Step 5: VERIFY** (VERIFY BLOCK + grep). Expected clean.
- [ ] **Step 6: Commit** — `git commit -m "re-skin sidebar dialogs: switch widget, tiers, nested elevation"`

---

## Task 4: Overlays A (search/filter — Launcher, Clipboard, EmojiPicker)

**Files (modify):** `modules/Launcher.qml`, `Clipboard.qml`, `EmojiPicker.qml`.

**Apply:** Recipe A (card `Theme.background`→`surfaceContainer`), Recipe D (scrim fade + card enter spring), Recipe B (ListView/GridView delegates get StateLayer + current-item focus tint), Recipe C (font literals → role rungs; `22`→`extraLarge`, `18`→`large`/icon rung), Recipe E (lists → StyledScrollBar; TextField normalize).

- [ ] **Step 1: Launcher.qml** — card (`:~105`) → `surfaceContainer`; Recipe D on its PanelWindow; ListView delegates (`:~189`) → StateLayer + `isCurrentItem` focus tint; `ScrollBar.vertical: StyledScrollBar {}`; `font.pixelSize: 22` (`:149`)→`extraLarge`, `18` (`:222`)→`large` or icon rung; TextField → token normalize.
- [ ] **Step 2: Clipboard.qml** — same pattern; `font.pixelSize: 22` (`:150`)→`extraLarge`, `18` (`:239`)→`large`; entry rows StateLayer; StyledScrollBar.
- [ ] **Step 3: EmojiPicker.qml** — same; GridView cells StateLayer + selection tint; `font.pixelSize: 22`×3 (`:105,:193,:247`)→`extraLarge` (the `:193`/`:247` are emoji glyph sizes — keep large but token if a rung fits, else local prop w/ comment); StyledScrollBar.
- [ ] **Step 4: VERIFY** (VERIFY BLOCK + grep the 3 files). Manually trigger one overlay if possible.
- [ ] **Step 5: Commit** — `git commit -m "re-skin launcher, clipboard, emoji overlays: scrim fade, enter spring, delegate state"`

---

## Task 5: Overlays B (pickers — Cheatsheet, PassMenu, WindowPicker, TagInput)

**Files (modify):** `modules/Cheatsheet.qml`, `PassMenu.qml`, `WindowPicker.qml`, `TagInput.qml`.

**Apply:** same recipe set as Task 4 (A, D, B, C, E).

- [ ] **Step 1: Cheatsheet.qml** — card→`surfaceContainer`; Recipe D; keybind rows StateLayer; `font.pixelSize: 22` (`:97`)→`extraLarge`; StyledScrollBar; TextField normalize.
- [ ] **Step 2: PassMenu.qml** — same; `font.pixelSize: 22` (`:120`)→`extraLarge`; entry rows StateLayer + focus tint; StyledScrollBar.
- [ ] **Step 3: WindowPicker.qml** — same; `font.pixelSize: 22` (`:130`)→`extraLarge`; window rows StateLayer + active/focused tint; StyledScrollBar.
- [ ] **Step 4: TagInput.qml** — standalone overlay (own Scope/PanelWindow/scrim); card→`surfaceContainer`; Recipe D; `font.pixelSize: 18` (`:90`)→`large` or icon rung; TextField normalize.
- [ ] **Step 5: VERIFY** (VERIFY BLOCK + grep the 4 files).
- [ ] **Step 6: Commit** — `git commit -m "re-skin cheatsheet, passmenu, windowpicker, taginput overlays"`

---

## Task 6: Feedback / status

**Files (modify):** `modules/Osd.qml`, `Notifications.qml`, `NotificationHistory.qml`, `RecordingIndicator.qml`, `MediaControls.qml`, `Power.qml`.

**Apply:** Recipe A (cards→`surfaceContainer`), Recipe C (literals incl. RecordingIndicator `radius: 6`→`radius.small`), Recipe E (Osd level bar + MediaControls position → StyledProgressBar with correct `to:`; NotificationHistory list → StyledScrollBar), Recipe B (Notifications dismiss + NotificationHistory clear + Power buttons → StateLayer), Recipe F (RecordingIndicator `700`ms → Theme duration; all anims → Theme curves).

- [ ] **Step 1: Osd.qml** — card → `surfaceContainer`; progress Rectangle (`:152`) → `StyledProgressBar { from:0; to:150; value: root.value }` (volume max 150; for brightness kind `to:100`); `font.pixelSize: 28` (`:137`, MaterialIcon) → `icon.size.large`.
- [ ] **Step 2: Notifications.qml** — card per-notification → `surfaceContainer`; dismiss button → StateLayer; `font.pixelSize: 16` (`:124`) → `Theme.font.size.normal`; keep slide-in (route durations through Theme, Recipe F).
- [ ] **Step 3: NotificationHistory.qml** — panel → `surfaceContainer`; clear button → StateLayer (replace ad-hoc hover); list → StyledScrollBar; row cards → `surfaceContainerHigh`.
- [ ] **Step 4: RecordingIndicator.qml** — `radius: 6` (`:65`) → `Theme.radius.small`; `font.pixelSize: 12` (`:80`) → `Theme.font.size.smaller`; pulse `700`ms (SequentialAnimation) → `Theme.anim.durations.spring`; keep `error` color (semantic). Body → `surfaceContainer`.
- [ ] **Step 5: MediaControls.qml** — card → `surfaceContainer`; position 2-rect (`:127-143`) → `StyledProgressBar { from:0; to:length; value:position }` (display-only, NOT seekable); MaterialIcon sizes `40`(`:101`)→`icon.size.larger`, `22`(`:168,:213`)→`icon.size.normal`, `28`(`:190`)→`icon.size.large`; route button anims through Theme.
- [ ] **Step 6: Power.qml** — card → `surfaceContainer`; action button containers → consistent `radius.large` + StateLayer (keep existing scale/color Behaviors, route through Theme curves); `font.pixelSize: 48` (`:141`, MaterialIcon) → keep `48` with `// hero glyph, no rung` comment (the one allowed exception).
- [ ] **Step 7: VERIFY** (VERIFY BLOCK + grep the 6 files). Trigger an OSD (`qs ipc` or change volume) and confirm no errors.
- [ ] **Step 8: Commit** — `git commit -m "re-skin feedback modules: progress bars, state layers, motion tokens"`

---

## Final review (after all tasks)

- [ ] Dispatch a final code-quality reviewer over the whole branch diff vs master.
- [ ] Repo-wide grep gate:
```bash
cd quickshell/.config/quickshell
grep -rnE 'font.pixelSize:\s*[0-9]' modules    # expect only Power.qml:141 (48)
grep -rnE 'radius:\s*[0-9]' modules            # expect empty (all migrated/widget-owned)
grep -rn '#[0-9a-fA-F]\{6\}\|Qt.rgba' modules  # expect only NightLight gradient + QuickToggleTile on-primary (commented)
```
- [ ] Full-shell smoke: VERIFY BLOCK, then manually open bar, sidebar, each overlay; trigger OSD + notification — consistent Rubik + rounding + grey-tier elevation, no QML errors.
- [ ] Use superpowers:finishing-a-development-branch (push, PR, merge).
