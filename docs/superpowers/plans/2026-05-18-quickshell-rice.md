# Quickshell Rice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current caelestia-style vertical-left-dock quickshell config with floating pills (TopBar + BottomBar) on opaque black palette, hidden by default, peek-on-hover per edge, primary monitor only.

**Architecture:** Two `PanelWindow` instances per primary screen — TopBar holds 4 pills (launcher, workspaces, claude usage, clock), BottomBar holds 1 pill (status). Each window owns its own peek FSM that animates `y` offset and computes input `mask`. `ExclusionMode.Ignore` so windows tile full-screen and pills float above. New `ClaudeUsage` service singleton polls the existing `~/.claude/fetch-usage.sh` cache.

**Tech Stack:** Quickshell 0.3.0, QML / Qt6, Hyprland 0.55.2, Material Icons, JetBrains Mono. Spec: `docs/superpowers/specs/2026-05-18-quickshell-rice-design.md` (commit `4d2b7a8`).

**Working directory:** `~/dotfiles/` repo. All paths below are relative to this repo root unless absolute.

**Live quickshell instance:** PID 321061, config `~/.config/quickshell/shell.qml` (symlink → `dotfiles/quickshell/.config/quickshell/shell.qml` via stow).

---

## Smoke pattern (used at every reload-affecting commit)

After any commit that touches files already loaded by `shell.qml`, run this verification block:

```bash
# kill live quickshell and respawn (Hyprland's exec-once won't re-run)
qs kill -a 2>&1 ; sleep 1
qs -d 2>&1 ; sleep 2
# tail the most recent log; look for ERROR/WARN lines added since restart
qs log --follow 2>&1 &
LOG_PID=$!
sleep 5
kill $LOG_PID
```

Read the log output. Acceptable warnings (pre-existing):
- `Could not register notification server` (other notification daemon already up — pre-existing)
- `Battery.qml ... BAT0 ... File does not exist` (on pavg15; expected per spec)
- `Could not attach Keys property to: ... WaylandPanelInterface_QML_41 is not an Item` (pre-existing quickshell warning)
- `Illegal escape sequence in desktop entry exec string` (swappy entry; pre-existing)

Anything else — especially `QML ... Error:` or `TypeError:` — is a regression and the task is not complete.

Tasks that only add files *not yet imported by `shell.qml`* (Tasks 1-10) skip the smoke block — those files are inert until wired in Task 11. They still get committed with a syntactic visual review.

---

## File Structure

```
quickshell/.config/quickshell/
  shell.qml                                unchanged
  components/
    Theme.qml                              unchanged
    StyledRect.qml                         unchanged
    StyledText.qml                         unchanged
    MaterialIcon.qml                       unchanged
    StateLayer.qml                         unchanged
    Anim.qml                               unchanged
    CAnim.qml                              unchanged
    qmldir                                 unchanged
  services/
    Time.qml          Audio.qml            unchanged
    Network.qml       Battery.qml          unchanged
    ClaudeUsage.qml                        NEW   (Task 1)
    qmldir                                 MODIFY (Task 1)
  modules/
    Bar.qml                                REPLACE (Task 11)
    bar/
      Pill.qml                             NEW (Task 2)
      PeekState.qml                        NEW (Task 3)
      LauncherPill.qml                     NEW (Task 4)
      WorkspacesPill.qml                   NEW (Task 5)
      ClockPill.qml                        NEW (Task 6)
      ClaudePill.qml                       NEW (Task 7)
      StatusPill.qml                       NEW (Task 8)
      TopBar.qml                           NEW (Task 9)
      BottomBar.qml                        NEW (Task 10)
      OsIcon.qml                           DELETE (Task 11)
      Workspaces.qml                       DELETE (Task 11)
      Clock.qml                            DELETE (Task 11)
      StatusIcons.qml                      DELETE (Task 11)
      PowerButton.qml                      DELETE (Task 11)
    Launcher.qml                           PATCH (Task 12)
    Notifications.qml                      PATCH (Task 12)
    Osd.qml                                PATCH (Task 12)
    Clipboard.qml                          PATCH (Task 13)
    Power.qml                              PATCH (Task 13)
    EmojiPicker.qml                        PATCH (Task 13)
    PassMenu.qml                           PATCH (Task 14)
    TagInput.qml                           PATCH (Task 14)
    WindowPicker.qml                       PATCH (Task 14)
hypr/.config/hypr/hyprland.conf            PATCH (Task 15)
```

---

## Task 1: Add `ClaudeUsage` service singleton

**Files:**
- Create: `quickshell/.config/quickshell/services/ClaudeUsage.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

- [ ] **Step 1.1: Write `ClaudeUsage.qml`**

```qml
// quickshell/.config/quickshell/services/ClaudeUsage.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real sessionPct: 0
    property real weeklyPct: 0
    property string sessionResetIso: ""
    property string weeklyResetIso: ""
    property string status: "ok"      // ok | warning | critical | error
    property string errorKind: ""

    function severity(pct: real): string {
        if (pct >= 80) return "critical";
        if (pct >= 50) return "warning";
        return "ok";
    }

    function _parse(text: string): void {
        try {
            const d = JSON.parse(text);
            if (d.error) {
                root.status = "error";
                root.errorKind = d.error;
                return;
            }
            root.sessionPct = parseFloat(d.sessionUsage ?? 0);
            root.weeklyPct = parseFloat(d.weeklyUsage ?? 0);
            root.sessionResetIso = d.sessionResetAt ?? "";
            root.weeklyResetIso = d.weeklyResetAt ?? "";
            root.status = severity(Math.max(root.sessionPct, root.weeklyPct));
            root.errorKind = "";
        } catch (e) {
            root.status = "error";
            root.errorKind = "parse";
        }
    }

    Process {
        id: proc
        command: ["bash", "-c", "source \"$HOME/.claude/fetch-usage.sh\"; fetch_usage_data"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    Timer {
        interval: 600000             // 10 minutes — matches fetch-usage.sh CACHE_MAX_AGE
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
```

- [ ] **Step 1.2: Append singleton to `services/qmldir`**

Current contents:
```
module qs.services
singleton Time 1.0 Time.qml
singleton Audio 1.0 Audio.qml
singleton Battery 1.0 Battery.qml
singleton Network 1.0 Network.qml
```

Add this line at the end:
```
singleton ClaudeUsage 1.0 ClaudeUsage.qml
```

Final file:
```
module qs.services
singleton Time 1.0 Time.qml
singleton Audio 1.0 Audio.qml
singleton Battery 1.0 Battery.qml
singleton Network 1.0 Network.qml
singleton ClaudeUsage 1.0 ClaudeUsage.qml
```

- [ ] **Step 1.3: Verify `fetch-usage.sh` is readable and emits JSON**

```bash
bash -c 'source "$HOME/.claude/fetch-usage.sh"; fetch_usage_data' | head -20
```
Expected: JSON object with at least `sessionUsage` / `weeklyUsage` keys, or `{"error": "..."}` if no creds. Either is fine — the service handles both.

- [ ] **Step 1.4: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/services/ClaudeUsage.qml \
        quickshell/.config/quickshell/services/qmldir
git commit -m "feat(quickshell): add ClaudeUsage singleton service

Polls ~/.claude/fetch-usage.sh every 10 minutes (matching its cache TTL)
and exposes session/weekly percentages, reset ISO timestamps, and a
severity status (ok | warning | critical | error). Re-uses the same
cache as the Claude statusline so no extra API hits."
```

---

## Task 2: Add `Pill.qml` base container

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/Pill.qml`

- [ ] **Step 2.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/Pill.qml
import QtQuick
import qs.components

// Reusable opaque-black capsule container. Wraps `contentItem` with the
// standard pill chrome from Theme. All pills in the bar use this so the
// look stays uniform.
StyledRect {
    id: root

    property Item contentItem: null
    property int horizontalPadding: 12

    implicitHeight: 28
    implicitWidth: (contentItem ? contentItem.implicitWidth : 0) + 2 * horizontalPadding

    color: Theme.background
    border.color: Theme.outlineVariant
    border.width: 1
    radius: Theme.radius.full

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = root;
            contentItem.anchors.centerIn = root;
        }
    }
}
```

- [ ] **Step 2.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/Pill.qml
git commit -m "feat(quickshell): add reusable Pill capsule container

Opaque-black background, 1px outlineVariant border, full-radius capsule,
28px tall. Wraps a contentItem positioned with 12px horizontal padding.
Every pill in the new bar uses this so chrome stays uniform."
```

---

## Task 3: Add `PeekState.qml` FSM helper

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/PeekState.qml`

- [ ] **Step 3.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/PeekState.qml
import QtQuick
import qs.components

// Edge-peek finite state machine for a TopBar / BottomBar PanelWindow.
//
// Lifecycle:
//   Collapsed -> hotZone hover -> Peeking (slide in)
//   Peeking   -> anim done     -> Visible
//   Visible   -> pills not hovered + dwellMs -> Hiding (slide out)
//   Hiding    -> anim done                   -> Collapsed
//
// Caller provides:
//   - slideTarget: the Item being translated (y property is animated)
//   - slideFromY / slideToY: collapsed and visible y offsets
//   - hotZoneItem: an Item with a HoverHandler at the screen edge
//   - watchedItems: list of pill Items whose hover state defines "still over bar"
//
// PeekState exposes:
//   - state: string ("Collapsed" | "Peeking" | "Visible" | "Hiding")
//   - fullyHidden: bool (true when state === "Collapsed")
QtObject {
    id: peek

    property Item slideTarget: null
    property int slideFromY: 0
    property int slideToY: 0
    property Item hotZoneItem: null
    property var watchedItems: []
    property int dwellMs: 150

    property string state: "Collapsed"
    readonly property bool fullyHidden: state === "Collapsed"

    function _enter(): void {
        if (state === "Collapsed" || state === "Hiding") {
            state = "Peeking";
        }
    }

    function _maybeExit(): void {
        // Called when hover changes; if no watched item is hovered and not
        // currently in hotZone, schedule Hiding after dwellMs.
        if (state !== "Visible" && state !== "Peeking") return;
        const hotHovered = hotZoneItem && hotZoneItem.hovered === true;
        if (hotHovered) return;
        for (let i = 0; i < watchedItems.length; ++i) {
            if (watchedItems[i] && watchedItems[i].hovered === true) return;
        }
        _exitTimer.restart();
    }

    function _commitExit(): void {
        if (state === "Visible" || state === "Peeking") state = "Hiding";
    }

    property Timer _exitTimer: Timer {
        interval: peek.dwellMs
        repeat: false
        onTriggered: peek._commitExit()
    }

    property Connections _hotConn: Connections {
        target: peek.hotZoneItem
        function onHoveredChanged() {
            if (peek.hotZoneItem && peek.hotZoneItem.hovered) {
                peek._exitTimer.stop();
                peek._enter();
            } else {
                peek._maybeExit();
            }
        }
    }

    property NumberAnimation _slideAnim: NumberAnimation {
        target: peek.slideTarget
        property: "y"
        duration: 200
        from: peek.slideTarget ? peek.slideTarget.y : 0
        to: peek.state === "Peeking" ? peek.slideToY : peek.slideFromY
        easing.type: peek.state === "Peeking" ? Easing.OutCubic : Easing.InCubic
        onFinished: {
            if (peek.state === "Peeking") peek.state = "Visible";
            else if (peek.state === "Hiding") peek.state = "Collapsed";
        }
    }

    onStateChanged: {
        if (state === "Peeking" || state === "Hiding") {
            _slideAnim.from = slideTarget ? slideTarget.y : 0;
            _slideAnim.to = state === "Peeking" ? slideToY : slideFromY;
            _slideAnim.easing.type = state === "Peeking" ? Easing.OutCubic : Easing.InCubic;
            _slideAnim.restart();
        }
    }

    function notifyWatchedHoverChanged(): void {
        _maybeExit();
    }
}
```

- [ ] **Step 3.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/PeekState.qml
git commit -m "feat(quickshell): add PeekState FSM helper for bar peek

Finite state machine driving slide-in/out animation and exit-dwell
timer for TopBar and BottomBar peek behaviour. Caller wires a hot-zone
hover handler and the list of pill items to watch for hover-out;
PeekState animates the slideTarget y property between slideFromY and
slideToY."
```

---

## Task 4: Add `LauncherPill.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/LauncherPill.qml`

- [ ] **Step 4.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/LauncherPill.qml
import QtQuick
import Quickshell
import qs.components

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 8
    implicitWidth: 28               // square pill

    HoverHandler { id: hoverHandler }

    contentItem: MaterialIcon {
        text: "apps"
        color: Theme.text
        font.pixelSize: 18
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
    }
}
```

- [ ] **Step 4.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/LauncherPill.qml
git commit -m "feat(quickshell): add LauncherPill — apps icon, opens launcher"
```

---

## Task 5: Add `WorkspacesPill.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/WorkspacesPill.qml`

- [ ] **Step 5.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/WorkspacesPill.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.components

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 6

        Repeater {
            model: 5

            StyledRect {
                id: dot
                readonly property int wsId: index + 1
                readonly property var ws: {
                    const list = Hyprland.workspaces.values;
                    for (let i = 0; i < list.length; ++i) {
                        if (list[i].id === wsId) return list[i];
                    }
                    return null;
                }
                readonly property bool active: ws !== null && ws.active === true
                readonly property bool urgent: ws !== null && ws.urgent === true

                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 6
                implicitWidth: active ? 28 : 6
                radius: Theme.radius.full
                color: active ? Theme.text : (urgent ? Theme.warning : "#444444")
                border.width: 0

                Behavior on implicitWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                TapHandler {
                    onTapped: Hyprland.dispatch("workspace " + dot.wsId)
                }
            }
        }
    }
}
```

- [ ] **Step 5.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/WorkspacesPill.qml
git commit -m "feat(quickshell): add WorkspacesPill — 5 fixed slots, active expands

Renders 5 dots regardless of Hyprland's current workspace set. Active
workspace dot animates width 6 -> 28 over 200ms. Urgent dot uses warning
colour. Tap dispatches workspace switch (Hyprland creates the workspace
on demand if it doesn't exist yet)."
```

---

## Task 6: Add `ClockPill.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/ClockPill.qml`

- [ ] **Step 6.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/ClockPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 12

    HoverHandler { id: hoverHandler }

    contentItem: StyledText {
        text: Time.now ? Qt.formatDateTime(Time.now, "HH:mm") : "--:--"
        color: Theme.text
        font.pixelSize: 14
        font.bold: true
    }
}
```

- [ ] **Step 6.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/ClockPill.qml
git commit -m "feat(quickshell): add ClockPill — HH:mm bold, no click action"
```

---

## Task 7: Add `ClaudePill.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/ClaudePill.qml`

- [ ] **Step 7.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/ClaudePill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    readonly property color claudeColor: {
        if (ClaudeUsage.status === "critical") return Theme.error;
        if (ClaudeUsage.status === "warning") return Theme.warning;
        if (ClaudeUsage.status === "error") return Theme.textDim;
        return Theme.text;
    }

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 6

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "smart_toy"
            color: root.claudeColor
            font.pixelSize: 14
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: ClaudeUsage.status === "error"
                  ? "--"
                  : `${ClaudeUsage.sessionPct.toFixed(0)}%`
            color: root.claudeColor
            font.pixelSize: 12
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: ClaudeUsage.status === "error"
                  ? ""
                  : `${ClaudeUsage.weeklyPct.toFixed(0)}%`
            color: root.claudeColor
            font.pixelSize: 12
            visible: ClaudeUsage.status !== "error"
        }
    }
}
```

- [ ] **Step 7.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/ClaudePill.qml
git commit -m "feat(quickshell): add ClaudePill — robot glyph + session/weekly pct

Reads ClaudeUsage singleton; renders smart_toy icon + sessionPct% +
weeklyPct%. Colour ramps from text -> warning -> error based on
status. On error, shows '--' and dims to textDim."
```

---

## Task 8: Add `StatusPill.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/StatusPill.qml`

- [ ] **Step 8.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/StatusPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 12

    HoverHandler { id: hoverHandler }

    readonly property string volumeIcon: {
        if (Audio.muted) return "volume_off";
        if (Audio.volume === 0) return "volume_mute";
        if (Audio.volume < 50) return "volume_down";
        return "volume_up";
    }

    readonly property string batteryIcon: {
        if (Battery.charging) return "battery_charging_full";
        if (Battery.percent < 10) return "battery_alert";
        if (Battery.percent < 25) return "battery_2_bar";
        if (Battery.percent < 50) return "battery_4_bar";
        if (Battery.percent < 75) return "battery_5_bar";
        return "battery_full";
    }

    readonly property color batteryColor: {
        if (!Battery.charging && Battery.percent < 10) return Theme.error;
        if (!Battery.charging && Battery.percent < 25) return Theme.warning;
        return Theme.text;
    }

    contentItem: Row {
        spacing: 10

        // volume
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volumeIcon
                color: Audio.muted ? Theme.textDim : Theme.text
                font.pixelSize: 16
                TapHandler { onTapped: Audio.toggleMute() }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "--" : Audio.volume.toString()
                color: Audio.muted ? Theme.textDim : Theme.textVariant
                font.pixelSize: 11
            }
        }

        // network
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Network.connected ? "wifi" : "wifi_off"
            color: Network.connected ? Theme.text : Theme.warning
            font.pixelSize: 16
        }

        // battery
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryIcon
                color: root.batteryColor
                font.pixelSize: 16
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent.toString()
                color: root.batteryColor === Theme.text ? Theme.textVariant : root.batteryColor
                font.pixelSize: 11
            }
        }
    }
}
```

- [ ] **Step 8.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/StatusPill.qml
git commit -m "feat(quickshell): add StatusPill — volume + wifi + battery row

Single row inside one pill. Volume icon tap toggles mute. Battery row
hides when Battery.present is false (e.g. pavg15 with no BAT0)."
```

---

## Task 9: Add `TopBar.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/TopBar.qml`

- [ ] **Step 9.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/TopBar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: 28
    readonly property int edgeMargin: 6      // gap between pill and screen edge
    readonly property int hotZoneHeight: 4
    readonly property int panelHeight: pillHeight + edgeMargin + 2   // 36

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Hot-zone: thin invisible strip at the very top of the panel. Hover
    // here triggers the peek FSM to slide pills in.
    Item {
        id: hotZone
        property bool hovered: hotHover.hovered

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: panel.hotZoneHeight

        HoverHandler { id: hotHover }
    }

    Item {
        id: pillRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: panel.edgeMargin
        anchors.rightMargin: panel.edgeMargin
        height: panel.pillHeight
        y: -panel.pillHeight       // start collapsed (offscreen, above panel top)

        LauncherPill {
            id: launcher
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacesPill {
            id: workspaces
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width - 4
        }

        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 + 4
        }

        ClockPill {
            id: clock
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: -panel.pillHeight
        slideToY: panel.edgeMargin
        hotZoneItem: hotZone
        watchedItems: [launcher, workspaces, claude, clock]
        dwellMs: 150
    }

    // Wire pill hover changes back into peek FSM.
    Connections {
        target: launcher
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: workspaces
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: claude
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: clock
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }

    // Input mask: collapsed = top hot-zone strip; otherwise = full panel
    // (acceptable cost — user is actively hovering during this state).
    mask: Region {
        x: 0
        y: 0
        width: panel.width
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
```

- [ ] **Step 9.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/TopBar.qml
git commit -m "feat(quickshell): add TopBar PanelWindow with peek FSM

Top-anchored full-width panel with ExclusionMode.Ignore so windows tile
full height. Hot-zone strip (4px) at top triggers PeekState slide. Holds
launcher (left), workspaces (centre-left), claude (centre-right), clock
(right). Mask collapses to hot-zone strip when fully hidden; otherwise
covers the full panel."
```

---

## Task 10: Add `BottomBar.qml`

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/BottomBar.qml`

- [ ] **Step 10.1: Write the file**

```qml
// quickshell/.config/quickshell/modules/bar/BottomBar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    readonly property int pillHeight: 28
    readonly property int edgeMargin: 6
    readonly property int hotZoneHeight: 4
    readonly property int panelHeight: pillHeight + edgeMargin + 2   // 36
    // Pill row visible y: pill ends edgeMargin from panel bottom (= screen
    // bottom). pillRow.y = panelHeight - pillHeight - edgeMargin = 2.
    readonly property int visibleY: panelHeight - pillHeight - edgeMargin

    anchors {
        bottom: true
        right: true
    }

    implicitHeight: panelHeight
    implicitWidth: status.implicitWidth + 2 * edgeMargin
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: hotZone
        property bool hovered: hotHover.hovered

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: panel.hotZoneHeight

        HoverHandler { id: hotHover }
    }

    Item {
        id: pillRow

        anchors.right: parent.right
        anchors.rightMargin: panel.edgeMargin
        width: status.implicitWidth
        height: panel.pillHeight
        y: panel.panelHeight                 // start collapsed (offscreen, below panel)

        StatusPill {
            id: status
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: panel.panelHeight
        slideToY: panel.visibleY
        hotZoneItem: hotZone
        watchedItems: [status]
        dwellMs: 150
    }

    Connections {
        target: status
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }

    mask: Region {
        x: 0
        y: peek.fullyHidden ? panel.panelHeight - panel.hotZoneHeight : 0
        width: panel.width
        height: peek.fullyHidden ? panel.hotZoneHeight : panel.panelHeight
    }
}
```

- [ ] **Step 10.2: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/bar/BottomBar.qml
git commit -m "feat(quickshell): add BottomBar PanelWindow with peek FSM

Bottom-right anchored, content-sized panel. Hot-zone strip at bottom
triggers PeekState slide. Holds StatusPill anchored to right edge with
6px margin. Same FSM contract as TopBar."
```

---

## Task 11: Replace `Bar.qml`, delete obsolete bar files, smoke-test live

**Files:**
- Replace: `quickshell/.config/quickshell/modules/Bar.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/OsIcon.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/Workspaces.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/Clock.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/StatusIcons.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/PowerButton.qml`

- [ ] **Step 11.1: Replace `Bar.qml`**

```qml
// quickshell/.config/quickshell/modules/Bar.qml
import QtQuick
import Quickshell
import qs.modules.bar as BarModules

// Primary-monitor-only floating-pills bar. Spawns TopBar (4 pills, peeks
// from top) and BottomBar (status pill, peeks from bottom) on the primary
// screen only — multi-monitor: secondary screens get nothing.
Scope {
    id: bar

    readonly property var primaryScreens: Quickshell.screens.filter(
        s => Quickshell.primaryScreen && s.name === Quickshell.primaryScreen.name
    )

    Variants {
        model: bar.primaryScreens
        BarModules.TopBar {}    // modelData property already declared `required` in TopBar.qml
    }

    Variants {
        model: bar.primaryScreens
        BarModules.BottomBar {}
    }
}
```

- [ ] **Step 11.2: Delete obsolete pill files**

```bash
cd ~/dotfiles
git rm quickshell/.config/quickshell/modules/bar/OsIcon.qml \
       quickshell/.config/quickshell/modules/bar/Workspaces.qml \
       quickshell/.config/quickshell/modules/bar/Clock.qml \
       quickshell/.config/quickshell/modules/bar/StatusIcons.qml \
       quickshell/.config/quickshell/modules/bar/PowerButton.qml
```

- [ ] **Step 11.3: Smoke reload (run the Smoke pattern block from the top)**

```bash
qs kill -a 2>&1 ; sleep 1
qs -d 2>&1 ; sleep 2
qs log --follow 2>&1 &
LOG_PID=$!
sleep 5
kill $LOG_PID
```

Expected: no QML errors or TypeErrors. Acceptable warnings listed in Smoke pattern.

- [ ] **Step 11.4: Visual smoke (manual, in the live Hyprland session)**

Verify:
- No bar visible by default (peek hidden).
- Hover mouse to top edge — 4 pills slide in (launcher, workspaces, claude, clock).
- Hover mouse to bottom-right edge — status pill slides in.
- Move mouse away from pills — they slide out after ~150ms dwell.
- Click launcher pill → launcher overlay opens.
- Click a workspace dot → workspace switches.
- Click volume icon in status pill → mute toggles (try unmuting too).
- Open second monitor (if available) — bar absent on secondary.

- [ ] **Step 11.5: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/Bar.qml
git commit -m "feat(quickshell): replace bar with floating-pills layout

Bar.qml now instantiates TopBar + BottomBar on the primary screen only.
The vertical-dock OsIcon/Workspaces/Clock/StatusIcons/PowerButton modules
are removed. Power overlay is reached via the Hyprland MOD+L keybind
(wired in a follow-up commit), not via a bar pill."
```

---

## Task 12: Reskin Launcher, Notifications, Osd

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Launcher.qml` (lines 90-97)
- Modify: `quickshell/.config/quickshell/modules/Notifications.qml` (lines 54-61)
- Modify: `quickshell/.config/quickshell/modules/Osd.qml` (lines 93-100)

The reskin is a mechanical swap of root-container colours and borders. Internal layouts and handlers are NOT touched.

- [ ] **Step 12.1: Patch `Launcher.qml` lines 94-95**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 12.2: Patch `Notifications.qml` lines 58-59**

Old:
```qml
                        color: Theme.surface
                        border.color: Theme.outline
```
New:
```qml
                        color: Theme.background
                        border.color: Theme.outlineVariant
```

(Single per-toast `StyledRect` inside the `Repeater` — only one occurrence in this file.)

- [ ] **Step 12.3: Patch `Osd.qml` lines 97-100**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                radius: Theme.radius.large
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.full
```

(Capsule radius — matches bar pill aesthetic.)

- [ ] **Step 12.4: Smoke reload**

```bash
qs kill -a 2>&1 ; sleep 1
qs -d 2>&1 ; sleep 2
qs log --follow 2>&1 &
LOG_PID=$!
sleep 5
kill $LOG_PID
```

- [ ] **Step 12.5: Visual smoke**

- Open launcher (click launcher pill or via existing keybind). Confirm pure-black bg, no grey leftover.
- Trigger a notification (e.g. `notify-send 'test' 'body'`). Confirm toast bg matches.
- Trigger an OSD (volume up/down keys). Confirm capsule shape.

- [ ] **Step 12.6: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/Launcher.qml \
        quickshell/.config/quickshell/modules/Notifications.qml \
        quickshell/.config/quickshell/modules/Osd.qml
git commit -m "style(quickshell): reskin launcher/notifications/osd to opaque black

Root containers switch from Theme.surface to Theme.background and from
outline to outlineVariant border. OSD pill picks up Theme.radius.full to
match the new bar pill capsule shape. No layout or handler changes."
```

---

## Task 13: Reskin Clipboard, Power, EmojiPicker

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Clipboard.qml` (lines 117-118)
- Modify: `quickshell/.config/quickshell/modules/Power.qml` (lines 65-66 + 86)
- Modify: `quickshell/.config/quickshell/modules/EmojiPicker.qml` (lines 316-317)

- [ ] **Step 13.1: Patch `Clipboard.qml` lines 117-118**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

(Per-row delegates already use `Theme.surfaceContainerHigh` for current-index highlight and `"transparent"` otherwise — leave those alone; they provide the necessary contrast against the now-pure-black root.)

- [ ] **Step 13.2: Patch `Power.qml` lines 65-66**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 13.3: Patch `Power.qml` line 86 (per-card border)**

Old:
```qml
                            border.color: layer.hovered ? Theme.primary : Theme.outline
```
New:
```qml
                            border.color: layer.hovered ? Theme.primary : Theme.outlineVariant
```

(`Theme.primary` on hover is intentional — it's `#ffffff` and gives the selected-action card a white border highlight against the new pure-black surround. Card fill colours `Theme.surfaceContainer` / `Theme.surfaceContainerHigh` on line 84 stay.)

- [ ] **Step 13.4: Patch `EmojiPicker.qml` lines 316-317**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 13.5: Smoke reload**

```bash
qs kill -a 2>&1 ; sleep 1
qs -d 2>&1 ; sleep 2
qs log --follow 2>&1 &
LOG_PID=$!
sleep 5
kill $LOG_PID
```

- [ ] **Step 13.6: Visual smoke**

- Trigger clipboard overlay (existing keybind). Confirm bg.
- Press MOD+L → Power overlay opens (Lock card first). Confirm card hover border still white.
- Trigger emoji picker (existing keybind). Confirm bg.

- [ ] **Step 13.7: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/Clipboard.qml \
        quickshell/.config/quickshell/modules/Power.qml \
        quickshell/.config/quickshell/modules/EmojiPicker.qml
git commit -m "style(quickshell): reskin clipboard/power/emoji to opaque black

Same pattern as launcher/notifications: root background goes to
Theme.background, border to outlineVariant. Power cards keep their
surfaceContainer fill and Theme.primary (white) hover border for the
selected-action highlight."
```

---

## Task 14: Reskin PassMenu, TagInput, WindowPicker

**Files:**
- Modify: `quickshell/.config/quickshell/modules/PassMenu.qml` (lines 100-101)
- Modify: `quickshell/.config/quickshell/modules/TagInput.qml` (lines 69-70)
- Modify: `quickshell/.config/quickshell/modules/WindowPicker.qml` (lines 110-111)

- [ ] **Step 14.1: Patch `PassMenu.qml` lines 100-101**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 14.2: Patch `TagInput.qml` lines 69-70**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 14.3: Patch `WindowPicker.qml` lines 110-111**

Old:
```qml
                color: Theme.surface
                border.color: Theme.outline
```
New:
```qml
                color: Theme.background
                border.color: Theme.outlineVariant
```

- [ ] **Step 14.4: Smoke reload**

```bash
qs kill -a 2>&1 ; sleep 1
qs -d 2>&1 ; sleep 2
qs log --follow 2>&1 &
LOG_PID=$!
sleep 5
kill $LOG_PID
```

- [ ] **Step 14.5: Visual smoke**

- Trigger PassMenu (existing keybind, if used). Confirm bg.
- Trigger TagInput (if used in your workflow). Confirm modal bg.
- Trigger WindowPicker (alt-tab style). Confirm bg.

If any of these aren't bound to a current keybind, skip the live test for them — the change is mechanical and matches the other reskins.

- [ ] **Step 14.6: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/modules/PassMenu.qml \
        quickshell/.config/quickshell/modules/TagInput.qml \
        quickshell/.config/quickshell/modules/WindowPicker.qml
git commit -m "style(quickshell): reskin passmenu/taginput/windowpicker to opaque black

Final batch of overlay reskins. Same root-container colour swap as
launcher/notifications/clipboard."
```

---

## Task 15: Rebind MOD+L to Power overlay in Hyprland

**Files:**
- Modify: `hypr/.config/hypr/hyprland.conf`

Current state (relevant lines):
```
139:bind = $mainMod, L, exec, hyprlock
140:bind = $mainMod SHIFT, L, exec, $powerMenu
```

`$powerMenu` is already defined at line 29 as `qs ipc call session toggle`. The Power overlay's first card is Lock (fires `hyprlock`), so MOD+L → Power overlay still gives one-click lock via the card.

- [ ] **Step 15.1: Edit hyprland.conf**

Replace line 139:
```
bind = $mainMod, L, exec, hyprlock
```
with:
```
bind = $mainMod, L, exec, $powerMenu
```

Delete line 140 entirely (the MOD+SHIFT+L binding becomes redundant — it called the same `$powerMenu`).

The expected diff for lines 139-140:
```diff
-bind = $mainMod, L, exec, hyprlock
-bind = $mainMod SHIFT, L, exec, $powerMenu
+bind = $mainMod, L, exec, $powerMenu
```

- [ ] **Step 15.2: Reload Hyprland config**

```bash
hyprctl reload
```
Expected: no error. If a syntax error is reported, fix and re-run.

- [ ] **Step 15.3: Verify the binding**

Press SUPER+L in the live session. The Power overlay should appear with five cards (Lock, Logout, Suspend, Reboot, Shutdown). Click outside or press Escape to dismiss without locking.

- [ ] **Step 15.4: Commit**

```bash
cd ~/dotfiles
git add hypr/.config/hypr/hyprland.conf
git commit -m "feat(hyprland): bind MOD+L to power overlay instead of hyprlock

The new quickshell config has no PowerButton pill, so the session
overlay is reached via keybind. Lock remains one click away as the
first card in the overlay. Drops the redundant MOD+SHIFT+L binding
that called the same overlay."
```

---

## Task 16: Final manual verification

No file changes — this task runs the full spec checklist against the live system.

- [ ] **Step 16.1: Walk the 10-point checklist from the spec**

For each item, observe the result and tick the box in the commit message of the next docs commit:

1. Quickshell boots clean — no QML errors in `qs log` since restart. Acceptable warnings only.
2. Bar shows on primary monitor only. With a secondary monitor connected, only primary has the bar.
3. Per-edge peek works: top edge → top 4 pills slide in; bottom edge → status pill slides in; both auto-hide on mouse-away after ~150ms.
4. Pill taps: launcher → Launcher overlay; workspace dots → workspace switch; clock/claude → no-op; volume icon → mute toggle.
5. `MOD+L` → Power overlay with Lock first.
6. ClaudePill populates within ~10s of shell start (assuming `~/.claude/fetch-usage.sh` works and there are valid creds). Severity colour matches percentage. If creds missing, ClaudeUsage.status becomes "error" and pill shows "--" — acceptable.
7. Each overlay (launcher, notifications, osd, clipboard, power, emoji, pass, taginput, windowpicker) reads pure-black bg, no grey leftover.
8. Maximised window covers full screen (no reserved bar gap).
9. Replug an external monitor — bar stays primary-only.
10. Side-by-side screenshot vs the rejected caelestia commit `1db76df` (optional but useful — save as `docs/superpowers/rice-before-after.png` if you take one).

- [ ] **Step 16.2: If a check fails — open a follow-up plan instead of patching here**

The plan is "done" once all commits land and the codebase matches the spec. Fixes for issues uncovered by manual smoke go in a follow-up commit or a new plan, not by retroactively editing earlier tasks.

- [ ] **Step 16.3: Note the design-doc commit reference**

The spec lives at `docs/superpowers/specs/2026-05-18-quickshell-rice-design.md` (commit `4d2b7a8`). This plan lives at `docs/superpowers/plans/2026-05-18-quickshell-rice.md` (this file). No commit needed for this task — verification is observation only.

---

## Self-review notes (resolved before handoff)

The following issues were caught when reviewing this plan against the spec and fixed inline:

- `PeekState` initial code used `Behavior on y` driven directly by state; switched to an explicit `NumberAnimation` that restarts on state transition so `from` and `to` can be re-derived against the current `y` (handles fast hover-in-hover-out without snapping).
- `Bar.qml` originally used a single `Variants` with `model: [Quickshell.primaryScreen]`. That fails on cold start before `primaryScreen` is populated. Switched to `Quickshell.screens.filter(...)` which evaluates lazily and includes a `primaryScreen` null-guard.
- TopBar / BottomBar dimensions originally used `edgeSlack: 8` and `totalHeight: 44` which contradicted the spec's `Edge margin: 6px`. Renamed to `edgeMargin: 6` and `panelHeight: 36`, with `visibleY` derived for BottomBar so the pill sits the correct 6px from the screen bottom edge.
- `Bar.qml`'s `Variants` children originally redeclared `required property var modelData` inline, which is a QML syntax error when the inner type (`TopBar` / `BottomBar`) already declares the property as required. Removed the redundant inline declaration so `Variants` populates the existing required property automatically.
- Overlay reskin tasks (12-14) originally used "read the file, find the StyledRect" guidance. Replaced with concrete line-number diffs after reading each overlay file.
- Spec mentions a tooltip on `ClaudePill` but lists it as out-of-scope. Plan does not include a tooltip task. `ClaudePill.qml` exposes `hovered` so a future tooltip can attach without re-touching the pill.
- Power overlay reskin keeps `Theme.primary` (white) for hover border — verified this is intentional in spec section "Overlay reskin".
- Hyprland binding originally specified only adding a new line; in practice line 139 needs replacement (not addition) to avoid `hyprlock` racing the overlay. Task 15 reflects this.

## Known risks the implementer should watch for

- **`Region` API surface.** The `mask: Region { x; y; width; height }` shorthand in Tasks 9-10 assumes Quickshell's `Region` type accepts a plain rectangle inline. If the build complains, try the alternative form `mask: Region { item: hotZone }` when collapsed and `mask: null` when visible (null mask = full panel input).
- **`HoverHandler` alias signal.** Pills expose `readonly property alias hovered: hoverHandler.hovered`. The `Connections { target: pill; function onHoveredChanged() {...} }` in TopBar/BottomBar relies on the alias preserving the underlying notify signal. Property aliases do preserve `xxxChanged` signals in QML, but if Quickshell's QML runtime quirks-out, switch to a direct `Connections { target: pill.hoverHandler }` and pass `hoverHandler` as a property of each pill.
- **`ClaudeUsage` cold-start.** First poll runs at `triggeredOnStart: true`, so the pill may render with default 0% / "ok" status for ~1 second before the bash subshell returns. Acceptable per spec (the pill is display-only).
