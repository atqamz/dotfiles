# Quickshell Design-System Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the quickshell design tokens and shared widgets to match end-4's visual polish (typography, rounding, motion, state feedback, elevation) while staying pure-black monochrome — the foundation every later sub-project builds on.

**Architecture:** All changes live in `quickshell/.config/quickshell/components/`. `Theme.qml` (a singleton `QtObject`) is the single source of design tokens; every other component reads tokens by name. We change token *values* and add new token groups, refactor `Anim.qml`/`CAnim.qml` to accept full-length bezier curves, upgrade `StateLayer.qml`, and add six new `Styled*` widgets. No consumers are migrated here (that is sub-project 2), so the running shell must keep loading without QML errors at every step.

**Tech Stack:** QML / Qt 6.10.3 / Quickshell 0.3.0. QtQuick, QtQuick.Controls, QtQuick.Effects (RectangularShadow, Qt 6.9+). Fonts: Rubik (UI), Material Icons Round (icons), JetBrains Mono (retained, unused).

**Depth note (pure black):** A dark drop shadow is invisible against the solid-black desktop (#000000 cannot go darker). On the black desktop, panel separation comes from lighter surface tiers (`#0a0a0a`→`#202020`) plus a hairline `outlineVariant` border — both already in use. `StyledShadow` is still added because panels float over arbitrary window content (e.g. a maximized light app), where the shadow does read. Do not rely on shadow for separation over the desktop.

**Verification reality:** This repo has no QML unit-test harness, and inventing one is out of scope. Per the project's existing dev loop, each task is verified by hot-reloading the running shell and checking logs:

```bash
# REUSABLE VERIFY BLOCK — referred to as "run the VERIFY block"
pgrep -x quickshell >/dev/null && pkill -SIGUSR2 quickshell   # hot-reload
sleep 2
qs log 2>/dev/null | tail -40
# PASS = no lines containing "error", "QML", "Unable to assign", "is not a type",
#        "Cannot assign", "Required property". FAIL = any such line.
# If the shell is not running: `qs >/tmp/qslog.txt 2>&1 &` then `sleep 3` then
# `grep -iE "error|unable|not a type|cannot assign|required property" /tmp/qslog.txt`.
```

Where a task has a visible effect, an extra **Visual** check is given.

**Branch / workflow:** All work on branch `quickshell-design-system`. Commit per task. Open one PR after the final task (per repo GitHub conventions: push `-u`, `gh pr create`, assignee `atqamz`, `gh pr merge --merge --delete-branch`). The `google-rubik-fonts` dependency change is committed to the separate `dotmachines` repo (Task 2).

---

### Task 1: Create the working branch

**Files:** none (git only)

- [ ] **Step 1: Create and switch to the branch from up-to-date master**

```bash
cd /home/atqa/dotfiles
git checkout master
git pull
git checkout -b quickshell-design-system
```

- [ ] **Step 2: Confirm branch**

Run: `git branch --show-current`
Expected: `quickshell-design-system`

---

### Task 2: Add `google-rubik-fonts` dependency (dotmachines + local install)

Rubik must be installed or the UI silently falls back to a default sans. The package is Fedora-managed; provisioning lives in the separate `dotmachines` repo.

**Files:**
- Modify: `/home/atqa/repo/dotmachines/ansible/inventory/group_vars/workstations.yaml` (fonts list)

- [ ] **Step 1: Find the fonts block**

Run: `grep -n "fonts\|jetbrains\|fontawesome\|font" /home/atqa/repo/dotmachines/ansible/inventory/group_vars/workstations.yaml`
Expected: a list containing existing font packages (e.g. `jetbrains-mono-fonts`, `fontawesome-fonts-all`, `material-icons-fonts`).

- [ ] **Step 2: Add the package**

Add `google-rubik-fonts` to that font package list, alphabetically near the other `*-fonts` entries. Example (match the file's existing indentation/style):

```yaml
    - google-rubik-fonts
```

- [ ] **Step 3: Commit in the dotmachines repo**

```bash
cd /home/atqa/repo/dotmachines
git add ansible/inventory/group_vars/workstations.yaml
git commit -m "add google-rubik-fonts for quickshell UI font"
git push
cd /home/atqa/dotfiles
```

- [ ] **Step 4: Install locally so the redesign is visible now**

Run: `sudo dnf install -y google-rubik-fonts && fc-list | grep -i rubik | head -3`
Expected: at least one `Rubik` face listed (e.g. `Rubik-Regular`).

---

### Task 3: Theme.qml — typography tokens

Repoint the UI font from JetBrains Mono → Rubik, the icon font from Material Icons → Material Icons Round (same ligatures, verified installed), add weight + icon-size scales, and bump the font-size scale.

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Theme.qml:57-71`

- [ ] **Step 1: Replace the `font` token group**

Replace the existing block (lines 57-71):

```qml
    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: "JetBrains Mono"
            readonly property string mono: "JetBrains Mono"
            readonly property string material: "Material Icons"
        }
        readonly property QtObject size: QtObject {
            readonly property int smaller: 10
            readonly property int small: 11
            readonly property int normal: 12
            readonly property int large: 14
            readonly property int larger: 16
            readonly property int extraLarge: 20
        }
    }
```

with:

```qml
    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            // UI font: Rubik (Fedora google-rubik-fonts, static multi-weight).
            readonly property string sans: "Rubik"
            // Retained, unused by default UI.
            readonly property string mono: "JetBrains Mono"
            // Rounded variant of the legacy Material Icons set — identical
            // ligature names to "Material Icons", so existing icon usages
            // keep working. Deliberately NOT "Material Symbols Rounded".
            readonly property string material: "Material Icons Round"
        }
        // Static Rubik faces: select weight via font.weight, not variableAxes.
        readonly property QtObject weight: QtObject {
            readonly property int body: 400
            readonly property int title: 600
        }
        // Rung names are offset from end-4's by ~one step; values track end-4.
        readonly property QtObject size: QtObject {
            readonly property int smaller: 12     // end-4 smaller
            readonly property int small: 13       // end-4 smallie
            readonly property int normal: 15      // end-4 small
            readonly property int large: 17       // end-4 large
            readonly property int larger: 19      // end-4 larger
            readonly property int extraLarge: 22  // end-4 huge
        }
    }

    // Icon pixel sizes (Material Icons Round). Adopted by call sites in re-skin.
    readonly property QtObject icon: QtObject {
        readonly property QtObject size: QtObject {
            readonly property int small: 18
            readonly property int normal: 22
            readonly property int large: 28
            readonly property int larger: 36
        }
    }
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS (no QML errors). The shell text now renders in Rubik and is larger.

- [ ] **Step 3: Visual check**

Visually: bar clock + sidebar labels render in proportional Rubik (not monospace), slightly larger. Material icons still render correctly (rounded style), no missing-glyph boxes.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "theme: switch UI font to Rubik, icons to Material Icons Round, bump sizes"
```

---

### Task 4: Theme.qml — color tokens (monochrome + surface-state ladder)

Neutralize the two bluish tokens, drop nothing functional, and add the surface-state ladder + interaction-opacity tokens + disabled text.

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Theme.qml:11-30`

- [ ] **Step 1: Audit existing blue-token consumers (prerequisite)**

Run: `grep -rn "Theme.secondary\|Theme.tertiary" /home/atqa/dotfiles/quickshell/.config/quickshell/`
Expected: a list of usages. Confirm none use the blue hue to convey *meaning* (info/link). If any do, note them for the re-skin task; the token still flattens to grey here. (Decorative/accent uses are fine to flatten.)

- [ ] **Step 2: Replace the color block**

Replace lines 11-30 (from `readonly property color background` through `readonly property color scrim`):

```qml
    readonly property color background: "#000000"
    readonly property color surface: "#0a0a0a"
    readonly property color surfaceContainerLow: "#101010"
    readonly property color surfaceContainer: "#141414"
    readonly property color surfaceContainerHigh: "#1a1a1a"
    readonly property color surfaceContainerHighest: "#202020"
    readonly property color surfaceBright: "#2a2a2a"
    readonly property color outline: "#3a3a3a"
    readonly property color outlineVariant: "#262626"
    readonly property color text: "#ffffff"
    readonly property color textVariant: "#cccccc"
    readonly property color textMuted: "#888888"
    readonly property color textDim: "#666666"
    readonly property color textDisabled: "#5e5e5e"   // ~38% on black, monochrome
    readonly property color surfaceDisabled: "#0c0c0c" // surface mixed toward bg
    readonly property color primary: "#ffffff"
    readonly property color textOnPrimary: "#000000"
    readonly property color secondary: "#c0c0c0"      // neutralized (was #b9c8da)
    readonly property color tertiary: "#a0a0a0"       // neutralized (was #9ccbfb)
    readonly property color warning: "#ffaa44"        // semantic exception
    readonly property color error: "#ff4444"          // semantic exception
    readonly property color scrim: "#cc000000"
    readonly property color shadow: "#66000000"       // for StyledShadow over light content

    // Interaction state-layer opacities (M3): overlay the layer's on-color.
    readonly property QtObject state: QtObject {
        readonly property real hover: 0.08
        readonly property real focus: 0.12
        readonly property real pressed: 0.12
        readonly property real dragged: 0.16
    }
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS. Any previously-blue accents now render grey.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "theme: neutralize accents to monochrome, add state + disabled tokens"
```

---

### Task 5: Theme.qml — rounding tokens (soft)

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Theme.qml:50-55`

- [ ] **Step 1: Replace the `radius` group**

Replace lines 50-55:

```qml
    readonly property QtObject radius: QtObject {
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 12
        readonly property int full: 9999
    }
```

with:

```qml
    readonly property QtObject radius: QtObject {
        readonly property int small: 8        // end-4 verysmall
        readonly property int normal: 16       // end-4 normal (17)
        readonly property int large: 22        // end-4 large (23)
        readonly property int extraLarge: 28   // end-4 verylarge (30)
        readonly property int full: 9999
    }
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS. Panels/cards reading `Theme.radius.*` are now more rounded. Note: components with hardcoded `radius:` literals stay sharp until re-skin (expected, see spec Migration).

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "theme: soften rounding scale toward end-4"
```

---

### Task 6: Theme.qml — elevation & z-order tokens

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Theme.qml` (append new groups inside the root `QtObject`, before the closing brace after the `bar` group)

- [ ] **Step 1: Add the groups**

After the existing `bar` token group (currently lines 85-89) and before the final closing `}`, add:

```qml
    readonly property QtObject elevation: QtObject {
        readonly property int margin: 10   // shadow bleed reserve around panels
    }

    // Named stacking layers so modules don't fight over z.
    readonly property QtObject z: QtObject {
        readonly property int base: 0
        readonly property int panel: 10
        readonly property int overlay: 20
        readonly property int popup: 30
        readonly property int osd: 40
    }
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS (tokens unused yet).

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "theme: add elevation margin and z-order scale"
```

---

### Task 7: Theme.qml — motion curves (full-length bezier, with overshoot)

Replace the 4-element curves with full-length arrays (groups of three points, ending at `1,1`) so springs/overshoot/emphasized can be expressed.

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Theme.qml:73-83`

- [ ] **Step 1: Replace the `anim` group**

Replace lines 73-83:

```qml
    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 120
            readonly property int normal: 200
            readonly property int large: 320
            readonly property int extraLarge: 480
        }
        // Material Design "emphasized" curve (approximation).
        readonly property var standard: [0.2, 0.0, 0.0, 1.0]
        readonly property var emphasized: [0.3, 0.0, 0.0, 1.0]
    }
```

with:

```qml
    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 120
            readonly property int normal: 200
            readonly property int large: 320
            readonly property int extraLarge: 480
            readonly property int springFast: 350
            readonly property int spring: 500
        }
        // Full-length bezier curves: groups of 3 points (c1,c2,end), end = 1,1.
        readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1, 1]
        readonly property var standardDecel: [0.0, 0.0, 0.0, 1.0, 1, 1]
        readonly property var standardAccel: [0.3, 0.0, 1.0, 1.0, 1, 1]
        // M3 emphasized: two cubic segments (12 elements).
        readonly property var emphasized: [0.05, 0.0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1.0, 1, 1]
        // Spring curves with overshoot (control-point y > 1) — from end-4.
        readonly property var spring: [0.38, 1.21, 0.22, 1.0, 1, 1]
        readonly property var springFast: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property var decel: [0.05, 0.7, 0.1, 1.0, 1, 1]
        readonly property var accel: [0.3, 0.0, 0.8, 0.15, 1, 1]
        readonly property var clickBounce: [0.38, 1.21, 0.22, 1.0, 1, 1]
    }
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS. `Anim.qml`/`CAnim.qml` still index `standard[0..3]` and re-pad to a 6-element curve; `standard`'s leading four values are unchanged, so existing motion is identical. The added curves are unused until Task 8 refactors Anim/CAnim to consume them.

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "theme: full-length motion curves with spring/overshoot"
```

---

### Task 8: Refactor Anim.qml / CAnim.qml to consume full-length curves

Make both accept a `curve` property (default `Theme.anim.standard`) and pass it straight through, so callers can opt into spring/emphasized. Defaults preserve current behavior for existing `Anim {}` / `CAnim {}` usages.

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/Anim.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/CAnim.qml`

- [ ] **Step 1: Rewrite Anim.qml**

Replace the whole file with:

```qml
import QtQuick
import qs.components

NumberAnimation {
    // Override `curve` with any Theme.anim.* (e.g. Theme.anim.spring) and
    // `duration` as needed. Defaults reproduce the prior standard motion.
    property var curve: Theme.anim.standard
    duration: Theme.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
```

- [ ] **Step 2: Rewrite CAnim.qml**

Replace the whole file with:

```qml
import QtQuick
import qs.components

ColorAnimation {
    property var curve: Theme.anim.standard
    duration: Theme.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS. Existing color/number behaviors unchanged (standard curve, normal duration).

- [ ] **Step 4: Visual check (overshoot works)**

Temporarily, in `StateLayer.qml`'s `Behavior on color { CAnim {} }`, set `CAnim { curve: Theme.anim.springFast }`, reload, hover a bar pill — the tint should ease in with a slight spring. Revert the temporary change before committing (StateLayer is upgraded properly in Task 10).

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/components/Anim.qml quickshell/.config/quickshell/components/CAnim.qml
git commit -m "components: Anim/CAnim accept full-length curve override"
```

---

### Task 9: StyledText.qml — Rubik weight

Add explicit body weight (the family token now resolves to Rubik). Title-weight is opt-in by consumers via `font.weight: Theme.font.weight.title`.

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledText.qml`

- [ ] **Step 1: Add the weight line**

In `StyledText.qml`, after `font.family: Theme.font.family.sans` (line 8) add:

```qml
    font.weight: Theme.font.weight.body
```

Resulting file:

```qml
import QtQuick
import qs.components

Text {
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Theme.text
    font.family: Theme.font.family.sans
    font.weight: Theme.font.weight.body
    font.pixelSize: Theme.font.size.normal

    Behavior on color {
        CAnim {}
    }
}
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 3: Visual check**

Body text renders at Rubik 400; a temporary `StyledText { font.weight: Theme.font.weight.title }` instance would render heavier (no need to keep).

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledText.qml
git commit -m "components: StyledText uses Rubik body weight"
```

---

### Task 10: StateLayer.qml — read opacities from Theme tokens

Replace hardcoded `0.08`/`0.16` with `Theme.state.*` (hover 8%, pressed 12%) and add an opt-in `focused` state (12%).

**Files:**
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StateLayer.qml`

- [ ] **Step 1: Replace the whole file**

```qml
import QtQuick
import qs.components

// Hover/focus/press tint layer. Drop into a parent that has `radius` set;
// tints to a soft white wash. Opacities come from Theme.state (M3).
Rectangle {
    id: root

    property alias hovered: hoverHandler.hovered
    property bool pressed: false
    property bool focused: false
    property color tint: Theme.text   // on-color to wash with

    anchors.fill: parent
    radius: parent.radius
    color: pressed ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.pressed)
         : focused ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.focus)
         : hovered ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.hover)
         : Qt.rgba(tint.r, tint.g, tint.b, 0)

    Behavior on color {
        CAnim {}
    }

    HoverHandler {
        id: hoverHandler
    }
}
```

- [ ] **Step 2: Run the VERIFY block**

Expected: PASS. Existing consumers (which set `hovered`/`pressed`) behave as before, except pressed is now 12% (was 16%) and uses `tint` (default white) — visually near-identical.

- [ ] **Step 3: Visual check**

Hover a bar pill / toggle tile → soft white wash appears; press → slightly stronger.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StateLayer.qml
git commit -m "components: StateLayer reads M3 state opacities from Theme"
```

---

### Task 11: StyledShadow.qml (new)

RectangularShadow wrapper for floating panels (helps over non-black window content; see Depth note).

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledShadow.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Effects
import qs.components

// Usage: place as a sibling BEFORE the target rect; pass target.
// Set `cached: false` if the target animates size/radius.
RectangularShadow {
    required property var target
    anchors.fill: target
    radius: target.radius
    blur: 0.9 * Theme.elevation.margin
    spread: 1
    offset: Qt.vector2d(0.0, 1.0)
    color: Theme.shadow
    cached: true
}
```

- [ ] **Step 2: Register in qmldir**

Add to `components/qmldir`:

```
StyledShadow 1.0 StyledShadow.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS (no consumers yet; type resolves).

- [ ] **Step 4: Smoke-instantiate**

Temporarily add to `shell.qml` (inside `ShellRoot`) a hidden test or rely on type resolution; simplest is the VERIFY block passing (QML resolves the import). Confirm `qs log` has no "StyledShadow is not a type".

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledShadow.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledShadow (RectangularShadow wrapper)"
```

---

### Task 12: StyledSwitch.qml (new)

Material 3 toggle, monochrome (active = white track, black thumb; inactive = grey).

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledSwitch.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Controls
import qs.components

Switch {
    id: root
    property real uiScale: 0.85
    implicitHeight: 32 * root.uiScale
    implicitWidth: 52 * root.uiScale

    background: Rectangle {
        radius: Theme.radius.full
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: 2 * root.uiScale
        border.color: root.checked ? Theme.primary : Theme.outline

        Behavior on color { CAnim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
        Behavior on border.color { CAnim {} }
    }

    indicator: Rectangle {
        property int sz: (root.pressed || root.down) ? 28 : (root.checked ? 24 : 16)
        width: sz * root.uiScale
        height: sz * root.uiScale
        radius: Theme.radius.full
        color: root.checked ? Theme.textOnPrimary : Theme.outline
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (root.checked
            ? ((root.pressed || root.down) ? 22 : 24)
            : ((root.pressed || root.down) ? 2 : 8)) * root.uiScale

        Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on width { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on height { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on color { CAnim {} }
    }
}
```

- [ ] **Step 2: Register in qmldir**

```
StyledSwitch 1.0 StyledSwitch.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledSwitch.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledSwitch (M3 monochrome toggle)"
```

---

### Task 13: StyledSlider.qml (new)

Monochrome Material slider: grey track, white fill + handle.

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledSlider.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Controls
import qs.components

Slider {
    id: root
    implicitHeight: 24

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
            color: Theme.primary
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: Theme.radius.full
        color: Theme.primary
        border.color: Theme.background
        border.width: root.pressed ? 3 : 0

        Behavior on border.width { Anim { duration: Theme.anim.durations.small } }
    }
}
```

- [ ] **Step 2: Register in qmldir**

```
StyledSlider 1.0 StyledSlider.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledSlider.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledSlider (monochrome M3 slider)"
```

---

### Task 14: StyledToolTip.qml (new)

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledToolTip.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Controls
import qs.components

ToolTip {
    id: root
    delay: 400
    padding: Theme.padding.normal

    contentItem: StyledText {
        text: root.text
        color: Theme.text
        font.pixelSize: Theme.font.size.small
    }

    background: Rectangle {
        radius: Theme.radius.small
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant
    }
}
```

- [ ] **Step 2: Register in qmldir**

```
StyledToolTip 1.0 StyledToolTip.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledToolTip.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledToolTip"
```

---

### Task 15: StyledScrollBar.qml (new)

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledScrollBar.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Controls
import qs.components

ScrollBar {
    id: root
    padding: 2

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: Theme.radius.full
        color: root.pressed ? Theme.textMuted
             : root.hovered ? Theme.outline
             : Theme.outlineVariant
        opacity: root.active ? 1 : 0

        Behavior on color { CAnim {} }
        Behavior on opacity { Anim {} }
    }
}
```

- [ ] **Step 2: Register in qmldir**

```
StyledScrollBar 1.0 StyledScrollBar.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledScrollBar.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledScrollBar"
```

---

### Task 16: StyledProgressBar.qml (new)

**Files:**
- Create: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/StyledProgressBar.qml`
- Modify: `/home/atqa/dotfiles/quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Create the component**

```qml
import QtQuick
import QtQuick.Controls
import qs.components

ProgressBar {
    id: root
    implicitHeight: 6

    background: Rectangle {
        radius: Theme.radius.full
        color: Theme.surfaceContainerHighest
    }

    contentItem: Item {
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.radius.full
            color: Theme.primary

            Behavior on width { Anim {} }
        }
    }
}
```

- [ ] **Step 2: Register in qmldir**

```
StyledProgressBar 1.0 StyledProgressBar.qml
```

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/StyledProgressBar.qml quickshell/.config/quickshell/components/qmldir
git commit -m "components: add StyledProgressBar"
```

---

### Task 17: Reference re-skin — prove the system on one component

Re-skin a single component to validate the foundation end-to-end (spec success criterion). Target: the sidebar quick-toggle tile, which has hardcoded radius/size literals and an ad-hoc switch-free toggle look.

**Files:**
- Read first: `/home/atqa/dotfiles/quickshell/.config/quickshell/modules/sidebar/QuickToggleTile.qml`
- Modify: same file

- [ ] **Step 1: Read the current tile**

Run: `cat /home/atqa/dotfiles/quickshell/.config/quickshell/modules/sidebar/QuickToggleTile.qml`
Confirm it matches the 4 edits below (line numbers from the current file).

- [ ] **Step 2a: Spring the toggle color transition (line 18)**

Replace:

```qml
    Behavior on color { ColorAnimation { duration: 200 } }
```

with:

```qml
    Behavior on color { CAnim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
```

- [ ] **Step 2b: Tokenize the icon size (line 28)**

Replace `font.pixelSize: 20` with:

```qml
            font.pixelSize: Theme.icon.size.normal
```

- [ ] **Step 2c: Bump the name label to the new body size (line 37)**

Replace `font.pixelSize: Theme.font.size.small` (the `tile.model.name` StyledText) with:

```qml
                font.pixelSize: Theme.font.size.normal
```

- [ ] **Step 2d: Fix the invisible toggled status text (line 48)**

The status sub-label currently uses `Qt.rgba(1, 1, 1, 0.7)` when toggled — white text on the white (primary) active fill, i.e. invisible. With monochrome active = white fill / black text, it must be dark. Replace:

```qml
                color: tile.model.toggled ? Qt.rgba(1, 1, 1, 0.7) : Theme.textMuted
```

with:

```qml
                color: tile.model.toggled ? Qt.rgba(0, 0, 0, 0.6) : Theme.textMuted
```

- [ ] **Step 2e: Add a hover state layer**

Immediately after the `MouseArea { ... }` block (before the tile's closing `}`), add:

```qml
    StateLayer {}
```

(The root tile already sets `radius: Theme.radius.large`, which Task 5 widened to 22 — no change needed there.)

- [ ] **Step 3: Run the VERIFY block**

Expected: PASS.

- [ ] **Step 4: Visual check (the proof)**

Open the right sidebar (`qs ipc call sidebarRight toggle`). The quick-toggle tile should now visibly show: Rubik label, larger rounded corners (22px), monochrome active state (white fill / black text), spring color transition on toggle, soft white hover wash. Compare against end-4 sidebar tiles — proportions/polish should be comparable.

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/modules/sidebar/QuickToggleTile.qml
git commit -m "sidebar: re-skin quick-toggle tile onto new design tokens"
```

---

### Task 18: Open the PR

**Files:** none (git/gh only)

- [ ] **Step 1: Push the branch**

```bash
git push -u origin quickshell-design-system
```

- [ ] **Step 2: Create the PR**

```bash
gh pr create --assignee atqamz \
  --title "quickshell design-system foundation: tokens, motion, shared widgets" \
  --body "$(cat <<'EOF'
## Summary

- Theme.qml: Rubik UI font + Material Icons Round, monochrome accents, soft rounding, font/icon size scales, surface-state + focus tokens, elevation + z-order tokens, full-length spring motion curves.
- Anim/CAnim accept a full-length curve override (springs/overshoot/emphasized).
- StateLayer reads M3 state opacities from Theme; adds focus state.
- New shared widgets: StyledShadow, StyledSwitch, StyledSlider, StyledToolTip, StyledScrollBar, StyledProgressBar.
- Reference re-skin of the sidebar quick-toggle tile proving the system.
- Dependency google-rubik-fonts added to dotmachines.

Foundation for the quickshell visual redesign (spec: docs/superpowers/specs/2026-05-30-quickshell-visual-redesign-design.md). Re-skin of remaining modules, dock, overview, and settings GUI are separate sub-projects.

## Test plan

- [ ] qs log clean after each token change (no QML errors / missing glyphs)
- [ ] Rubik + Material Icons Round render across bar/sidebar
- [ ] New widgets instantiate without errors
- [ ] Spring/overshoot curve visibly applies
- [ ] Re-skinned quick-toggle tile matches end-4 polish
EOF
)"
```

- [ ] **Step 3: Merge**

```bash
gh pr merge --merge --delete-branch
```

---

## Notes for the executor

- After Theme.qml token jumps, the shell will look *half-migrated* (token-reading surfaces update; hardcoded literals don't). This is expected per the spec Migration section — full re-skin is sub-project 2. Only Task 17's tile is fully re-skinned here.
- If `qs log` shows a missing-glyph or font fallback warning for Rubik, confirm Task 2 Step 4 installed the font (`fc-list | grep -i rubik`).
- The `material-icons-fonts` package is already installed and provides `Material Icons Round` — no new icon dependency.
