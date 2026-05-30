# Quickshell Settings GUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-shell settings overlay backed by a new persisted `Config`
singleton, exposing typography/roundness/motion (Appearance), Bar, Dock, Overview,
and Behavior settings that apply live; rewire the hardcoded consumers to bind to it.

**Architecture:** New `components/Config.qml` singleton (FileView + JsonAdapter,
persists `~/.local/state/quickshell/settings.json`, reactive two-way binding).
`Theme.qml` reads `Config.options.appearance.*` for live typography/roundness/motion.
A `modules/Settings.qml` overlay (cloned from `modules/Overview.qml`) hosts a nav
rail + per-page controls (`modules/settings/`). Each control reads via binding,
writes via user-action signals (`onMoved`/`onToggled`). Consumers across bar, dock,
overview, notifications, and Hyprsunset bind to `Config.options.*`.

**Tech Stack:** Quickshell 0.3.0 / Qt 6.10.3, QML, `Quickshell.Io` (FileView +
JsonAdapter). Validation: `qs -p <cfg>` → grep log → `qs kill` (no offline linter).

**Spec:** `docs/superpowers/specs/2026-05-31-quickshell-settings-gui-design.md`

---

## Conventions for every task

- **Validate** = `qs -p ~/.config/quickshell 2>&1 | tee /tmp/qslog &` (background),
  wait ~3s, grep the log for `Configuration Loaded` (or the running banner) and for
  errors (`error|Error|QML .*is not a type|Unable|undefined|TypeError|loop detected`),
  then `qs kill`. Clean = banner present, no relevant errors. The repo's live config
  IS `~/.config/quickshell` (Stow symlink), so validating there validates the real
  shell. Use a separate instance path if a running shell conflicts.
- **Config access:** `Config` is in `qs.components`. Files that read it must
  `import qs.components` (most already do for `Theme`).
- **Two-way binding rule:** controls READ via binding (`value: Config.options.x`),
  WRITE only from user-action signals (`onMoved`, `onToggled`, custom `selected`).
  Never `onValueChanged`/`onCheckedChanged` (re-entry with the watchChanges reload).
- **Commit** after each task on branch `settings-gui` (already created), imperative
  lowercase subject, no planning jargon, no Co-Authored-By, GPG on.
- Live/interactive behavior (drag a slider, watch the bar resize) can't be verified
  headlessly — validate load-cleanliness + JSON persistence; note interactive checks
  for the user.

---

### Task 1: Config singleton + registration

**Files:**
- Create: `quickshell/.config/quickshell/components/Config.qml`
- Modify: `quickshell/.config/quickshell/components/qmldir`

- [ ] **Step 1: Write `components/Config.qml`**

```qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dirPath: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string filePath: dirPath + "/settings.json"
    property alias options: jsonAdapter
    property bool ready: false
    readonly property int readWriteDelay: 50

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object")
                obj[keys[i]] = {};
            obj = obj[keys[i]];
        }
        let converted = value;
        if (typeof value === "string") {
            let t = value.trim();
            if (t === "true" || t === "false" || (t !== "" && !isNaN(Number(t)))) {
                try { converted = JSON.parse(t); } catch (e) { converted = value; }
            }
        }
        obj[keys[keys.length - 1]] = converted;
    }

    // FileView won't create missing parent dirs. On first run (file missing) we must
    // mkdir BEFORE the first writeAdapter(). The Process is async, so gate the
    // initial write on its exit rather than racing it from Component.onCompleted.
    property bool _pendingWrite: false
    Process {
        id: ensureDirProc
        command: ["bash", "-c", "mkdir -p " + root.dirPath]
        onExited: {
            if (root._pendingWrite) { root._pendingWrite = false; fileView.writeAdapter(); }
        }
    }

    Timer { id: reloadTimer; interval: root.readWriteDelay; onTriggered: fileView.reload() }
    Timer { id: writeTimer;  interval: root.readWriteDelay; onTriggered: fileView.writeAdapter() }

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        blockLoading: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
                root._pendingWrite = true;
                ensureDirProc.running = true;   // writes defaults once mkdir exits
            }
        }

        JsonAdapter {
            id: jsonAdapter

            property JsonObject appearance: JsonObject {
                property string fontFamily: "Rubik"
                property real fontScale: 1.0
                property real radiusScale: 1.0
                property real motionScale: 1.0
            }
            property JsonObject bar: JsonObject {
                property int height: 28
                property bool clock24h: true
                property bool showLauncher: true
                property bool showWorkspaces: true
                property bool showMedia: true
                property bool showClock: true
                property bool showResources: true
                property bool showTray: true
                property bool showStatus: true
            }
            property JsonObject dock: JsonObject {
                property bool enable: true
                property int height: 60
                property int iconSize: 36
                property bool autoHide: true
            }
            property JsonObject overview: JsonObject {
                property real scale: 0.18
                property int rows: 2
                property int columns: 5
            }
            property JsonObject behavior: JsonObject {
                property int notifTimeout: 5000
                property int notifMaxVisible: 5
                property int notifHistoryMax: 50
                property bool dndDefault: false
                property int nightTemp: 4000
            }
        }
    }
}
```

- [ ] **Step 2: Register in `components/qmldir`**

Add this line directly under the existing `singleton Theme 1.0 Theme.qml` line:

```
singleton Config 1.0 Config.qml
```

- [ ] **Step 3: Validate load + persistence**

Run the validation procedure. Additionally:
- `cat ~/.local/state/quickshell/settings.json` → must exist, be valid JSON, contain
  the full default tree (`appearance`, `bar`, `dock`, `overview`, `behavior`).
- `cd ~/dotfiles && git status --porcelain` → `settings.json` must NOT appear
  (it lives outside the repo at `~/.local/state/`).
- Grep log: no `FileView`/`JsonAdapter`/`is not a type` errors.

Expected: clean load, JSON written with defaults, nothing new in git status.

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/components/Config.qml quickshell/.config/quickshell/components/qmldir
git commit -m "add Config singleton with persisted settings store"
```

---

### Task 2: Theme reads Appearance settings (live typography / roundness / motion)

**Files:**
- Modify: `quickshell/.config/quickshell/components/Theme.qml`

- [ ] **Step 1: Add the Config import**

Change the import block (currently `import QtQuick` only) to also import the module
so `Config` (a sibling singleton) resolves — mirrors `StyledSwitch.qml`:

```qml
import QtQuick
import qs.components
```

- [ ] **Step 2: font.family.sans ← Config**

Replace `readonly property string sans: "Rubik"` (line ~73) with:

```qml
readonly property string sans: Config.options.appearance.fontFamily
```

(Leave `mono` and `material` literal.)

- [ ] **Step 3: font.size.* ← fontScale**

Replace the `size` QtObject body (lines ~88-93) with computed bindings (bases are the
current literals):

```qml
readonly property int smaller: Math.round(12 * Config.options.appearance.fontScale)
readonly property int small: Math.round(13 * Config.options.appearance.fontScale)
readonly property int normal: Math.round(15 * Config.options.appearance.fontScale)
readonly property int large: Math.round(17 * Config.options.appearance.fontScale)
readonly property int larger: Math.round(19 * Config.options.appearance.fontScale)
readonly property int extraLarge: Math.round(22 * Config.options.appearance.fontScale)
```

- [ ] **Step 4: icon.size.* ← fontScale**

Replace the icon `size` QtObject body (lines ~100-103):

```qml
readonly property int small: Math.round(18 * Config.options.appearance.fontScale)
readonly property int normal: Math.round(22 * Config.options.appearance.fontScale)
readonly property int large: Math.round(28 * Config.options.appearance.fontScale)
readonly property int larger: Math.round(36 * Config.options.appearance.fontScale)
```

- [ ] **Step 5: radius.* ← radiusScale (full stays 9999)**

Replace the radius QtObject body (lines ~63-67):

```qml
readonly property int small: Math.round(8 * Config.options.appearance.radiusScale)
readonly property int normal: Math.round(16 * Config.options.appearance.radiusScale)
readonly property int large: Math.round(22 * Config.options.appearance.radiusScale)
readonly property int extraLarge: Math.round(28 * Config.options.appearance.radiusScale)
readonly property int full: 9999
```

- [ ] **Step 6: anim.durations.* ← motionScale (floored ≥ 1)**

Replace the durations QtObject body (lines ~109-114):

```qml
readonly property int small: Math.max(1, Math.round(120 * Config.options.appearance.motionScale))
readonly property int normal: Math.max(1, Math.round(200 * Config.options.appearance.motionScale))
readonly property int large: Math.max(1, Math.round(320 * Config.options.appearance.motionScale))
readonly property int extraLarge: Math.max(1, Math.round(480 * Config.options.appearance.motionScale))
readonly property int springFast: Math.max(1, Math.round(350 * Config.options.appearance.motionScale))
readonly property int spring: Math.max(1, Math.round(500 * Config.options.appearance.motionScale))
```

- [ ] **Step 7: Validate**

Run validation. With all scales at default `1.0`, every computed value must equal the
old literal (12,13,15…; 8,16,22,28; 200,320…) so the shell looks identical. Grep for
`loop detected` / binding-loop warnings — there must be none (Config never reads
Theme, so no cycle).

- [ ] **Step 8: Commit**

```bash
git add quickshell/.config/quickshell/components/Theme.qml
git commit -m "drive Theme typography, roundness, and motion from Config"
```

---

### Task 3: Settings overlay shell + nav rail + page frame

**Files:**
- Create: `quickshell/.config/quickshell/modules/Settings.qml`
- Create: `quickshell/.config/quickshell/modules/settings/SettingsContent.qml`
- Create: `quickshell/.config/quickshell/modules/settings/widgets/NavButton.qml`
- Create: `quickshell/.config/quickshell/modules/settings/qmldir`
- Create: `quickshell/.config/quickshell/modules/settings/widgets/qmldir`
- Modify: `quickshell/.config/quickshell/shell.qml`
- Modify: `hypr/.config/hypr/hyprland.conf`

This task stands up the overlay with placeholder page content (real pages come in
Tasks 4-9). Clone the overlay skeleton from `modules/Overview.qml`.

- [ ] **Step 1: `modules/Settings.qml`** (overlay — clone Overview pattern)

```qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import "settings"

Scope {
    id: root
    property bool open: false
    function toggle(): void { open = !open; }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open; }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.open
            property bool shown: false
            onVisibleChanged: shown = visible
            onShownChanged: if (shown) content.forceActiveFocus()

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: panel.shown ? 1 : 0
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
                MouseArea { anchors.fill: parent; onClicked: root.open = false }
            }

            SettingsContent {
                id: content
                focus: true
                Keys.onEscapePressed: root.open = false
                anchors.centerIn: parent
                opacity: panel.shown ? 1 : 0
                scale: panel.shown ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on opacity { CAnim { duration: Theme.anim.durations.normal } }
                Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }
                onRequestClose: root.open = false
            }
        }
    }
}
```

- [ ] **Step 2: `modules/settings/widgets/NavButton.qml`**

```qml
import QtQuick
import qs.components

Item {
    id: btn
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    implicitWidth: parent ? parent.width : 140
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.normal
        color: btn.active ? Theme.surfaceContainerHigh : "transparent"
    }
    // StateLayer exposes only `pressed`/`focused`/`hovered` (no clicked signal) —
    // drive `pressed` from a TapHandler, the repo-wide idiom.
    TapHandler { id: navTap; onTapped: btn.clicked() }
    StateLayer { pressed: navTap.pressed }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.padding.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.normal
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.icon
            font.pixelSize: Theme.icon.size.normal
            color: btn.active ? Theme.primary : Theme.textVariant
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            color: btn.active ? Theme.text : Theme.textVariant
            font.pixelSize: Theme.font.size.normal
        }
    }
}
```

(`StateLayer` is a `Rectangle` exposing `pressed`/`focused`/`hovered` only — confirmed.
The `TapHandler` above provides the click + feeds the press tint.)

- [ ] **Step 3: `modules/settings/SettingsContent.qml`** (card + nav + page loader)

```qml
import QtQuick
import Quickshell
import qs.components
import "widgets"

Item {
    id: root
    signal requestClose()

    readonly property var pages: [
        { name: "Appearance", icon: "palette", source: "pages/AppearancePage.qml" },
        { name: "Bar",        icon: "toolbar",  source: "pages/BarPage.qml" },
        { name: "Dock",       icon: "dock",     source: "pages/DockPage.qml" },
        { name: "Overview",   icon: "grid_view",source: "pages/OverviewPage.qml" },
        { name: "Behavior",   icon: "tune",     source: "pages/BehaviorPage.qml" },
        { name: "About",      icon: "info",     source: "pages/AboutPage.qml" }
    ]
    property int currentPage: 0

    implicitWidth: Math.min(900, Screen.width - 80)
    implicitHeight: Math.min(620, Screen.height - 80)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.large
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            Item {
                width: parent.width
                height: 56
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.padding.larger
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.normal
                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "settings"; font.pixelSize: Theme.icon.size.large; color: Theme.text
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Settings"; color: Theme.text
                        font.pixelSize: Theme.font.size.large; font.weight: Theme.font.weight.title
                    }
                }
                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 36
                    Rectangle { anchors.fill: parent; radius: Theme.radius.full; color: "transparent" }
                    MaterialIcon { anchors.centerIn: parent; text: "close"; font.pixelSize: Theme.icon.size.normal; color: Theme.textVariant }
                    MouseArea { anchors.fill: parent; onClicked: root.requestClose() }
                }
            }
        }

        Row {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.padding.large
            spacing: Theme.spacing.large

            Column {
                id: navRail
                width: 150
                height: parent.height
                spacing: Theme.spacing.smaller
                Repeater {
                    model: root.pages
                    NavButton {
                        required property var modelData
                        required property int index
                        width: navRail.width
                        icon: modelData.icon
                        label: modelData.name
                        active: root.currentPage === index
                        onClicked: root.currentPage = index
                    }
                }
            }

            Rectangle {
                width: parent.width - navRail.width - Theme.spacing.large
                height: parent.height
                radius: Theme.radius.normal
                color: Theme.surfaceContainerLow
                clip: true
                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: Theme.padding.large
                    source: Config.ready ? root.pages[root.currentPage].source : ""
                }
            }
        }
    }
}
```

Note: page sources don't exist yet — until Tasks 4-9 the `Loader` will fail to load
missing files. For THIS task, temporarily point all `source` entries at a single
placeholder you create at `modules/settings/pages/_Placeholder.qml` (a `StyledText {
text: "TODO" }`), OR leave `source` empty and add the real per-page sources as each
page task lands. Use the placeholder approach so the overlay is verifiable now; later
tasks replace the source strings with the real page paths.

- [ ] **Step 4: `modules/settings/pages/_Placeholder.qml`** (temporary)

```qml
import QtQuick
import qs.components
StyledText { text: "Settings page"; color: Theme.textVariant; font.pixelSize: Theme.font.size.normal }
```

(Set all `pages[].source` to `"pages/_Placeholder.qml"` for now.)

- [ ] **Step 5: qmldir files**

`modules/settings/qmldir`:
```
module qs.modules.settings
SettingsContent 1.0 SettingsContent.qml
```

`modules/settings/widgets/qmldir`:
```
module qs.modules.settings.widgets
NavButton 1.0 NavButton.qml
```

(Add page/widget entries as later tasks create them. `Settings.qml` imports the
subdir via relative `import "settings"`; `SettingsContent.qml` imports widgets via
relative `import "widgets"`; pages will import widgets via `import "../widgets"`.)

- [ ] **Step 6: Instantiate in `shell.qml`**

Add `Settings {}` right after `Overview {}`:

```qml
    Overview {}
    Settings {}
```

- [ ] **Step 7: Keybind in `hypr/.config/hypr/hyprland.conf`**

Add after the `overview` bind (line ~148):

```
bind = $mainMod, comma, exec, qs ipc call settings toggle
```

- [ ] **Step 8: Validate**

Run validation. Then:
- `qs ipc show` (or `qs ipc call settings toggle`) → target `settings` listed with
  `toggle`/`open`/`close`.
- `qs ipc call settings open` then `qs ipc call settings close` → no errors in log.
- Confirm no QML errors loading `Settings.qml`/`SettingsContent.qml`/`NavButton.qml`.

Interactive (note for user): Super+comma opens the overlay; nav buttons switch the
(placeholder) page; Esc / scrim-click / close button dismiss it.

- [ ] **Step 9: Commit**

```bash
git add quickshell/.config/quickshell/modules/Settings.qml \
        quickshell/.config/quickshell/modules/settings/ \
        quickshell/.config/quickshell/shell.qml \
        hypr/.config/hypr/hyprland.conf
git commit -m "add settings overlay with navigation rail and page frame"
```

---

### Task 4: Setting control widgets + Appearance page (live)

**Files:**
- Create: `modules/settings/widgets/SettingSection.qml`
- Create: `modules/settings/widgets/SettingSwitch.qml`
- Create: `modules/settings/widgets/SettingSlider.qml`
- Create: `modules/settings/widgets/SettingSelect.qml`
- Create: `modules/settings/widgets/SettingText.qml`
- Create: `modules/settings/pages/AppearancePage.qml`
- Modify: `modules/settings/widgets/qmldir` (add the 5 widgets)
- Modify: `modules/settings/SettingsContent.qml` (point Appearance source at the real page)

- [ ] **Step 1: `SettingSection.qml`**

```qml
import QtQuick
import qs.components

Column {
    id: root
    property string title: ""
    default property alias content: inner.data
    width: parent ? parent.width : 400
    spacing: Theme.spacing.small

    StyledText {
        text: root.title
        color: Theme.text
        font.pixelSize: Theme.font.size.large
        font.weight: Theme.font.weight.title
        visible: root.title !== ""
    }
    Column {
        id: inner
        width: parent.width
        spacing: Theme.spacing.smaller
    }
}
```

- [ ] **Step 2: `SettingSwitch.qml`** (label + StyledSwitch; writes on `onToggled`)

```qml
import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled(bool value)
    width: parent ? parent.width : 400
    implicitHeight: 44

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    StyledSwitch {
        id: sw
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        onToggled: root.toggled(checked)
    }
}
```

- [ ] **Step 3: `SettingSlider.qml`** (label + StyledSlider + value readout; `onMoved`)

```qml
import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property string suffix: ""
    property int decimals: 0
    signal moved(real value)
    width: parent ? parent.width : 400
    implicitHeight: 52

    StyledText {
        id: lbl
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
        width: 160
        elide: Text.ElideRight
    }
    StyledText {
        id: readout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        horizontalAlignment: Text.AlignRight
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.small
    }
    StyledSlider {
        id: slider
        anchors.left: lbl.right
        anchors.right: readout.left
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        anchors.verticalCenter: parent.verticalCenter
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: root.moved(value)
    }
}
```

- [ ] **Step 4: `SettingSelect.qml`** (segmented choices; emits `selected`)

```qml
import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property var options: []        // [{ label, value }]
    property var currentValue: null
    signal selected(var value)
    width: parent ? parent.width : 400
    implicitHeight: 44

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.smaller
        Repeater {
            model: root.options
            Item {
                required property var modelData
                readonly property bool sel: root.currentValue === modelData.value
                implicitWidth: segText.implicitWidth + 2 * Theme.padding.large
                implicitHeight: 32
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.full
                    color: parent.sel ? Theme.primary : Theme.surfaceContainerHigh
                    border.color: parent.sel ? Theme.primary : Theme.outline
                    border.width: 1
                }
                StyledText {
                    id: segText
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.sel ? Theme.textOnPrimary : Theme.textVariant
                    font.pixelSize: Theme.font.size.small
                }
                MouseArea { anchors.fill: parent; onClicked: root.selected(modelData.value) }
            }
        }
    }
}
```

- [ ] **Step 5: `SettingText.qml`** (labeled text field; writes on editing finished)

```qml
import QtQuick
import QtQuick.Controls
import qs.components

Item {
    id: root
    property string label: ""
    property string text: ""
    signal edited(string value)
    width: parent ? parent.width : 400
    implicitHeight: 48

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 200
        height: 34
        radius: Theme.radius.small
        color: Theme.surfaceContainerHigh
        border.color: field.activeFocus ? Theme.primary : Theme.outline
        border.width: 1
        TextField {
            id: field
            anchors.fill: parent
            anchors.margins: 2
            leftPadding: Theme.padding.normal
            text: root.text
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family.sans
            background: null
            onEditingFinished: root.edited(text)
        }
    }
}
```

(Focus border `Theme.primary` per the re-skin fix — NOT a state-layer tint.)

- [ ] **Step 6: `pages/AppearancePage.qml`** (the worked template for all pages)

```qml
import QtQuick
import qs.components
import "../widgets"

Flickable {
    id: page
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: page.width
        spacing: Theme.spacing.extraLarge

        SettingSection {
            title: "Typography"
            SettingText {
                label: "UI font"
                text: Config.options.appearance.fontFamily
                onEdited: value => Config.options.appearance.fontFamily = value
            }
            SettingSlider {
                label: "Font scale"
                from: 0.85; to: 1.25; stepSize: 0.05; decimals: 2
                value: Config.options.appearance.fontScale
                onMoved: v => Config.options.appearance.fontScale = v
            }
        }
        SettingSection {
            title: "Shape & motion"
            SettingSlider {
                label: "Roundness"
                from: 0.5; to: 1.5; stepSize: 0.05; decimals: 2
                value: Config.options.appearance.radiusScale
                onMoved: v => Config.options.appearance.radiusScale = v
            }
            SettingSlider {
                label: "Motion speed"
                from: 0.5; to: 2.0; stepSize: 0.1; decimals: 1; suffix: "x"
                value: Config.options.appearance.motionScale
                onMoved: v => Config.options.appearance.motionScale = v
            }
        }
    }
}
```

- [ ] **Step 7: Register widgets in `widgets/qmldir`** (append)

```
SettingSection 1.0 SettingSection.qml
SettingSwitch 1.0 SettingSwitch.qml
SettingSlider 1.0 SettingSlider.qml
SettingSelect 1.0 SettingSelect.qml
SettingText 1.0 SettingText.qml
```

- [ ] **Step 8: Wire the Appearance source in `SettingsContent.qml`**

Change the Appearance entry's `source` from `"pages/_Placeholder.qml"` to
`"pages/AppearancePage.qml"`.

- [ ] **Step 9: Validate**

Run validation. Open settings (`qs ipc call settings open`), no errors loading
`AppearancePage` or the widgets. Then verify persistence round-trip: with the shell
running, `qs ipc call settings open`, and manually edit
`~/.local/state/quickshell/settings.json` setting `appearance.fontScale` to `1.2` →
the JSON reload (`watchChanges`) should not error. Reset to 1.0.

Interactive (note for user): drag Font scale → text across the shell rescales live;
Roundness → corners change; Motion speed → animation timing changes; all persist
across `qs kill`/relaunch.

- [ ] **Step 10: Commit**

```bash
git add quickshell/.config/quickshell/modules/settings/
git commit -m "add setting control widgets and live Appearance page"
```

---

### Task 5: Bar page + bar consumer rewiring

**Files:**
- Create: `modules/settings/pages/BarPage.qml`
- Modify: `modules/bar/TopBar.qml` (height bind + RowLayout pill groups + per-pill visibility)
- Modify: `modules/bar/ClockPill.qml` (clock format)
- Modify: `modules/settings/SettingsContent.qml` (Bar source)
- Modify: `modules/settings/pages/qmldir` if one is added (else none — pages loaded by path)

**Context — TopBar is a 3-zone layout:** left group (launcher, workspaces, media),
centered clock, right group (resources, tray, status). The pills are positioned by a
manual `x`-chain that does NOT collapse when a pill is hidden. Convert each side group
to a `RowLayout` (auto-centers children vertically, excludes `visible:false` children
and their spacing). Keep the clock centered and standalone. `PeekState` still
references the pill ids for hover, so they must remain children with their ids intact.

- [ ] **Step 1: TopBar height ← Config**

In `modules/bar/TopBar.qml`, change line 12:
```qml
readonly property int pillHeight: Config.options.bar.height
```
(`panelHeight` already derives from `pillHeight`.) Ensure `import qs.components` is
present (it is, line 5).

- [ ] **Step 2: Convert pill layout to RowLayout groups**

Add `import QtQuick.Layouts` AND `import qs.services` to the imports (the latter is
needed because MediaPill/TrayPill visibility must AND with their runtime-availability
services — see below). Replace the `pillRow` `Item` body (current lines 42-93 — the
seven pills with manual `x`) with:

```qml
    Item {
        id: pillRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: panel.edgeMargin
        anchors.rightMargin: panel.edgeMargin
        height: panel.pillHeight
        y: peek.slideFromY

        RowLayout {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            LauncherPill   { id: launcher;   visible: Config.options.bar.showLauncher;   Layout.alignment: Qt.AlignVCenter }
            WorkspacesPill { id: workspaces; visible: Config.options.bar.showWorkspaces; Layout.alignment: Qt.AlignVCenter }
            MediaPill      { id: media;      visible: Config.options.bar.showMedia && MprisService.hasPlayer; Layout.alignment: Qt.AlignVCenter }
        }

        ClockPill {
            id: clock
            visible: Config.options.bar.showClock
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width / 2
        }

        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            ResourcesPill { id: resources; visible: Config.options.bar.showResources; Layout.alignment: Qt.AlignVCenter }
            TrayPill      { id: tray;      visible: Config.options.bar.showTray && TrayService.count > 0; Layout.alignment: Qt.AlignVCenter }
            StatusPill    { id: status;    visible: Config.options.bar.showStatus;    Layout.alignment: Qt.AlignVCenter }
        }
    }
```

Notes for the implementer:
- **MediaPill and TrayPill carry their own runtime-availability `visible` condition**
  (`MediaPill.qml:12` → `visible: MprisService.hasPlayer`; `TrayPill.qml:13` →
  `visible: TrayService.count > 0`). A call-site `visible:` overrides the component's,
  so the toggle MUST be ANDed with the runtime condition (as written above) or those
  pills would show empty. The other five pills have no root-level `visible` condition,
  so a plain `Config.options.bar.show*` is correct for them.
- Pills previously set `anchors.verticalCenter`/`x` at the call site; inside a
  RowLayout those are replaced by `Layout.alignment` (the pill component files
  themselves set no `anchors`/`x`/`width`, so no "anchors inside Layout" warning is
  expected — verified). Read a pill file only if a warning does appear.
- `PeekState.watchedItems` (line 101) and the per-pill `Connections` (lines 105-132)
  still reference `launcher/workspaces/media/clock/resources/tray/status` — leave
  them; the ids still exist. If a hidden (`visible:false`) pill's `hovered` is read,
  that's harmless (false).
- If any pill lacks a `hovered` property when not the expected type, keep as-is —
  no change to the Connections block.

- [ ] **Step 3: ClockPill format ← Config**

In `modules/bar/ClockPill.qml` line 16, change the format string:
```qml
text: Time.now ? Qt.formatDateTime(Time.now, Config.options.bar.clock24h ? "HH:mm" : "hh:mm AP") : "--:--"
```
Add `import qs.components` if not present (it is, line 3).

- [ ] **Step 4: `pages/BarPage.qml`** (follow AppearancePage structure)

A `Flickable`+`Column` of `SettingSection`s with these controls (all two-way bound to
`Config.options.bar.*`, writing on `onMoved`/`onToggled`/`selected`):

| Section | Control | Type | Config path | params |
|---|---|---|---|---|
| Layout | Bar height | SettingSlider | `bar.height` | from 24 to 48, step 1, decimals 0, suffix " px" |
| Layout | Clock format | SettingSelect | `bar.clock24h` | options `[{label:"24h",value:true},{label:"12h",value:false}]` |
| Pills | Launcher | SettingSwitch | `bar.showLauncher` | |
| Pills | Workspaces | SettingSwitch | `bar.showWorkspaces` | |
| Pills | Media | SettingSwitch | `bar.showMedia` | |
| Pills | Clock | SettingSwitch | `bar.showClock` | |
| Pills | Resources | SettingSwitch | `bar.showResources` | |
| Pills | Tray | SettingSwitch | `bar.showTray` | |
| Pills | Status | SettingSwitch | `bar.showStatus` | |

Example control (height) for reference:
```qml
SettingSlider {
    label: "Bar height"; suffix: " px"
    from: 24; to: 48; stepSize: 1; decimals: 0
    value: Config.options.bar.height
    onMoved: v => Config.options.bar.height = v
}
```
SettingSelect for clock format:
```qml
SettingSelect {
    label: "Clock format"
    options: [{ label: "24h", value: true }, { label: "12h", value: false }]
    currentValue: Config.options.bar.clock24h
    onSelected: v => Config.options.bar.clock24h = v
}
```

- [ ] **Step 5: Wire Bar source** in `SettingsContent.qml` (`"pages/BarPage.qml"`).

- [ ] **Step 6: Validate**

Run validation. No errors loading BarPage or the rewired TopBar/ClockPill. Grep for
RowLayout/anchors conflict warnings (`Cannot specify anchors for items inside
Layout`) — if present, remove the offending child anchors. `qs ipc call settings
open` clean.

Interactive (note for user): Bar height slider resizes the strip; toggling each pill
hides it and the group collapses (no gap); clock format toggles 24h/12h; all persist.

- [ ] **Step 7: Commit**

```bash
git add quickshell/.config/quickshell/modules/bar/TopBar.qml \
        quickshell/.config/quickshell/modules/bar/ClockPill.qml \
        quickshell/.config/quickshell/modules/settings/
git commit -m "make bar height, clock format, and pill visibility configurable"
```

---

### Task 6: Dock page + dock consumer rewiring (enable / height / icon size / auto-hide)

**Files:**
- Create: `modules/settings/pages/DockPage.qml`
- Modify: `modules/bar/PeekState.qml` (add `pinned` property)
- Modify: `modules/Dock.qml` (enable / height / autoHide)
- Modify: `modules/dock/DockAppButton.qml` (icon size)
- Modify: `modules/settings/SettingsContent.qml` (Dock source)

- [ ] **Step 1: Add `pinned` to `PeekState.qml`**

`PeekState` animates `slideTarget.y` imperatively, so a binding can't pin the dock
open. Add a `pinned` flag that keeps it revealed. In `modules/bar/PeekState.qml`:

Add the property (after `dwellMs`, line ~30):
```qml
    property bool pinned: false
```
Guard `_maybeExit()` — insert as the first statement of the function body (the
signature `function _maybeExit(): void {` is at line 41; lines 42-43 are a comment
inside the body — put the guard right after the opening brace, before that comment):
```qml
        if (pinned) return;
```
Add a handler + initial reveal (anywhere at the object root, e.g. before
`notifyWatchedHoverChanged`):
```qml
    onPinnedChanged: { if (pinned) _enter(); else _maybeExit(); }
    property Connections _initConn: Connections {
        target: peek
        Component.onCompleted: if (peek.pinned) peek._enter();
    }
```
(The bar leaves `pinned` default `false` → unchanged behavior.)

- [ ] **Step 2: Dock enable / height ← Config**

In `modules/Dock.qml`:
- Gate visibility — change the `PanelWindow` to add:
  ```qml
  visible: Config.options.dock.enable
  ```
  (add right after `screen: modelData`, line ~21). `import qs.components` is present
  (line 5).
- Height — change line 23:
  ```qml
  readonly property int dockHeight: Config.options.dock.height
  ```
  (`panelHeight` derives from it.)

- [ ] **Step 3: Dock auto-hide ← Config (pin when disabled)**

In `modules/Dock.qml`, on the `PeekState` block (lines 70-78), add:
```qml
                pinned: !Config.options.dock.autoHide
```
When `autoHide` is false, `pinned` becomes true → the dock reveals and never hides;
the existing `mask` (line 84-89) already returns the full panel region when
`!peek.fullyHidden`, so the dock stays interactive.

- [ ] **Step 4: Dock icon size ← Config**

In `modules/dock/DockAppButton.qml`, replace `Theme.icon.size.larger` with
`Config.options.dock.iconSize` at the three sizing sites:
- line 15: `implicitWidth: Config.options.dock.iconSize + 2 * Theme.padding.small`
- line 16: `implicitHeight: Config.options.dock.iconSize + 2 * Theme.padding.small`
- line 24: `width: Config.options.dock.iconSize`

Leave the fallback `MaterialIcon` glyph size (line 36, `Theme.icon.size.large`) as-is.
`import qs.components` is present (line 3).

- [ ] **Step 5: `pages/DockPage.qml`**

| Section | Control | Type | Config path | params |
|---|---|---|---|---|
| Dock | Enable dock | SettingSwitch | `dock.enable` | |
| Dock | Auto-hide | SettingSwitch | `dock.autoHide` | |
| Dock | Dock height | SettingSlider | `dock.height` | from 40 to 96, step 2, decimals 0, suffix " px" |
| Dock | Icon size | SettingSlider | `dock.iconSize` | from 24 to 64, step 2, decimals 0, suffix " px" |

Bind/write pattern identical to BarPage.

- [ ] **Step 6: Wire Dock source** in `SettingsContent.qml`.

- [ ] **Step 7: Validate**

Run validation. No errors. Confirm the bar (which also uses PeekState) still loads and
peeks (pinned defaults false). `qs ipc call settings open` clean.

Interactive (note for user): toggle Enable dock → dock appears/disappears; Auto-hide
off → dock stays revealed and clickable; height/icon sliders resize live; persist.

- [ ] **Step 8: Commit**

```bash
git add quickshell/.config/quickshell/modules/bar/PeekState.qml \
        quickshell/.config/quickshell/modules/Dock.qml \
        quickshell/.config/quickshell/modules/dock/DockAppButton.qml \
        quickshell/.config/quickshell/modules/settings/
git commit -m "make dock enable, size, icons, and auto-hide configurable"
```

---

### Task 7: Overview page + overview consumer rewiring

**Files:**
- Create: `modules/settings/pages/OverviewPage.qml`
- Modify: `modules/overview/OverviewGrid.qml` (scale / rows / columns)
- Modify: `modules/settings/SettingsContent.qml` (Overview source)

- [ ] **Step 1: OverviewGrid ← Config**

In `modules/overview/OverviewGrid.qml`, change lines 18-20:
```qml
readonly property real wsScale: Config.options.overview.scale
readonly property int rows: Config.options.overview.rows
readonly property int columns: Config.options.overview.columns
```
Leave `spacing` (line 21) literal. `import qs.components` present (line 5). All three
feed `cellWidth`/`cellHeight`/the workspace model reactively.

- [ ] **Step 2: `pages/OverviewPage.qml`**

| Section | Control | Type | Config path | params |
|---|---|---|---|---|
| Layout | Workspace scale | SettingSlider | `overview.scale` | from 0.10 to 0.30, step 0.01, decimals 2 |
| Layout | Rows | SettingSlider | `overview.rows` | from 1 to 3, step 1, decimals 0 |
| Layout | Columns | SettingSlider | `overview.columns` | from 3 to 8, step 1, decimals 0 |

- [ ] **Step 3: Wire Overview source** in `SettingsContent.qml`.

- [ ] **Step 4: Validate**

Run validation. No errors. `qs ipc call overview toggle` still works; open settings →
Overview page renders.

Interactive (note for user): change rows/columns/scale → open overview (Super+grave)
→ grid re-lays-out to the new geometry; persist.

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/modules/overview/OverviewGrid.qml \
        quickshell/.config/quickshell/modules/settings/
git commit -m "make overview grid dimensions configurable"
```

---

### Task 8: Behavior page + notification/night-light rewiring

**Files:**
- Create: `modules/settings/pages/BehaviorPage.qml`
- Modify: `modules/Notifications.qml` (maxVisible, fallback timeout)
- Modify: `services/NotificationHistory.qml` (history limit, DND seed)
- Modify: `services/Hyprsunset.qml` (night temp seed + re-apply)
- Modify: `modules/settings/SettingsContent.qml` (Behavior source)

- [ ] **Step 1: Notifications**

In `modules/Notifications.qml`:
- Line 11: `readonly property int maxVisible: Config.options.behavior.notifMaxVisible`
- The dwell fallback literal `5000` (~line 198, `expireTimeout > 0 ? expireTimeout :
  5000`): replace `5000` with `Config.options.behavior.notifTimeout`.
`import qs.components` present (line 5).

- [ ] **Step 2: NotificationHistory**

In `services/NotificationHistory.qml`:
- Add `import qs.components` to the imports.
- Line 12: `readonly property int historyLimit: Config.options.behavior.notifHistoryMax`
- Line 14 (`property bool doNotDisturb: false`): keep the declaration, seed it once —
  add at the Singleton root:
  ```qml
  Component.onCompleted: doNotDisturb = Config.options.behavior.dndDefault;
  ```
  (Seed only — a binding would fight live DND toggles elsewhere.)

- [ ] **Step 3: Hyprsunset night temp (seed + re-apply, NOT a binding)**

In `services/Hyprsunset.qml`:
- Add `import qs.components` to the imports.
- Keep `property int temperature: 4000` (line 11) as-is (it's imperatively
  reassigned; binding it would break).
- Seed + re-apply — add at the Singleton root:
  ```qml
  Component.onCompleted: root.temperature = Config.options.behavior.nightTemp;
  Connections {
      target: Config.options.behavior
      function onNightTempChanged() { root.setTemperature(Config.options.behavior.nightTemp); }
  }
  ```
  (`setTemperature` already re-launches hyprsunset when `active`, so a live change
  re-applies; when inactive it just updates the stored value for next toggle.)
  `target: Config.options.behavior` with `function onNightTempChanged()` is the
  correct, verified form — a JsonAdapter nested JsonObject property DOES emit a
  `<prop>Changed` signal usable as a Connections target. Do NOT use an
  underscore-prefixed proxy property (`property int _nt` + `on_ntChanged`) — leading
  underscores break QML change-handler name resolution and won't compile. If a
  non-underscore proxy is ever needed, name it `ntProxy` (`onNtProxyChanged`).

- [ ] **Step 4: `pages/BehaviorPage.qml`**

| Section | Control | Type | Config path | params |
|---|---|---|---|---|
| Notifications | On-screen timeout | SettingSlider | `behavior.notifTimeout` | from 2000 to 15000, step 500, decimals 0, suffix " ms" |
| Notifications | Max on screen | SettingSlider | `behavior.notifMaxVisible` | from 1 to 10, step 1, decimals 0 |
| Notifications | History limit | SettingSlider | `behavior.notifHistoryMax` | from 10 to 200, step 10, decimals 0 |
| Notifications | Do not disturb on startup | SettingSwitch | `behavior.dndDefault` | |
| Night light | Default temperature | SettingSlider | `behavior.nightTemp` | from 2500 to 6500, step 100, decimals 0, suffix " K" |

- [ ] **Step 5: Wire Behavior source** in `SettingsContent.qml`.

- [ ] **Step 6: Validate**

Run validation. No errors loading the page or the rewired services. Grep specifically
for Hyprsunset `Connections` target errors; if present, apply the fallback from Step 3.

Interactive (note for user): night-temp slider with night light active re-applies the
temperature; notification timeout/max/history affect new notifications; persist.

- [ ] **Step 7: Commit**

```bash
git add quickshell/.config/quickshell/modules/Notifications.qml \
        quickshell/.config/quickshell/services/NotificationHistory.qml \
        quickshell/.config/quickshell/services/Hyprsunset.qml \
        quickshell/.config/quickshell/modules/settings/
git commit -m "make notification and night-light behavior configurable"
```

---

### Task 9: About page + sidebar gear entry point

**Files:**
- Create: `modules/settings/pages/AboutPage.qml`
- Modify: `modules/sidebar/SidebarRightContent.qml` (add gear button → opens settings)
- Modify: `modules/settings/SettingsContent.qml` (About source)
- Remove: `modules/settings/pages/_Placeholder.qml` (temporary file from Task 3)

- [ ] **Step 1: `pages/AboutPage.qml`**

A `Column` with: shell name/title; static version text ("Quickshell 0.3.0 · Qt
6.10.3"); the config path with a copy affordance; a note. Example:

```qml
import QtQuick
import Quickshell
import qs.components

Column {
    width: parent.width
    spacing: Theme.spacing.large

    StyledText { text: "Quickshell dotfiles shell"; color: Theme.text; font.pixelSize: Theme.font.size.large; font.weight: Theme.font.weight.title }
    StyledText { text: "Quickshell 0.3.0 · Qt 6.10.3"; color: Theme.textVariant; font.pixelSize: Theme.font.size.normal }

    StyledText { text: "Settings file (hand-editable, picked up live):"; color: Theme.textVariant; font.pixelSize: Theme.font.size.small }
    Row {
        spacing: Theme.spacing.normal
        StyledText {
            id: pathText
            text: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"
            color: Theme.text; font.pixelSize: Theme.font.size.normal; font.family: Theme.font.family.mono
        }
        MaterialIcon {
            text: "content_copy"; font.pixelSize: Theme.icon.size.small; color: Theme.textVariant
            MouseArea { anchors.fill: parent; onClicked: Quickshell.clipboardText = pathText.text }
        }
    }
    StyledText { text: "Delete the file to restore all defaults."; color: Theme.textMuted; font.pixelSize: Theme.font.size.small }
}
```

- [ ] **Step 2: Sidebar gear button**

Read `modules/sidebar/SidebarRightContent.qml` and add a small gear icon button in its
header area (top of the content). On click, open the settings overlay via IPC:
```qml
MouseArea {
    // inside a 32x32 icon Item with a MaterialIcon { text: "settings" }
    anchors.fill: parent
    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "open"])
}
```
Match the existing icon-button styling in that header (use the same Item/MaterialIcon/
StateLayer idiom already present). Ensure `import Quickshell` is available for
`execDetached`.

- [ ] **Step 3: Wire About source** in `SettingsContent.qml`, and **delete the
temporary placeholder**: `git rm
quickshell/.config/quickshell/modules/settings/pages/_Placeholder.qml`. Confirm no
`pages[].source` still points at `_Placeholder.qml` (all six now point at real pages).

- [ ] **Step 4: Validate**

Run validation. All six pages load without error; nav cycles through all of them;
`_Placeholder.qml` is gone and nothing references it.

Interactive (note for user): the sidebar gear opens settings; About shows the path and
copy works.

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/modules/settings/ \
        quickshell/.config/quickshell/modules/sidebar/SidebarRightContent.qml
git rm quickshell/.config/quickshell/modules/settings/pages/_Placeholder.qml
git commit -m "add about page and sidebar settings entry point"
```

---

## Final verification (after all tasks)

- [ ] `qs -p ~/.config/quickshell` loads clean; `qs ipc show` lists `settings` with
  `toggle`/`open`/`close`.
- [ ] All six pages render; nav switches between them; Esc / scrim / close / gear all
  work; Super+comma toggles.
- [ ] `~/.local/state/quickshell/settings.json` exists, valid JSON, full default tree,
  NOT in `git status`.
- [ ] Every exposed setting round-trips: change in UI → JSON updates → persists across
  `qs kill` + relaunch.
- [ ] At default values (all scales 1.0, all defaults) the shell is visually identical
  to pre-change (Theme bases unchanged).
- [ ] No binding-loop warnings; no `is not a type`/`undefined`/anchors-in-Layout
  errors.
- [ ] Dispatch the final whole-branch code review (superpowers:requesting-code-review),
  then finish via superpowers:finishing-a-development-branch (PR + merge).
```
