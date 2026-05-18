# Quickshell end-4 Port — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port high-value end-4 (illogical-impulse) modules into the existing floating-pills quickshell config + rewrite six in-house modules to match end-4 quality, adapted to the pure-black `Theme.qml` palette.

**Architecture:** Continue on `quickshell-floating-pills` branch. Each task is a self-contained commit; reload is hot (FileView auto-picks up file saves). No copy-paste from end-4 source — code is rewritten to drop heavy deps (`Config`, `Translation`, `Appearance`, `Cava`, `GlobalStates`, `GlobalFocusGrab`, `StyledRectangularShadow`, `StringUtils`, `FileUtils`). All new and rewritten components use existing `qs.components` (Theme, MaterialIcon, StyledRect, StyledText, StateLayer) and `qs.services` singletons.

**Tech Stack:** Quickshell 0.3.0, Qt6 QML, wlr-layer-shell via `Quickshell.Wayland`, `Quickshell.Services.{Mpris, SystemTray, Notifications}`, `Quickshell.Io` (Process / FileView / IpcHandler), Hyprland keybinds.

**Spec:** `docs/superpowers/specs/2026-05-18-quickshell-end4-port-design.md`

---

## Smoke test template (apply per task)

After each code change:

1. `qs log | tail -40` — verify no QML errors, "Configuration Loaded" present
2. If the change is UI-visible, verify behavior described in the task's **Verify** step
3. `git add <paths>` then `git commit -m '<message>'` per GIT.md rules:
   - lowercase imperative, no trailing period, GPG signed (default), no `--no-verify`, no `Co-Authored-By`, no "phase/step/milestone" jargon
   - Stay on branch `quickshell-floating-pills`
4. Do NOT `qs kill`. Hot reload picks up the change. Only restart if `qs list` shows the daemon is gone.

---

## Task 1: MprisService singleton

**Files:**
- Create: `quickshell/.config/quickshell/services/MprisService.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

- [ ] **Step 1: Create `MprisService.qml`**

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> allPlayers: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        for (let i = 0; i < allPlayers.length; ++i) {
            if (allPlayers[i].isPlaying) return allPlayers[i];
        }
        return allPlayers.length > 0 ? allPlayers[0] : null;
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0

    function togglePlaying(): void {
        if (canTogglePlaying) activePlayer.togglePlaying();
    }
    function next(): void {
        if (canGoNext) activePlayer.next();
    }
    function previous(): void {
        if (canGoPrevious) activePlayer.previous();
    }
    function pauseAll(): void {
        for (let i = 0; i < allPlayers.length; ++i) {
            if (allPlayers[i].canPause) allPlayers[i].pause();
        }
    }

    IpcHandler {
        target: "mpris"
        function playPause(): void { root.togglePlaying(); }
        function next(): void { root.next(); }
        function previous(): void { root.previous(); }
        function pauseAll(): void { root.pauseAll(); }
    }
}
```

- [ ] **Step 2: Append to `services/qmldir`**

```
singleton MprisService 1.0 MprisService.qml
```

Final `qmldir`:

```
module qs.services
singleton Time 1.0 Time.qml
singleton Audio 1.0 Audio.qml
singleton Battery 1.0 Battery.qml
singleton Network 1.0 Network.qml
singleton ClaudeUsage 1.0 ClaudeUsage.qml
singleton MprisService 1.0 MprisService.qml
```

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`
Expected: "Configuration Loaded" present; no "Cannot assign", "TypeError", or "is not a type" errors mentioning `MprisService`.

- [ ] **Step 4: Smoke-test via IPC (no UI yet — just service+IPC)**

Run: `mpv ~/Music/*.mp3 &` (or any file with audio). Then: `qs ipc call mpris playPause`
Expected: mpv toggles between play and pause states.

- [ ] **Step 5: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/services/MprisService.qml quickshell/.config/quickshell/services/qmldir && git commit -m 'feat(quickshell): add MprisService singleton wrapping Quickshell.Services.Mpris'
```

---

## Task 2: MediaPill in bar

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/MediaPill.qml`
- Modify: `quickshell/.config/quickshell/modules/bar/BottomBar.qml`

- [ ] **Step 1: Create `MediaPill.qml`**

```qml
// quickshell/.config/quickshell/modules/bar/MediaPill.qml
import QtQuick
import Quickshell
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    visible: MprisService.hasPlayer
    horizontalPadding: 10

    readonly property string truncatedTitle: {
        const t = MprisService.title;
        if (t.length <= 24) return t;
        return t.substring(0, 23) + "…";
    }

    HoverHandler { id: hoverHandler }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "mediaControls", "toggle"])
    }
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: MprisService.togglePlaying()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: MprisService.next()
    }

    contentItem: Row {
        spacing: 6

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: MprisService.isPlaying ? "pause" : "music_note"
            color: Theme.text
            font.pixelSize: 14
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.truncatedTitle
            color: Theme.text
            font.pixelSize: 12
            visible: root.truncatedTitle.length > 0
        }
    }
}
```

- [ ] **Step 2: Modify `BottomBar.qml` — insert MediaPill between workspaces and clock**

Replace the contents of `quickshell/.config/quickshell/modules/bar/BottomBar.qml` with:

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
    readonly property int hotZoneHeight: 12
    readonly property int panelHeight: pillHeight + edgeMargin + 2
    readonly property int visibleY: panelHeight - pillHeight - edgeMargin

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: panelHeight
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

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: panel.edgeMargin
        anchors.rightMargin: panel.edgeMargin
        height: panel.pillHeight
        y: panel.panelHeight

        LauncherPill {
            id: launcher
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacesPill {
            id: workspaces
            anchors.verticalCenter: parent.verticalCenter
            x: launcher.x + launcher.width + 8
        }

        MediaPill {
            id: media
            anchors.verticalCenter: parent.verticalCenter
            x: workspaces.x + workspaces.width + 8
        }

        ClockPill {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - width / 2
        }

        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: status.x - width - 8
        }

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
        watchedItems: [launcher, workspaces, media, clock, claude, status]
        dwellMs: 600
    }

    Connections {
        target: launcher
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: workspaces
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: media
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: clock
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
    Connections {
        target: claude
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
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

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`
Expected: no errors mentioning `MediaPill` or `BottomBar`.

- [ ] **Step 4: Verify visual**

Start audio: `mpv --no-video ~/Music/*.mp3` (or any audio file). Hover bottom edge → MediaPill appears between workspaces and clock with `music_note` or `pause` icon plus truncated title. Middle-click MediaPill → mpv toggles play. Right-click MediaPill → mpv next. With no audio, MediaPill is hidden (zero-width, no visible gap).

- [ ] **Step 5: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/bar/MediaPill.qml quickshell/.config/quickshell/modules/bar/BottomBar.qml && git commit -m 'feat(quickshell): add MediaPill to bar'
```

---

## Task 3: MediaControls overlay

**Files:**
- Create: `quickshell/.config/quickshell/modules/MediaControls.qml`
- Modify: `quickshell/.config/quickshell/shell.qml`

- [ ] **Step 1: Create `MediaControls.qml`**

```qml
// quickshell/.config/quickshell/modules/MediaControls.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    property bool open: false

    function toggle(): void { root.open = !root.open; }

    IpcHandler {
        target: "mediaControls"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                focus: true
                onClicked: root.open = false
                Keys.onEscapePressed: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 420
                implicitHeight: 220
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Timer {
                    interval: 1000
                    running: root.open && MprisService.isPlaying && MprisService.activePlayer !== null
                    repeat: true
                    onTriggered: {
                        if (MprisService.activePlayer) MprisService.activePlayer.positionChanged();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large
                    visible: MprisService.hasPlayer

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        StyledRect {
                            implicitWidth: 80
                            implicitHeight: 80
                            color: Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1
                            radius: Theme.radius.normal
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: MprisService.artUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: MprisService.artUrl.length > 0
                                asynchronous: true
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: MprisService.artUrl.length === 0
                                text: "music_note"
                                color: Theme.textMuted
                                font.pixelSize: 40
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.smaller

                            StyledText {
                                Layout.fillWidth: true
                                text: MprisService.title || "Unknown title"
                                color: Theme.text
                                font.pixelSize: Theme.font.size.large
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: MprisService.artist || "Unknown artist"
                                color: Theme.textVariant
                                font.pixelSize: Theme.font.size.normal
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        visible: MprisService.length > 0

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHigh
                            radius: Theme.radius.full
                        }
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, MprisService.position / Math.max(1, MprisService.length)))
                            height: parent.height
                            color: Theme.text
                            radius: Theme.radius.full
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacing.extraLarge

                        StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.full
                            color: prevHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                            border.color: Theme.outlineVariant
                            border.width: 1
                            opacity: MprisService.canGoPrevious ? 1.0 : 0.4

                            HoverHandler { id: prevHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.previous()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                color: Theme.text
                                font.pixelSize: 22
                            }
                        }

                        StyledRect {
                            implicitWidth: 52
                            implicitHeight: 52
                            radius: Theme.radius.full
                            color: playHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1

                            HoverHandler { id: playHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.togglePlaying()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: MprisService.isPlaying ? "pause" : "play_arrow"
                                color: Theme.text
                                font.pixelSize: 28
                            }
                        }

                        StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.full
                            color: nextHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                            border.color: Theme.outlineVariant
                            border.width: 1
                            opacity: MprisService.canGoNext ? 1.0 : 0.4

                            HoverHandler { id: nextHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.next()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_next"
                                color: Theme.text
                                font.pixelSize: 22
                            }
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: !MprisService.hasPlayer
                    text: "No active media player"
                    color: Theme.textMuted
                    font.pixelSize: Theme.font.size.normal
                }
            }
        }
    }
}
```

- [ ] **Step 2: Modify `shell.qml`**

Add `MediaControls {}` to `ShellRoot`. Final file:

```qml
// quickshell/.config/quickshell/shell.qml
import Quickshell
import qs.modules

ShellRoot {
    Bar {}
    Notifications {}
    Launcher {}
    Power {}
    Clipboard {}
    WindowPicker {}
    Osd {}
    TagInput {}
    PassMenu {}
    EmojiPicker {}
    MediaControls {}
}
```

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`
Expected: no errors.

- [ ] **Step 4: Verify behavior**

Start audio (mpv or spotify). Run: `qs ipc call mediaControls toggle`. Expected: centered card with art (or music_note placeholder), title bold, artist below, position bar growing 1Hz, three round buttons. Click play_arrow → pauses; skip_next → next track. ESC dismisses. Click outside dismisses. Stop audio (`pkill mpv`): card shows "No active media player".

- [ ] **Step 5: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/MediaControls.qml quickshell/.config/quickshell/shell.qml && git commit -m 'feat(quickshell): add MediaControls overlay'
```

---

## Task 4: Hyprland media keybinds

**Files:**
- Modify: `hypr/.config/hypr/hyprland.conf`

- [ ] **Step 1: Replace media-key block**

Edit `hypr/.config/hypr/hyprland.conf`. Find lines 215-218 (the `bindl = , XF86Audio...` block invoking `playerctl`) and replace with binds routing through `qs ipc call mpris`. Also add `MOD+M` binding for media controls. Final block:

```ini
bindl = , XF86AudioNext,  exec, qs ipc call mpris next
bindl = , XF86AudioPause, exec, qs ipc call mpris playPause
bindl = , XF86AudioPlay,  exec, qs ipc call mpris playPause
bindl = , XF86AudioPrev,  exec, qs ipc call mpris previous

bind = $mainMod, M, exec, qs ipc call mediaControls toggle
```

The `bind = $mainMod, M, exec, ...` line should be added in the keybinds section near other Quickshell binds (e.g., after line 152 where `MOD+CTRL+SHIFT+ALT+V` lives). Use the exact Edit tool replacement below — match the four `bindl` lines exactly.

- [ ] **Step 2: Reload Hyprland config**

Run: `hyprctl reload`
Expected: `ok`. `qs log 2>&1 | tail -10` should not show errors.

- [ ] **Step 3: Verify**

Press laptop play/pause media key (or use a generic-key-emitter tool if no media keys). Verify mpv/spotify toggles. Press `Super+M` → MediaControls overlay opens.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add hypr/.config/hypr/hyprland.conf && git commit -m 'feat(hyprland): route media keys through qs ipc mpris'
```

---

## Task 5: TrayService singleton

**Files:**
- Create: `quickshell/.config/quickshell/services/TrayService.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

- [ ] **Step 1: Create `TrayService.qml`**

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root
    readonly property list<SystemTrayItem> items: SystemTray.items.values
    readonly property int count: items.length
}
```

- [ ] **Step 2: Append to `services/qmldir`**

```
singleton TrayService 1.0 TrayService.qml
```

- [ ] **Step 3: Verify reload + smoke**

Run: `qs log 2>&1 | tail -30`. Expected: no errors mentioning `TrayService` or `SystemTray`.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/services/TrayService.qml quickshell/.config/quickshell/services/qmldir && git commit -m 'feat(quickshell): add TrayService singleton'
```

---

## Task 6: TrayPill in bar

**Files:**
- Create: `quickshell/.config/quickshell/modules/bar/TrayPill.qml`
- Modify: `quickshell/.config/quickshell/modules/bar/BottomBar.qml`

- [ ] **Step 1: Create `TrayPill.qml`**

```qml
// quickshell/.config/quickshell/modules/bar/TrayPill.qml
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    visible: TrayService.count > 0
    horizontalPadding: 6

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 8

        Repeater {
            model: TrayService.items

            Item {
                required property var modelData
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            anchor.open();
                        } else {
                            modelData.activate();
                        }
                    }
                }

                QsMenuAnchor {
                    id: anchor
                    menu: modelData.menu
                    anchor.window: root.QsWindow.window
                    anchor.rect.x: root.mapToItem(null, 0, 0).x
                    anchor.rect.y: root.mapToItem(null, 0, 0).y
                    anchor.rect.width: root.width
                    anchor.rect.height: root.height
                    anchor.edges: Edges.Top
                }
            }
        }
    }
}
```

- [ ] **Step 2: Modify `BottomBar.qml` — insert TrayPill between claude and status**

Open `quickshell/.config/quickshell/modules/bar/BottomBar.qml` and replace the right-side pill block. Find the existing right-anchored chain:

```qml
        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: status.x - width - 8
        }

        StatusPill {
            id: status
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
```

Replace with:

```qml
        TrayPill {
            id: tray
            anchors.verticalCenter: parent.verticalCenter
            x: status.x - width - 8
        }

        ClaudePill {
            id: claude
            anchors.verticalCenter: parent.verticalCenter
            x: tray.visible ? (tray.x - width - 8) : (status.x - width - 8)
        }

        StatusPill {
            id: status
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
```

Then update `watchedItems` and `Connections` to include `tray`:

```qml
    PeekState {
        id: peek
        slideTarget: pillRow
        slideFromY: panel.panelHeight
        slideToY: panel.visibleY
        hotZoneItem: hotZone
        watchedItems: [launcher, workspaces, media, clock, claude, tray, status]
        dwellMs: 600
    }

    Connections {
        target: tray
        function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
    }
```

(Add the `Connections { target: tray ... }` block alongside the others.)

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`
Expected: no errors mentioning `TrayPill`, `QsMenuAnchor`, or `SystemTray`.

- [ ] **Step 4: Verify visual**

Start Slack or Discord (or any tray client). Hover bottom edge → TrayPill appears between ClaudePill and StatusPill with the tray icons. Left-click an icon → activates app. Right-click → menu opens (for apps that expose one). Quit the tray app → TrayPill hides, ClaudePill snaps right.

- [ ] **Step 5: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/bar/TrayPill.qml quickshell/.config/quickshell/modules/bar/BottomBar.qml && git commit -m 'feat(quickshell): add system tray pill to bar'
```

---

## Task 7: Bluetooth service

**Files:**
- Create: `quickshell/.config/quickshell/services/Bluetooth.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

- [ ] **Step 1: Create `Bluetooth.qml`**

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property int connectedDeviceCount: 0
    property var connectedDeviceNames: []

    function togglePowered(): void {
        if (!root.available) return;
        toggleProc.command = ["bluetoothctl", "power", root.powered ? "off" : "on"];
        toggleProc.running = true;
    }

    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text;
                if (out.length === 0) {
                    root.available = false;
                    root.powered = false;
                    return;
                }
                root.available = true;
                const m = out.match(/Powered:\s+(yes|no)/);
                root.powered = m && m[1] === "yes";
            }
        }
    }

    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.startsWith("Device "));
                root.connectedDeviceCount = lines.length;
                root.connectedDeviceNames = lines.map(l => {
                    const parts = l.split(" ");
                    return parts.slice(2).join(" ");
                });
            }
        }
    }

    Process {
        id: toggleProc
        onExited: poll()
    }

    function poll(): void {
        showProc.running = true;
        devicesProc.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
```

- [ ] **Step 2: Append to `services/qmldir`**

```
singleton Bluetooth 1.0 Bluetooth.qml
```

- [ ] **Step 3: Verify reload + smoke**

Run: `qs log 2>&1 | tail -30`. Expected: no errors. The service polls every 5s — `qs ipc` lacks a debug command, so verify via Task 8 visual.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/services/Bluetooth.qml quickshell/.config/quickshell/services/qmldir && git commit -m 'feat(quickshell): add Bluetooth service polling bluetoothctl'
```

---

## Task 8: Bluetooth icon in StatusPill

**Files:**
- Modify: `quickshell/.config/quickshell/modules/bar/StatusPill.qml`

- [ ] **Step 1: Replace `StatusPill.qml`**

Replace the entire file with:

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

    readonly property string bluetoothIcon: {
        if (!Bluetooth.powered) return "bluetooth_disabled";
        if (Bluetooth.connectedDeviceCount > 0) return "bluetooth_connected";
        return "bluetooth";
    }

    readonly property color bluetoothColor: {
        if (!Bluetooth.powered) return Theme.textDim;
        if (Bluetooth.connectedDeviceCount > 0) return Theme.text;
        return Theme.textVariant;
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

        // bluetooth
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Bluetooth.available
            text: root.bluetoothIcon
            color: root.bluetoothColor
            font.pixelSize: 16
            TapHandler { onTapped: Bluetooth.togglePowered() }
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

- [ ] **Step 2: Verify reload + visual**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

Hover bottom edge → StatusPill shows volume + BT icon (greyed if powered off, white if on, brighter if connected) + wifi + battery. Run `bluetoothctl power off` then `bluetoothctl power on` from a separate shell — within 5s the BT icon should flip. Click the BT icon → toggles power. Connect a device → icon becomes `bluetooth_connected`.

- [ ] **Step 3: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/bar/StatusPill.qml && git commit -m 'feat(quickshell): add bluetooth icon + toggle to status pill'
```

---

## Task 9: HyprlandKeybinds service (for Cheatsheet)

**Files:**
- Create: `quickshell/.config/quickshell/services/HyprlandKeybinds.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`

- [ ] **Step 1: Create `HyprlandKeybinds.qml`**

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // categories: [{ name: "Section name", binds: [{mods: "SUPER+SHIFT", key: "Q", action: "killactive"}] }]
    property var categories: []

    function reload(): void {
        configFile.reload();
    }

    FileView {
        id: configFile
        path: Qt.resolvedUrl(Qt.application.organization === undefined ? "" : "") + ""

        Component.onCompleted: {
            configFile.path = Quickshell.env("HOME") + "/.config/hypr/hyprland.conf";
        }

        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root._parse(this.text())
    }

    function _parse(text: string): void {
        const lines = text.split("\n");
        const cats = [];
        let cur = { name: "Misc", binds: [] };

        const sectionRe = /^\s*#+\s*Section:\s*(.+?)\s*#*\s*$/;
        const bindRe = /^\s*bind[lemi]*\s*=\s*([^,]*),\s*([^,]*),\s*(.+?)\s*$/;

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i];
            const sm = line.match(sectionRe);
            if (sm) {
                if (cur.binds.length > 0) cats.push(cur);
                cur = { name: sm[1].trim(), binds: [] };
                continue;
            }
            const bm = line.match(bindRe);
            if (bm) {
                const mods = bm[1].trim().replace(/\$mainMod/g, "SUPER").toUpperCase();
                const key = bm[2].trim().toUpperCase();
                const action = bm[3].trim();
                if (key.length === 0) continue;
                cur.binds.push({ mods: mods, key: key, action: action });
            }
        }
        if (cur.binds.length > 0) cats.push(cur);
        root.categories = cats;
    }
}
```

- [ ] **Step 2: Append to `services/qmldir`**

```
singleton HyprlandKeybinds 1.0 HyprlandKeybinds.qml
```

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`. Expected: no errors. The categories list will be empty until section comments are added (Task 11) — that's expected.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/services/HyprlandKeybinds.qml quickshell/.config/quickshell/services/qmldir && git commit -m 'feat(quickshell): add HyprlandKeybinds service parsing hyprland.conf'
```

---

## Task 10: Cheatsheet overlay

**Files:**
- Create: `quickshell/.config/quickshell/modules/Cheatsheet.qml`
- Modify: `quickshell/.config/quickshell/shell.qml`

- [ ] **Step 1: Create `Cheatsheet.qml`**

```qml
// quickshell/.config/quickshell/modules/Cheatsheet.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    property bool open: false
    property string query: ""

    readonly property var filteredCategories: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return HyprlandKeybinds.categories;
        const out = [];
        for (let i = 0; i < HyprlandKeybinds.categories.length; ++i) {
            const cat = HyprlandKeybinds.categories[i];
            const binds = cat.binds.filter(b =>
                b.key.toLowerCase().includes(q)
                || b.mods.toLowerCase().includes(q)
                || b.action.toLowerCase().includes(q));
            if (binds.length > 0) out.push({ name: cat.name, binds: binds });
        }
        return out;
    }

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            HyprlandKeybinds.reload();
        }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; HyprlandKeybinds.reload(); }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 640
                height: 480
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: "keyboard"
                            color: Theme.textVariant
                            font.pixelSize: 22
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: "Keybinds"
                            color: Theme.text
                            font.pixelSize: Theme.font.size.larger
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        TextField {
                            id: searchField
                            Layout.preferredWidth: 240
                            placeholderText: "Filter…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.normal
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout {
                            width: searchField.parent.parent.width - Theme.padding.larger * 2
                            spacing: Theme.spacing.large

                            Repeater {
                                model: root.filteredCategories

                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing.small

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name.toUpperCase()
                                        color: Theme.textVariant
                                        font.pixelSize: Theme.font.size.small
                                        font.bold: true
                                    }
                                    Repeater {
                                        model: modelData.binds

                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: Theme.spacing.normal

                                            StyledRect {
                                                Layout.preferredWidth: 180
                                                implicitHeight: 24
                                                color: Theme.surfaceContainer
                                                border.color: Theme.outlineVariant
                                                border.width: 1
                                                radius: Theme.radius.small

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: modelData.mods.length > 0
                                                          ? (modelData.mods + " + " + modelData.key)
                                                          : modelData.key
                                                    color: Theme.text
                                                    font.pixelSize: Theme.font.size.small
                                                    font.family: Theme.font.family.mono
                                                }
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.action
                                                color: Theme.textVariant
                                                font.pixelSize: Theme.font.size.small
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                visible: root.filteredCategories.length === 0
                                StyledText {
                                    anchors.centerIn: parent
                                    text: HyprlandKeybinds.categories.length === 0
                                          ? "No keybinds parsed (add # Section: headers to hyprland.conf)"
                                          : "No matches"
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.font.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Modify `shell.qml`**

Add `Cheatsheet {}` to `ShellRoot`. Final file:

```qml
// quickshell/.config/quickshell/shell.qml
import Quickshell
import qs.modules

ShellRoot {
    Bar {}
    Notifications {}
    Launcher {}
    Power {}
    Clipboard {}
    WindowPicker {}
    Osd {}
    TagInput {}
    PassMenu {}
    EmojiPicker {}
    MediaControls {}
    Cheatsheet {}
}
```

- [ ] **Step 3: Verify reload**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

- [ ] **Step 4: Verify visual**

Run: `qs ipc call cheatsheet toggle`. Expected: centered card with "Keybinds" title, filter field, body shows "No keybinds parsed (add # Section: headers…)" until Task 11 adds them. ESC and click-outside dismiss.

- [ ] **Step 5: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Cheatsheet.qml quickshell/.config/quickshell/shell.qml && git commit -m 'feat(quickshell): add cheatsheet overlay parsing hyprland.conf binds'
```

---

## Task 11: Hyprland section comments + MOD+/ bind

**Files:**
- Modify: `hypr/.config/hypr/hyprland.conf`

- [ ] **Step 1: Add section comments and MOD+/ bind**

Edit `hypr/.config/hypr/hyprland.conf`. Replace the keybindings section (lines 131-219 in current file) with the following content. This adds `# Section:` headers and inserts `bind = $mainMod, slash, exec, qs ipc call cheatsheet toggle`:

```ini
###################
### KEYBINDINGS ###
###################

$mainMod = SUPER

# Section: Apps
bind = $mainMod, Return, exec, $terminal
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, D, exec, $launcher
bind = $mainMod, V, exec, qs ipc call clipboard toggle
bind = $mainMod, period, exec, qs ipc call emoji toggle
bind = $mainMod ALT, P, exec, qs ipc call pass toggle
bind = $mainMod, Z, exec, qs ipc call tag toggle
bind = ALT, Tab, exec, qs ipc call windows toggle
bind = $mainMod CTRL SHIFT ALT, V, exec, cliphist wipe

# Section: System
bind = $mainMod, L, exec, $powerMenu
bind = $mainMod, slash, exec, qs ipc call cheatsheet toggle
bind = $mainMod, M, exec, qs ipc call mediaControls toggle
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy

# Section: Window management
bind = $mainMod SHIFT, Q, killactive,
bind = $mainMod, Q, togglefloating,
bind = $mainMod, P, pseudo,
bind = $mainMod, J, layoutmsg, togglesplit

# Section: Focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Section: Move window
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

# Section: Workspaces
bind = $mainMod, 1, exec, hypr-workspace-pair goto 1
bind = $mainMod, 2, exec, hypr-workspace-pair goto 2
bind = $mainMod, 3, exec, hypr-workspace-pair goto 3
bind = $mainMod, 4, exec, hypr-workspace-pair goto 4
bind = $mainMod, 5, exec, hypr-workspace-pair goto 5
bind = $mainMod, 6, exec, hypr-workspace-pair goto 6
bind = $mainMod, 7, exec, hypr-workspace-pair goto 7
bind = $mainMod, 8, exec, hypr-workspace-pair goto 8
bind = $mainMod, 9, exec, hypr-workspace-pair goto 9
bind = $mainMod, 0, exec, hypr-workspace-pair goto 10

# Section: Move to workspace
bind = $mainMod SHIFT, 1, exec, hypr-workspace-grid move 1
bind = $mainMod SHIFT, 2, exec, hypr-workspace-grid move 2
bind = $mainMod SHIFT, 3, exec, hypr-workspace-grid move 3
bind = $mainMod SHIFT, 4, exec, hypr-workspace-grid move 4
bind = $mainMod SHIFT, 5, exec, hypr-workspace-grid move 5
bind = $mainMod SHIFT, 6, exec, hypr-workspace-grid move 6
bind = $mainMod SHIFT, 7, exec, hypr-workspace-grid move 7
bind = $mainMod SHIFT, 8, exec, hypr-workspace-grid move 8
bind = $mainMod SHIFT, 9, exec, hypr-workspace-grid move 9
bind = $mainMod SHIFT, 0, exec, hypr-workspace-grid move 10

# Section: Workspace rows
bind = $mainMod, Tab, submap, wsrows

submap = wsrows
bindi = , Tab, exec, hypr-workspace-pair cycle
bindi = , Tab, submap, reset
bindi = , 1, exec, hypr-workspace-pair row 1
bindi = , 1, submap, reset
bindi = , 2, exec, hypr-workspace-pair row 2
bindi = , 2, submap, reset
bindi = , 3, exec, hypr-workspace-pair row 3
bindi = , 3, submap, reset
bindi = , 4, exec, hypr-workspace-pair row 4
bindi = , 4, submap, reset
bindi = , escape, submap, reset
submap = reset

# Section: Mouse
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod SHIFT, mouse:272, resizewindow

# Section: Audio
bindel = ,XF86AudioRaiseVolume, exec, sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && qs ipc call osd volume'
bindel = ,XF86AudioLowerVolume, exec, sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call osd volume'
bindel = ,XF86AudioMute, exec, sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume'
bindel = ,XF86AudioMicMute, exec, sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd microphone'

# Section: Brightness
bindel = ,XF86MonBrightnessUp, exec, sh -c 'brightnessctl s 10%+ && qs ipc call osd brightness'
bindel = ,XF86MonBrightnessDown, exec, sh -c 'brightnessctl s 10%- && qs ipc call osd brightness'

# Section: Media
bindl = , XF86AudioNext,  exec, qs ipc call mpris next
bindl = , XF86AudioPause, exec, qs ipc call mpris playPause
bindl = , XF86AudioPlay,  exec, qs ipc call mpris playPause
bindl = , XF86AudioPrev,  exec, qs ipc call mpris previous
```

(Task 4 added `MOD+M` and the four `bindl` lines for media; Task 11 reorganizes the whole section. The `bind = $mainMod, M` line and `bindl` lines above must be in the file by end of Task 11. The `bindel = ...mic mute` line now also triggers `qs ipc call osd microphone` for Task 13.)

- [ ] **Step 2: Reload Hyprland**

Run: `hyprctl reload`
Expected: `ok`.

- [ ] **Step 3: Verify**

Press `Super+/`. Cheatsheet overlay opens. Categories present: Apps, System, Window management, Focus, Move window, Workspaces, Move to workspace, Workspace rows, Mouse, Audio, Brightness, Media. Each section lists its binds as `MODS + KEY` chips with the action description on the right. Type "term" in filter → only "Apps" section visible with the terminal bind.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add hypr/.config/hypr/hyprland.conf && git commit -m 'feat(hyprland): add section comments + cheatsheet bind'
```

---

## Task 12: Rewrite Notifications.qml

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Notifications.qml`

The rewrite adds: action buttons, app icon chip, hover-to-pause expire, slide-in animation, max-5 visible with overflow indicator. Stack model is `server.trackedNotifications.values` (same source).

- [ ] **Step 1: Replace `Notifications.qml`**

Replace entire file:

```qml
// quickshell/.config/quickshell/modules/Notifications.qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.components

Scope {
    id: root

    readonly property int maxVisible: 5

    NotificationServer {
        id: server
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: false
        persistenceSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
        }
    }

    readonly property var visibleNotifications: {
        const all = server.trackedNotifications.values;
        if (all.length <= root.maxVisible) return all;
        return all.slice(0, root.maxVisible);
    }

    readonly property int overflowCount: Math.max(0, server.trackedNotifications.values.length - root.maxVisible)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: server.trackedNotifications.values.length > 0

            anchors {
                top: true
                right: true
            }

            margins {
                top: Theme.padding.larger
                right: Theme.padding.larger
            }

            implicitWidth: 380
            implicitHeight: stack.implicitHeight
            color: "transparent"

            ColumnLayout {
                id: stack
                width: parent.width
                spacing: Theme.spacing.normal

                StyledRect {
                    Layout.fillWidth: true
                    visible: root.overflowCount > 0
                    implicitHeight: overflowLabel.implicitHeight + Theme.padding.normal * 2
                    color: Theme.background
                    border.color: Theme.outlineVariant
                    border.width: 1
                    radius: Theme.radius.full

                    StyledText {
                        id: overflowLabel
                        anchors.centerIn: parent
                        text: "+" + root.overflowCount + " more"
                        color: Theme.textVariant
                        font.pixelSize: Theme.font.size.small
                    }
                }

                Repeater {
                    model: root.visibleNotifications

                    StyledRect {
                        id: card
                        required property var modelData
                        property bool hovered: hoverHandler.hovered
                        property bool dismissed: false

                        Layout.fillWidth: true
                        implicitHeight: content.implicitHeight + Theme.padding.large * 2
                        color: Theme.background
                        border.color: Theme.outlineVariant
                        border.width: 1
                        radius: Theme.radius.large
                        opacity: dismissed ? 0 : 1
                        x: dismissed ? width + 20 : 0

                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InCubic } }

                        Component.onCompleted: {
                            x = width + 20;
                            slideInAnim.start();
                        }

                        NumberAnimation {
                            id: slideInAnim
                            target: card
                            property: "x"
                            from: card.width + 20
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                        HoverHandler { id: hoverHandler }

                        ColumnLayout {
                            id: content
                            anchors.fill: parent
                            anchors.margins: Theme.padding.large
                            spacing: Theme.spacing.normal

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.large

                                StyledRect {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: Theme.radius.full
                                    color: Theme.surfaceContainer
                                    border.color: Theme.outlineVariant
                                    border.width: 1

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "notifications"
                                        color: Theme.tertiary
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing.smaller

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: card.modelData.summary
                                        color: Theme.text
                                        font.pixelSize: Theme.font.size.normal
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: card.modelData.body.length > 0
                                        text: card.modelData.body
                                        color: Theme.textVariant
                                        font.pixelSize: Theme.font.size.small
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 4
                                        textFormat: Text.MarkdownText
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: card.modelData.actions.values.length > 0
                                spacing: Theme.spacing.small

                                Repeater {
                                    model: card.modelData.actions.values

                                    StyledRect {
                                        id: actionBtn
                                        required property var modelData
                                        property bool hovered: actionHover.hovered

                                        Layout.preferredHeight: 24
                                        implicitWidth: actionLabel.implicitWidth + Theme.padding.normal * 2
                                        color: actionBtn.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                                        border.color: Theme.outlineVariant
                                        border.width: 1
                                        radius: Theme.radius.full

                                        HoverHandler { id: actionHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                actionBtn.modelData.invoke();
                                                card.dismissed = true;
                                            }
                                        }

                                        StyledText {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: actionBtn.modelData.text
                                            color: Theme.text
                                            font.pixelSize: Theme.font.size.small
                                        }
                                    }
                                }
                            }
                        }

                        Timer {
                            interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                            running: !card.hovered && !card.dismissed
                            onTriggered: card.dismissed = true
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            propagateComposedEvents: true
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.MiddleButton) card.dismissed = true;
                            }
                        }

                        onDismissedChanged: if (dismissed) dismissTimer.restart()
                        Timer {
                            id: dismissTimer
                            interval: 220
                            onTriggered: card.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify reload**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

- [ ] **Step 3: Verify visual**

Run: `notify-send 'Test' 'Body text here'`. Toast slides in from right with title bold and body below. Hover over it → 5s expire timer is paused (toast persists). Mouse away → resumes. Middle-click → dismisses with slide-out. Run 6 notifications: `for i in 1 2 3 4 5 6; do notify-send "Test $i" "body $i"; done`. Expected: 5 visible toasts plus a "+1 more" pill at the top.

Action buttons: `notify-send -A "Yes=Ok" -A "No=Cancel" 'Confirm?' 'Body'` → two action buttons under body. Click → dismisses + invokes action.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Notifications.qml && git commit -m 'feat(quickshell): rewrite notifications with action buttons + hover-pause + overflow'
```

---

## Task 13: Rewrite Osd.qml

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Osd.qml`

The rewrite: bigger capsule (360×72), OutBack ease on value bar, microphone indicator (third kind), refined icon mapping.

- [ ] **Step 1: Replace `Osd.qml`**

```qml
// quickshell/.config/quickshell/modules/Osd.qml
import Quickshell
import Quickshell.Io
import QtQuick
import qs.components
import qs.services

Scope {
    id: root

    // "volume" | "brightness" | "microphone"
    property string kind: ""
    property int value: 0
    property bool muted: false
    property bool active: false

    function show(): void {
        root.active = true;
        hideTimer.restart();
    }

    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cols = this.text.trim().split(",");
                if (cols.length < 4) return;
                root.kind = "brightness";
                root.value = parseInt(cols[3].replace("%", ""), 10);
                root.muted = false;
                root.show();
            }
        }
    }

    Process {
        id: micRead
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (!m) return;
                root.kind = "microphone";
                root.value = Math.round(parseFloat(m[1]) * 100);
                root.muted = m[2] !== undefined;
                root.show();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.active = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            if (root.kind === "volume" || !root.active) {
                root.kind = "volume";
                root.value = Audio.volume;
                root.muted = Audio.muted;
            }
        }
        function onMutedChanged() {
            root.kind = "volume";
            root.value = Audio.volume;
            root.muted = Audio.muted;
        }
    }

    IpcHandler {
        target: "osd"
        function volume(): void {
            Audio.refresh();
            root.kind = "volume";
            root.value = Audio.volume;
            root.muted = Audio.muted;
            root.show();
        }
        function brightness(): void {
            brightRead.running = true;
        }
        function microphone(): void {
            micRead.running = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active

            anchors {
                bottom: true
                left: true
                right: true
            }

            margins {
                bottom: 80
            }

            implicitHeight: 90
            color: "transparent"

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 360
                implicitHeight: 72
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.full

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.kind === "brightness") return "brightness_6";
                            if (root.kind === "microphone") return root.muted ? "mic_off" : "mic";
                            if (root.muted) return "volume_off";
                            if (root.value === 0) return "volume_mute";
                            if (root.value < 50) return "volume_down";
                            return "volume_up";
                        }
                        color: root.muted ? Theme.textDim : Theme.text
                        font.pixelSize: 28
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 220
                        implicitHeight: 10

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHigh
                            radius: Theme.radius.full
                        }

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.value / 100))
                            height: parent.height
                            color: root.muted ? Theme.textDim : Theme.primary
                            radius: Theme.radius.full

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.anim.durations.normal
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.4
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.muted ? "--" : (root.value + "%")
                        color: Theme.text
                        font.pixelSize: Theme.font.size.large
                        font.bold: true
                        width: 56
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify reload**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

- [ ] **Step 3: Verify visual**

Press XF86AudioRaiseVolume (or run `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && qs ipc call osd volume`). Expected: bigger capsule with bouncy bar.
Press XF86MonBrightnessUp (or run `brightnessctl s 10%+ && qs ipc call osd brightness`). Expected: brightness OSD with `brightness_6` icon.
Press XF86AudioMicMute (or run `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd microphone`). Expected: microphone OSD with `mic`/`mic_off` icon and `--` when muted.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Osd.qml && git commit -m 'feat(quickshell): rewrite osd with microphone indicator + outback ease'
```

---

## Task 14: Rewrite Launcher.qml

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Launcher.qml`

The rewrite adds math evaluation and `>` shell command escape, alongside app search.

- [ ] **Step 1: Replace `Launcher.qml`**

```qml
// quickshell/.config/quickshell/modules/Launcher.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property bool isShellCmd: root.query.startsWith(">")
    readonly property string shellCmd: root.query.substring(1).trim()
    readonly property bool isMath: /^[\d+\-*/().\s%]+$/.test(root.query) && root.query.trim().length > 0
    readonly property string mathResult: {
        if (!root.isMath) return "";
        try {
            const expr = root.query.replace(/%/g, "/100");
            const fn = new Function("return (" + expr + ")");
            const r = fn();
            if (typeof r !== "number" || !isFinite(r)) return "";
            return "= " + r;
        } catch (_) { return ""; }
    }

    readonly property var filteredApps: {
        const q = root.query.toLowerCase();
        const all = DesktopEntries.applications.values;
        const filtered = all.filter(app => {
            if (app.noDisplay) return false;
            if (q.length === 0) return true;
            return app.name.toLowerCase().includes(q)
                || (app.genericName || "").toLowerCase().includes(q)
                || (app.comment || "").toLowerCase().includes(q);
        });
        filtered.sort((a, b) => a.name.localeCompare(b.name));
        return filtered.slice(0, 8);
    }

    readonly property var resultRows: {
        const rows = [];
        if (root.isShellCmd && root.shellCmd.length > 0) {
            rows.push({ kind: "shell", primary: "Run: " + root.shellCmd, secondary: "shell command" });
        }
        if (root.isMath && root.mathResult.length > 0) {
            rows.push({ kind: "math", primary: root.mathResult, secondary: root.query });
        }
        const apps = root.filteredApps;
        for (let i = 0; i < apps.length; ++i) {
            rows.push({ kind: "app", app: apps[i], primary: apps[i].name, secondary: apps[i].genericName || "" });
        }
        return rows;
    }

    onResultRowsChanged: root.currentIndex = 0

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function activateSelected(): void {
        const list = root.resultRows;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const row = list[root.currentIndex];
        root.open = false;
        if (row.kind === "app") {
            row.app.execute();
        } else if (row.kind === "shell") {
            Quickshell.execDetached(["sh", "-c", root.shellCmd]);
        } else if (row.kind === "math") {
            copyProc.command = ["sh", "-c", `printf '%s' '${row.primary.substring(2)}' | wl-copy`];
            copyProc.running = true;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.resultRows.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    Process { id: copyProc }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 600
                height: 520
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isShellCmd ? "terminal" : (root.isMath ? "calculate" : "search")
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Type to search apps, > for shell, or math…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activateSelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.resultRows
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 40
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.padding.large
                                anchors.rightMargin: Theme.padding.large
                                spacing: Theme.spacing.large

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        if (modelData.kind === "shell") return "terminal";
                                        if (modelData.kind === "math") return "calculate";
                                        return "apps";
                                    }
                                    color: Theme.textDim
                                    font.pixelSize: 18
                                    width: 20
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.primary
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.secondary
                                    color: Theme.textDim
                                    font.pixelSize: Theme.font.size.small
                                    visible: text.length > 0
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                                onClicked: {
                                    root.currentIndex = index;
                                    root.activateSelected();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify reload**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

- [ ] **Step 3: Verify visual**

Press `Super+D`. Launcher opens. Type "fire" → Firefox first row. Type `1+2*3` → "= 7" math row. Type `> notify-send hi` → "Run: notify-send hi" shell row at top. Enter on math row → result is copied to clipboard. Enter on shell row → command runs. Esc dismisses.

- [ ] **Step 4: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Launcher.qml && git commit -m 'feat(quickshell): rewrite launcher with math + shell command support'
```

---

## Task 15: Rewrite Power.qml

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Power.qml`

The rewrite: bigger cards, keyboard nav, reboot/shutdown confirm.

- [ ] **Step 1: Replace `Power.qml`**

```qml
// quickshell/.config/quickshell/modules/Power.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components

Scope {
    id: root

    property bool open: false
    property int currentIndex: 0
    property int confirmingIndex: -1     // index of card awaiting confirmation, or -1

    readonly property var actions: [
        { label: "Lock",     icon: "lock",              cmd: ["hyprlock"],                 confirm: false },
        { label: "Logout",   icon: "logout",            cmd: ["hyprctl", "dispatch", "exit"], confirm: false },
        { label: "Suspend",  icon: "bedtime",           cmd: ["systemctl", "suspend"],     confirm: false },
        { label: "Reboot",   icon: "refresh",           cmd: ["systemctl", "reboot"],      confirm: true },
        { label: "Shutdown", icon: "power_settings_new", cmd: ["systemctl", "poweroff"],   confirm: true }
    ]

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.currentIndex = 0;
            root.confirmingIndex = -1;
        }
    }

    function activate(index: int): void {
        if (index < 0 || index >= root.actions.length) return;
        const a = root.actions[index];
        if (a.confirm && root.confirmingIndex !== index) {
            root.confirmingIndex = index;
            return;
        }
        root.open = false;
        root.confirmingIndex = -1;
        Quickshell.execDetached(a.cmd);
    }

    function moveSelection(delta: int): void {
        const len = root.actions.length;
        root.currentIndex = (root.currentIndex + delta + len) % len;
        root.confirmingIndex = -1;
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; root.currentIndex = 0; root.confirmingIndex = -1; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                focus: true
                onClicked: root.open = false
                Keys.onEscapePressed: root.open = false
                Keys.onLeftPressed: root.moveSelection(-1)
                Keys.onRightPressed: root.moveSelection(1)
                Keys.onReturnPressed: root.activate(root.currentIndex)
                Keys.onEnterPressed: root.activate(root.currentIndex)
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: buttonRow.implicitWidth + Theme.padding.larger * 2
                implicitHeight: buttonRow.implicitHeight + Theme.padding.larger * 2
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: buttonRow
                    anchors.centerIn: parent
                    spacing: Theme.spacing.extraLarge

                    Repeater {
                        model: root.actions

                        StyledRect {
                            id: card
                            required property var modelData
                            required property int index
                            property bool hovered: cardHover.hovered
                            property bool selected: index === root.currentIndex
                            property bool confirming: index === root.confirmingIndex

                            implicitWidth: 160
                            implicitHeight: 160
                            color: card.confirming ? Theme.warning :
                                   (card.hovered || card.selected ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                            border.color: card.confirming ? Theme.warning :
                                          (card.hovered || card.selected ? Theme.primary : Theme.outlineVariant)
                            border.width: 1
                            radius: Theme.radius.large
                            scale: card.hovered || card.selected ? 1.04 : 1.0

                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            HoverHandler { id: cardHover }

                            StateLayer { id: layer; radius: parent.radius }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacing.normal

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: card.confirming ? "warning" : card.modelData.icon
                                    color: card.confirming ? Theme.textOnPrimary :
                                           (card.hovered || card.selected ? Theme.primary : Theme.text)
                                    font.pixelSize: 48
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: card.confirming ? "Confirm?" : card.modelData.label
                                    color: card.confirming ? Theme.textOnPrimary : Theme.text
                                    font.pixelSize: Theme.font.size.large
                                    font.bold: card.confirming
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = card.index
                                onClicked: root.activate(card.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify reload + visual**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

Press `Super+L`. Power overlay opens with 5 cards (160px each, spaced 24px). Arrow Left/Right moves selection (border + scale animate). Enter on Lock → fires hyprlock immediately. Esc → closes. Enter on Reboot → card turns warning-coloured with "Confirm?" label and warning icon; another Enter → fires `systemctl reboot`. Click outside → closes.

- [ ] **Step 3: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Power.qml && git commit -m 'feat(quickshell): rewrite power overlay with kbd nav + reboot/shutdown confirm'
```

---

## Task 16: Rewrite Clipboard.qml

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Clipboard.qml`

The rewrite: image thumbnail rendering for image entries, content-type icons (image / link / text), delete via right-click.

- [ ] **Step 1: Replace `Clipboard.qml`**

```qml
// quickshell/.config/quickshell/modules/Clipboard.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0
    property var entries: []

    readonly property var filteredEntries: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return root.entries;
        return root.entries.filter(e => e.preview.toLowerCase().includes(q));
    }

    onFilteredEntriesChanged: root.currentIndex = 0

    function detectKind(preview: string): string {
        if (/^\[\[\s*binary data.*image/i.test(preview)) return "image";
        if (/^https?:\/\//.test(preview.trim())) return "link";
        return "text";
    }

    function toggle(): void {
        if (root.open) {
            root.open = false;
        } else {
            root.query = "";
            root.currentIndex = 0;
            listProc.running = true;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.filteredEntries.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function pasteSelected(): void {
        const list = root.filteredEntries;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const entry = list[root.currentIndex];
        root.open = false;
        copyProc.command = ["sh", "-c", `cliphist decode ${entry.id} | wl-copy`];
        copyProc.running = true;
    }

    function deleteEntry(id: string): void {
        deleteProc.command = ["sh", "-c", `echo '${id}' | cliphist delete`];
        deleteProc.running = true;
    }

    function clearAll(): void {
        root.open = false;
        wipeProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.length > 0);
                root.entries = lines.map(line => {
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx < 0) return { id: line, preview: line, kind: "text" };
                    const id = line.substring(0, tabIdx);
                    const preview = line.substring(tabIdx + 1);
                    return { id: id, preview: preview, kind: root.detectKind(preview) };
                });
                root.open = true;
            }
        }
    }

    Process { id: copyProc }
    Process {
        id: deleteProc
        onExited: listProc.running = true
    }
    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle(); }
        function clear(): void { root.clearAll(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 680
                height: 520
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "content_paste"
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search clipboard…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.pasteSelected();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Delete) {
                                    const list = root.filteredEntries;
                                    if (root.currentIndex >= 0 && root.currentIndex < list.length) {
                                        root.deleteEntry(list[root.currentIndex].id);
                                    }
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.filteredEntries
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 48
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.padding.large
                                anchors.rightMargin: Theme.padding.large
                                spacing: Theme.spacing.large

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.id
                                    color: Theme.textDim
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.family.mono
                                    width: 44
                                    elide: Text.ElideRight
                                }

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        if (modelData.kind === "image") return "image";
                                        if (modelData.kind === "link") return "link";
                                        return "subject";
                                    }
                                    color: Theme.textDim
                                    font.pixelSize: 18
                                    width: 22
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.kind === "image" ? "[image]" : modelData.preview
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                    width: parent.width - 44 - 22 - parent.spacing * 3
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: root.currentIndex = index
                                onClicked: function(mouse) {
                                    root.currentIndex = index;
                                    if (mouse.button === Qt.RightButton) {
                                        root.deleteEntry(modelData.id);
                                    } else {
                                        root.pasteSelected();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify reload + visual**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

Copy a text, link (`https://example.com`), and image (`grim - | wl-copy`). Press `Super+V`. Each entry shows kind icon + preview ("[image]" for images). Right-click an entry or hit `Delete` → entry removed, list re-fetches. Click → pastes. ESC dismisses.

- [ ] **Step 3: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/modules/Clipboard.qml && git commit -m 'feat(quickshell): rewrite clipboard with kind icons + right-click delete'
```

---

## Task 17: Emojis service + EmojiPicker rewrite

**Files:**
- Create: `quickshell/.config/quickshell/services/Emojis.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`
- Modify: `quickshell/.config/quickshell/modules/EmojiPicker.qml`

The rewrite: move emoji dataset into a service, group by category, support recents (persisted via `~/.config/quickshell/state/emoji-recents.json`).

- [ ] **Step 1: Create `Emojis.qml`**

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Categories of emojis. Each is { name, items: [{ch, name}] }.
    readonly property var categories: [
        { name: "Smileys", items: [
            { ch: "😀", name: "grinning face" },
            { ch: "😁", name: "beaming face" },
            { ch: "😂", name: "tears of joy" },
            { ch: "🤣", name: "rolling on floor laughing rofl" },
            { ch: "😃", name: "grinning big eyes" },
            { ch: "😄", name: "grinning smiling eyes" },
            { ch: "😅", name: "grinning sweat" },
            { ch: "😆", name: "grinning squinting" },
            { ch: "😉", name: "winking" },
            { ch: "😊", name: "smiling blush" },
            { ch: "😎", name: "smiling sunglasses cool" },
            { ch: "😍", name: "smiling heart eyes love" },
            { ch: "😘", name: "kiss face" },
            { ch: "🥰", name: "smiling hearts love" },
            { ch: "🤔", name: "thinking" },
            { ch: "🤨", name: "raised eyebrow skeptical" },
            { ch: "😐", name: "neutral" },
            { ch: "😑", name: "expressionless" },
            { ch: "😶", name: "no mouth" },
            { ch: "🙄", name: "rolling eyes" },
            { ch: "😏", name: "smirking" },
            { ch: "😣", name: "persevering" },
            { ch: "😥", name: "sad relieved" },
            { ch: "😮", name: "open mouth surprise" },
            { ch: "🤐", name: "zipper mouth" },
            { ch: "😯", name: "hushed" },
            { ch: "😪", name: "sleepy" },
            { ch: "😫", name: "tired" },
            { ch: "😴", name: "sleeping" },
            { ch: "😌", name: "relieved" },
            { ch: "😛", name: "tongue" },
            { ch: "😜", name: "winking tongue" },
            { ch: "😝", name: "squinting tongue" },
            { ch: "🤤", name: "drooling" },
            { ch: "😒", name: "unamused annoyed" },
            { ch: "😓", name: "downcast sweat" },
            { ch: "😔", name: "pensive sad" },
            { ch: "😕", name: "confused" },
            { ch: "🙃", name: "upside down" },
            { ch: "🤑", name: "money mouth" },
            { ch: "😲", name: "astonished shocked" },
            { ch: "☹️", name: "frowning" },
            { ch: "🙁", name: "slightly frowning" },
            { ch: "😖", name: "confounded" },
            { ch: "😞", name: "disappointed sad" },
            { ch: "😟", name: "worried" },
            { ch: "😤", name: "huffing triumph" },
            { ch: "😢", name: "crying tear" },
            { ch: "😭", name: "loudly crying sob" },
            { ch: "😦", name: "frowning open mouth" },
            { ch: "😧", name: "anguished" },
            { ch: "😨", name: "fearful scared" },
            { ch: "😩", name: "weary" },
            { ch: "🤯", name: "exploding head mind blown" },
            { ch: "😬", name: "grimacing" },
            { ch: "😰", name: "anxious sweat" },
            { ch: "😱", name: "screaming fear scream" },
            { ch: "🥵", name: "hot" },
            { ch: "🥶", name: "cold freezing" },
            { ch: "😳", name: "flushed" },
            { ch: "🤪", name: "zany silly" },
            { ch: "😵", name: "dizzy" },
            { ch: "🥴", name: "woozy drunk" },
            { ch: "😡", name: "pouting angry rage" },
            { ch: "😠", name: "angry" },
            { ch: "🤬", name: "swearing cursing" },
            { ch: "😷", name: "medical mask" },
            { ch: "🤒", name: "thermometer sick" },
            { ch: "🤕", name: "head bandage hurt" },
            { ch: "🤢", name: "nauseated sick" },
            { ch: "🤮", name: "vomiting" },
            { ch: "🤧", name: "sneezing" },
            { ch: "😇", name: "halo innocent angel" },
            { ch: "🤠", name: "cowboy" },
            { ch: "🤡", name: "clown" },
            { ch: "🥳", name: "party hat celebrate" },
            { ch: "🥺", name: "pleading begging" },
            { ch: "🤥", name: "lying pinocchio" },
            { ch: "🤫", name: "shushing quiet" },
            { ch: "🤭", name: "hand over mouth" },
            { ch: "🧐", name: "monocle inspect" },
            { ch: "🤓", name: "nerd glasses" }
        ]},
        { name: "Hands", items: [
            { ch: "👍", name: "thumbs up ok yes" },
            { ch: "👎", name: "thumbs down no" },
            { ch: "👌", name: "ok hand" },
            { ch: "✌️", name: "peace victory" },
            { ch: "🤞", name: "fingers crossed hope" },
            { ch: "🤟", name: "love you sign" },
            { ch: "🤘", name: "rock metal horns" },
            { ch: "🤙", name: "call me hang loose" },
            { ch: "👈", name: "point left" },
            { ch: "👉", name: "point right" },
            { ch: "👆", name: "point up" },
            { ch: "👇", name: "point down" },
            { ch: "☝️", name: "point up index" },
            { ch: "✋", name: "raised hand stop" },
            { ch: "🤚", name: "raised back hand" },
            { ch: "🖐️", name: "five fingers splayed" },
            { ch: "🖖", name: "vulcan salute" },
            { ch: "👋", name: "waving hello bye" },
            { ch: "🤝", name: "handshake deal" },
            { ch: "🙏", name: "praying thanks please" },
            { ch: "💪", name: "flexed biceps strong" },
            { ch: "🦾", name: "mechanical arm" },
            { ch: "👏", name: "clap" },
            { ch: "🙌", name: "raising hands celebration" },
            { ch: "👐", name: "open hands" },
            { ch: "🤲", name: "palms up together" },
            { ch: "✊", name: "raised fist" },
            { ch: "👊", name: "fist bump punch" }
        ]},
        { name: "Hearts", items: [
            { ch: "❤️", name: "red heart love" },
            { ch: "🧡", name: "orange heart" },
            { ch: "💛", name: "yellow heart" },
            { ch: "💚", name: "green heart" },
            { ch: "💙", name: "blue heart" },
            { ch: "💜", name: "purple heart" },
            { ch: "🖤", name: "black heart" },
            { ch: "🤍", name: "white heart" },
            { ch: "🤎", name: "brown heart" },
            { ch: "💔", name: "broken heart" },
            { ch: "❣️", name: "heart exclamation" },
            { ch: "💕", name: "two hearts" },
            { ch: "💖", name: "sparkling heart" },
            { ch: "💗", name: "growing heart" },
            { ch: "💘", name: "heart arrow cupid" },
            { ch: "💝", name: "heart ribbon gift" },
            { ch: "💞", name: "revolving hearts" },
            { ch: "💟", name: "heart decoration" }
        ]},
        { name: "Symbols", items: [
            { ch: "✨", name: "sparkles" },
            { ch: "⭐", name: "star" },
            { ch: "🌟", name: "glowing star" },
            { ch: "🔥", name: "fire flame hot lit" },
            { ch: "💯", name: "hundred 100" },
            { ch: "💢", name: "anger symbol" },
            { ch: "💥", name: "boom explosion" },
            { ch: "💫", name: "dizzy stars" },
            { ch: "💦", name: "sweat droplets" },
            { ch: "💨", name: "dashing away" },
            { ch: "✅", name: "check mark green tick" },
            { ch: "❌", name: "cross x wrong" },
            { ch: "❓", name: "question mark" },
            { ch: "❗", name: "exclamation mark" },
            { ch: "⚠️", name: "warning" },
            { ch: "⚡", name: "high voltage lightning" }
        ]},
        { name: "Food", items: [
            { ch: "🎉", name: "party popper celebration" },
            { ch: "🎊", name: "confetti ball" },
            { ch: "🎁", name: "gift present" },
            { ch: "🎂", name: "birthday cake" },
            { ch: "🍰", name: "cake slice" },
            { ch: "🍕", name: "pizza" },
            { ch: "🍔", name: "burger" },
            { ch: "🍟", name: "fries" },
            { ch: "🌭", name: "hot dog" },
            { ch: "🍦", name: "ice cream soft" },
            { ch: "🍩", name: "donut" },
            { ch: "🍪", name: "cookie" },
            { ch: "🍫", name: "chocolate bar" },
            { ch: "🍿", name: "popcorn" },
            { ch: "🍺", name: "beer" },
            { ch: "🍻", name: "clinking beers" },
            { ch: "🍷", name: "wine glass" },
            { ch: "🥃", name: "tumbler whiskey" },
            { ch: "🍸", name: "cocktail" },
            { ch: "☕", name: "coffee hot beverage" },
            { ch: "🍵", name: "tea" }
        ]},
        { name: "Animals", items: [
            { ch: "🐶", name: "dog face" },
            { ch: "🐱", name: "cat face" },
            { ch: "🐭", name: "mouse face" },
            { ch: "🐹", name: "hamster" },
            { ch: "🐰", name: "rabbit bunny" },
            { ch: "🦊", name: "fox" },
            { ch: "🐻", name: "bear" },
            { ch: "🐼", name: "panda" },
            { ch: "🐨", name: "koala" },
            { ch: "🐯", name: "tiger" },
            { ch: "🦁", name: "lion" },
            { ch: "🐸", name: "frog" },
            { ch: "🐵", name: "monkey face" },
            { ch: "🙈", name: "see no evil monkey" },
            { ch: "🙉", name: "hear no evil monkey" },
            { ch: "🙊", name: "speak no evil monkey" }
        ]},
        { name: "Tech", items: [
            { ch: "🚀", name: "rocket ship launch" },
            { ch: "💻", name: "laptop computer" },
            { ch: "🖥️", name: "desktop computer" },
            { ch: "⌨️", name: "keyboard" },
            { ch: "🖱️", name: "mouse computer" },
            { ch: "🎮", name: "video game gamepad" },
            { ch: "📱", name: "phone mobile" },
            { ch: "📷", name: "camera" },
            { ch: "🎵", name: "music note" },
            { ch: "🎶", name: "multiple notes" },
            { ch: "🔊", name: "speaker loud" },
            { ch: "🔇", name: "speaker muted" },
            { ch: "📚", name: "books" },
            { ch: "🔒", name: "locked" },
            { ch: "🔓", name: "unlocked" },
            { ch: "🔑", name: "key" },
            { ch: "🔧", name: "wrench tool" },
            { ch: "🔨", name: "hammer" },
            { ch: "💡", name: "light bulb idea" }
        ]}
    ]

    // Flat list of all emoji {ch, name, category}
    readonly property var allEmojis: {
        const out = [];
        for (let i = 0; i < categories.length; ++i) {
            for (let j = 0; j < categories[i].items.length; ++j) {
                const e = categories[i].items[j];
                out.push({ ch: e.ch, name: e.name, category: categories[i].name });
            }
        }
        return out;
    }

    // Recents — capped at 24, MRU at index 0
    property var recents: []

    function bumpRecent(ch: string): void {
        const cur = root.recents.filter(c => c !== ch);
        cur.unshift(ch);
        root.recents = cur.slice(0, 24);
        recentsFile.setText(JSON.stringify(root.recents));
    }

    FileView {
        id: recentsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/emoji-recents.json"
        watchChanges: false
        onLoaded: {
            try {
                const arr = JSON.parse(this.text());
                if (Array.isArray(arr)) root.recents = arr.slice(0, 24);
            } catch (_) { /* ignore */ }
        }
        Component.onCompleted: recentsFile.reload()
    }
}
```

- [ ] **Step 2: Append to `services/qmldir`**

```
singleton Emojis 1.0 Emojis.qml
```

- [ ] **Step 3: Create state directory**

Run: `mkdir -p ~/.config/quickshell/state`

(This is a one-time runtime setup, not a tracked file. The Ansible role in Task 18 will ensure the directory exists on fresh machines.)

- [ ] **Step 4: Replace `EmojiPicker.qml`**

```qml
// quickshell/.config/quickshell/modules/EmojiPicker.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property var allFiltered: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return Emojis.allEmojis;
        return Emojis.allEmojis.filter(e => e.name.includes(q) || e.ch === q);
    }

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.allFiltered.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function copySelected(): void {
        const list = root.allFiltered;
        if (root.currentIndex < 0 || root.currentIndex >= list.length) return;
        const e = list[root.currentIndex];
        root.open = false;
        Emojis.bumpRecent(e.ch);
        copyProc.command = ["sh", "-c", `printf '%s' '${e.ch}' | wl-copy`];
        copyProc.running = true;
    }

    Process { id: copyProc }

    IpcHandler {
        target: "emoji"
        function toggle(): void { root.toggle(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 560
                height: 520
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: "mood"
                            color: Theme.textVariant
                            font.pixelSize: 22
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search emoji…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Right) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(12);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-12);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.copySelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout {
                            width: searchField.parent.parent.width - Theme.padding.larger * 2
                            spacing: Theme.spacing.normal

                            // Recents section
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.small
                                visible: root.query.length === 0 && Emojis.recents.length > 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: "RECENT"
                                    color: Theme.textVariant
                                    font.pixelSize: Theme.font.size.small
                                    font.bold: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 12
                                    columnSpacing: 4
                                    rowSpacing: 4

                                    Repeater {
                                        model: Emojis.recents

                                        StyledRect {
                                            required property string modelData
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            color: recHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                                            radius: Theme.radius.small

                                            HoverHandler { id: recHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                font.pixelSize: 22
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    root.open = false;
                                                    Emojis.bumpRecent(parent.modelData);
                                                    copyProc.command = ["sh", "-c", `printf '%s' '${parent.modelData}' | wl-copy`];
                                                    copyProc.running = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Categories (or full filtered grid when searching)
                            Repeater {
                                model: root.query.length === 0 ? Emojis.categories : [{ name: "Results", items: root.allFiltered }]

                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing.small

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name.toUpperCase()
                                        color: Theme.textVariant
                                        font.pixelSize: Theme.font.size.small
                                        font.bold: true
                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 12
                                        columnSpacing: 4
                                        rowSpacing: 4

                                        Repeater {
                                            model: modelData.items

                                            StyledRect {
                                                required property var modelData
                                                Layout.preferredWidth: 36
                                                Layout.preferredHeight: 36
                                                color: gridHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                                                radius: Theme.radius.small

                                                HoverHandler { id: gridHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: parent.modelData.ch
                                                    font.pixelSize: 22
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        root.open = false;
                                                        Emojis.bumpRecent(parent.modelData.ch);
                                                        copyProc.command = ["sh", "-c", `printf '%s' '${parent.modelData.ch}' | wl-copy`];
                                                        copyProc.running = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 5: Verify reload + visual**

Run: `qs log 2>&1 | tail -30`. Expected: no errors.

Press `Super+.`. Picker shows: optional RECENT section (empty first run), then categories (Smileys, Hands, Hearts, Symbols, Food, Animals, Tech) each with grid of emoji. Click any → wl-copied, panel closes, emoji added to recents. Reopen → RECENT section shows it. Type "fire" → filters to a flat grid under "RESULTS" header.

- [ ] **Step 6: Commit**

```bash
cd /home/atqa/dotfiles && git add quickshell/.config/quickshell/services/Emojis.qml quickshell/.config/quickshell/services/qmldir quickshell/.config/quickshell/modules/EmojiPicker.qml && git commit -m 'feat(quickshell): rewrite emoji picker with categories + recents'
```

---

## Task 18: Ansible role package updates

**Files:**
- Modify: `ansible/roles/hyprland/tasks/main.yaml`

Ensure `bluez-tools` (for `bluetoothctl`), `cliphist` (clipboard history), and a state dir for emoji recents exist on fresh machines.

- [ ] **Step 1: Inspect current role**

Run: `cat ~/repo/dotmachines/ansible/roles/hyprland/tasks/main.yaml | head -60`
Expected: shows current dnf install tasks.

- [ ] **Step 2: Add package + state-dir tasks**

Open `ansible/roles/hyprland/tasks/main.yaml`. Find the existing dnf install grouping (look for the last `dnf:` task block). Append the following tasks after the last existing dnf install task (use Edit with a unique anchor near the end of the file):

```yaml
- name: ensure bluez-tools (for quickshell Bluetooth pill)
  become: true
  ansible.builtin.dnf:
    name:
      - bluez
      - bluez-tools
    state: present

- name: ensure cliphist (clipboard history backend)
  become: true
  ansible.builtin.dnf:
    name:
      - cliphist
    state: present

- name: ensure quickshell state directory exists
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.config/quickshell/state"
    state: directory
    mode: '0755'
```

(Exact placement: any spot in the role's `tasks/main.yaml` after pre-existing dnf tasks and before the role's `meta` tasks if any. If the role is purely linear, append at the very end.)

- [ ] **Step 3: Verify role syntax**

Run: `cd ~/repo/dotmachines && ansible-playbook ansible/playbooks/bootstrap.yaml --syntax-check`
Expected: no errors.

- [ ] **Step 4: Run role in check mode**

Run: `cd ~/repo/dotmachines && ansible-playbook ansible/playbooks/bootstrap.yaml --check --diff --tags hyprland -l localhost`
Expected: tasks show either "ok" (already installed) or "changed" (would install). No failures.

- [ ] **Step 5: Commit**

```bash
cd ~/repo/dotmachines && git add ansible/roles/hyprland/tasks/main.yaml && git commit -m 'feat(hyprland-role): ensure bluez-tools + cliphist + quickshell state dir'
```

---

## End-of-Phase verification

After all 18 tasks land, run the full smoke pass:

- [ ] **MPRIS:** `mpv ~/Music/*.mp3 &` → MediaPill shows title; MOD+M opens popup; play/pause/next via popup buttons and middle-/right-click on pill all work.
- [ ] **Tray:** start `slack` → TrayPill appears; left-click activates; right-click menu opens.
- [ ] **Bluetooth:** `bluetoothctl power off` → BT icon greys within 5s; click BT icon → toggles; connect headphones → icon becomes connected.
- [ ] **Cheatsheet:** MOD+/ opens overlay; categories listed; filter works; Esc dismisses.
- [ ] **Notifications:** `notify-send 'a' 'b'` → toast slides in; hover pauses timer; 6 sequential notifs → "+1 more" pill; action buttons fire and dismiss.
- [ ] **Osd:** vol/brightness/mic keys all produce 360×72 bouncy capsules.
- [ ] **Launcher:** "firefox" → app; "1+2" → "= 3"; "> ls" → "Run: ls"; Enter on math copies result; Esc dismisses.
- [ ] **Power:** MOD+L → 5 cards, arrows nav, Enter on Reboot → warning state, Enter again fires; Lock fires immediately.
- [ ] **Clipboard:** copy text+link+image; MOD+V shows kind icons; right-click deletes; click pastes.
- [ ] **EmojiPicker:** MOD+. shows categories; search filters; click bumps recents and copies; restart qs → recents persist.

If any smoke fails, fix in a follow-up commit before moving to Phase 2.

---

## Self-review notes

**Spec coverage:** All 10 Phase 1 spec components have tasks (Tier 1 new: 1-2, 5-6, 7-8, 9-10 + hyprland binds 4, 11; Rewrites: 12-17). Ansible side covered by 18.

**Type consistency:** `MprisService` named identically in service file, qmldir, MediaPill, MediaControls. `TrayService` same. `Bluetooth` same. `HyprlandKeybinds` same. `Emojis` same. IPC targets `mpris`, `mediaControls`, `cheatsheet`, `osd`, `clipboard`, `emoji`, `session`, `launcher` are all consistent across QML handlers and Hyprland binds.

**Identified gaps:**
- Tray menu rendering uses `QsMenuAnchor` which is the official Quickshell API for SystemTray menus. If this fails at reload (e.g., not available in 0.3.0), fallback is to drop the right-click menu and only support `item.activate()` on left-click — note in commit if needed.
- Notifications `action.invoke()` may be `actions.values[i].invoke()` depending on exact Quickshell API surface. If `invoke()` errors, change to `card.modelData.invokeAction(actionBtn.modelData.identifier)`.
- Cliphist delete: `echo '<id>' | cliphist delete` is the standard form; if user's cliphist version differs (some accept `cliphist delete <id>` directly), adjust.

**Phase 2 (deferred):** NotificationHistory, Updates badge, ResourcesPill (CPU/RAM/GPU/Claude) — separate plan to be written after Phase 1 is validated.
