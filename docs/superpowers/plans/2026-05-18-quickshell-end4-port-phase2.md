# Quickshell End-4 Port — Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land remaining Tier 2 modules from the end-4 port spec: notification history panel (MOD+N), DNF updates badge in StatusPill, and consolidated Resources pill (CPU/RAM/Nvidia GPU/Claude) that replaces the standalone ClaudePill.

**Architecture:** Three independent feature islands, each composed of one new service (singleton polling /proc or shelling out) + one new module (overlay or pill). Resources pill subsumes ClaudePill — old file deleted. NotificationHistory extends the Phase-1 Notifications module by adding an in-memory ring buffer keyed off `onNotification` signal. Theme stays pure-black; severity colours come from existing Theme tokens (`warning`/`error`).

**Tech Stack:** Quickshell 0.3.0 / Qt6 QML / `Quickshell.Services.Notifications` / `Quickshell.Io.Process` + `StdioCollector` / `Quickshell.Io.FileView` (none here, all in-memory) / Nvidia-smi CSV / dnf check-update exit codes.

---

## Files Touched

**Created:**
- `quickshell/.config/quickshell/services/Updates.qml`
- `quickshell/.config/quickshell/services/Resources.qml`
- `quickshell/.config/quickshell/modules/NotificationHistory.qml`
- `quickshell/.config/quickshell/modules/bar/ResourcesPill.qml`

**Modified:**
- `quickshell/.config/quickshell/services/qmldir` (add Updates + Resources)
- `quickshell/.config/quickshell/modules/Notifications.qml` (in-memory ring buffer)
- `quickshell/.config/quickshell/modules/bar/StatusPill.qml` (updates badge)
- `quickshell/.config/quickshell/modules/bar/BottomBar.qml` (replace ClaudePill → ResourcesPill, update PeekState watched list + Connections)
- `quickshell/.config/quickshell/shell.qml` (add NotificationHistory)
- `hypr/.config/hypr/hyprland.conf` (MOD+N bind in `# Section: Quickshell overlays`)

**Deleted:**
- `quickshell/.config/quickshell/modules/bar/ClaudePill.qml` (replaced by ResourcesPill — Claude usage now inline)

---

## Task 1: Notification History Panel

**Files:**
- Modify: `quickshell/.config/quickshell/modules/Notifications.qml` (add ring buffer + expose via `Notifications.history`)
- Create: `quickshell/.config/quickshell/modules/NotificationHistory.qml`
- Modify: `quickshell/.config/quickshell/shell.qml`
- Modify: `hypr/.config/hypr/hyprland.conf`

**Design notes:**
- Notifications.qml currently uses `Scope` with anonymous `NotificationServer` inside. The history needs to be visible to *another* module (NotificationHistory.qml). Two acceptable patterns: (a) move `NotificationServer` to a new `services/NotificationHistory.qml` singleton, or (b) give `Notifications` an `id: root` + `objectName: "Notifications"` and have NotificationHistory.qml locate it via `Quickshell.findChild`. Use (a) — cleaner.
- New singleton `services/NotificationHistory.qml`:
  - Wraps NotificationServer
  - Property `history: []` — ring buffer max 50
  - On `onNotification` push `{summary, body, appName, image, timestamp, persistent: false}` to head + trim to 50; mark `notif.tracked = true`
  - Function `clear()` empties history
  - Function `removeAt(idx)` splices one entry
  - IpcHandler `notificationHistory` { toggle/open/close/clear }
- Notifications.qml: change to *read* `NotificationHistory.server` (expose `server` as a property on the singleton) so the existing toast UI still works. This restructure also makes Notifications.qml smaller (logic moves to service).

**Implementation strategy:** since both Notifications.qml and NotificationHistory.qml need access to the same `NotificationServer` instance, hoist it to a singleton service. Refactor Notifications.qml to read `NotificationHistoryService.server.trackedNotifications.values` for its toast list.

- [ ] **Step 1: Create `services/NotificationHistory.qml`**

```qml
// quickshell/.config/quickshell/services/NotificationHistory.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 50
    property var history: []
    readonly property alias server: notifServer

    function _push(notif) {
        const entry = {
            id: Date.now() + "-" + Math.floor(Math.random() * 1000),
            summary: notif.summary || "",
            body: notif.body || "",
            appName: notif.appName || "",
            timestamp: Date.now()
        };
        const next = [entry].concat(root.history);
        if (next.length > root.historyLimit) next.length = root.historyLimit;
        root.history = next;
    }

    function clear() { root.history = []; }

    function removeAt(idx) {
        if (idx < 0 || idx >= root.history.length) return;
        const next = root.history.slice();
        next.splice(idx, 1);
        root.history = next;
    }

    NotificationServer {
        id: notifServer
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
            root._push(notif);
        }
    }

    IpcHandler {
        target: "notificationHistory"
        function toggle(): void { root._toggleCb && root._toggleCb(); }
        function open(): void   { root._openCb   && root._openCb();   }
        function close(): void  { root._closeCb  && root._closeCb();  }
        function clear(): void  { root.clear(); }
    }

    property var _toggleCb: null
    property var _openCb: null
    property var _closeCb: null
}
```

Note: IPC dispatches to callback hooks set by the NotificationHistory module. This keeps the singleton free of any UI/window references while letting the module own the visible state.

- [ ] **Step 2: Add to `services/qmldir`**

Append:
```
singleton NotificationHistory 1.0 NotificationHistory.qml
```

- [ ] **Step 3: Rewrite `modules/Notifications.qml` to use the singleton**

Replace the inline `NotificationServer { id: server; ... }` and references to `server.trackedNotifications.values` with `NotificationHistory.server.trackedNotifications.values`. Remove the `NotificationServer` block entirely. Add `import qs.services`. Everything else (visibleNotifications, overflow, slide-in, hover-pause, action buttons, middle-click dismiss) stays.

```qml
// quickshell/.config/quickshell/modules/Notifications.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    readonly property int maxVisible: 5

    readonly property var visibleNotifications: {
        const all = NotificationHistory.server.trackedNotifications.values;
        if (all.length <= root.maxVisible) return all;
        return all.slice(0, root.maxVisible);
    }

    readonly property int overflowCount: Math.max(0, NotificationHistory.server.trackedNotifications.values.length - root.maxVisible)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: NotificationHistory.server.trackedNotifications.values.length > 0

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

                        Component.onCompleted: slideInAnim.start()

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
                            acceptedButtons: Qt.MiddleButton
                            onClicked: card.dismissed = true
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

- [ ] **Step 4: Create `modules/NotificationHistory.qml`**

Centered 480×600 panel listing `NotificationHistory.history`. ESC dismisses. Right-click row → `NotificationHistory.removeAt(index)`. Top-right "Clear all" button → `NotificationHistory.clear()`.

```qml
// quickshell/.config/quickshell/modules/NotificationHistory.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components
import qs.services

Scope {
    id: root
    property bool open: false

    Component.onCompleted: {
        NotificationHistory._toggleCb = () => root.open = !root.open;
        NotificationHistory._openCb = () => root.open = true;
        NotificationHistory._closeCb = () => root.open = false;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: root.open
            color: "transparent"

            anchors { top: true; left: true; right: true; bottom: true }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                MouseArea { anchors.fill: parent; onClicked: root.open = false }
            }

            Keys.onEscapePressed: root.open = false
            focus: root.open

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 480
                implicitHeight: 600
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                radius: Theme.radius.large

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: Theme.text
                            font.pixelSize: Theme.font.size.large
                            font.bold: true
                        }

                        StyledRect {
                            id: clearBtn
                            property bool hovered: clearHover.hovered
                            Layout.preferredHeight: 24
                            implicitWidth: clearLabel.implicitWidth + Theme.padding.large * 2
                            color: clearBtn.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1
                            radius: Theme.radius.full
                            visible: NotificationHistory.history.length > 0

                            HoverHandler { id: clearHover }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: NotificationHistory.clear()
                            }

                            StyledText {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Theme.textVariant
                                font.pixelSize: Theme.font.size.small
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: NotificationHistory.history.length === 0

                        StyledText {
                            anchors.centerIn: parent
                            text: "No notifications"
                            color: Theme.textMuted
                            font.pixelSize: Theme.font.size.normal
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: NotificationHistory.history.length > 0
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing.small

                            Repeater {
                                model: NotificationHistory.history

                                StyledRect {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    property bool hovered: rowHover.hovered

                                    Layout.fillWidth: true
                                    implicitHeight: rowCol.implicitHeight + Theme.padding.normal * 2
                                    color: row.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                                    border.color: Theme.outlineVariant
                                    border.width: 1
                                    radius: Theme.radius.normal

                                    HoverHandler { id: rowHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: NotificationHistory.removeAt(row.index)
                                    }

                                    ColumnLayout {
                                        id: rowCol
                                        anchors.fill: parent
                                        anchors.margins: Theme.padding.normal
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.spacing.small

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: row.modelData.summary
                                                color: Theme.text
                                                font.pixelSize: Theme.font.size.normal
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                text: Qt.formatDateTime(new Date(row.modelData.timestamp), "hh:mm")
                                                color: Theme.textDim
                                                font.pixelSize: Theme.font.size.smaller
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: row.modelData.body.length > 0
                                            text: row.modelData.body
                                            color: Theme.textVariant
                                            font.pixelSize: Theme.font.size.small
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            visible: row.modelData.appName.length > 0
                                            text: row.modelData.appName
                                            color: Theme.textDim
                                            font.pixelSize: Theme.font.size.smaller
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

- [ ] **Step 5: Wire into `shell.qml`**

Add `NotificationHistory {}` to the `ShellRoot` children list (alongside other modules):

```qml
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
    NotificationHistory {}
}
```

- [ ] **Step 6: Add MOD+N bind to hyprland.conf**

In `# Section: System`, after the `mediaControls` bind on line 151:

```ini
bind = $mainMod, N, exec, qs ipc call notificationHistory toggle
```

- [ ] **Step 7: Reload + smoke test**

```bash
pgrep -af quickshell >/dev/null && pkill -SIGUSR2 quickshell
hyprctl reload
notify-send 'history-test-1' 'body body body'
notify-send 'history-test-2' 'second one'
# Wait for toasts to expire, then:
qs ipc call notificationHistory open
# Should show panel with 2 entries.
qs ipc call notificationHistory close
```

- [ ] **Step 8: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/services/NotificationHistory.qml \
        quickshell/.config/quickshell/services/qmldir \
        quickshell/.config/quickshell/modules/Notifications.qml \
        quickshell/.config/quickshell/modules/NotificationHistory.qml \
        quickshell/.config/quickshell/shell.qml \
        hypr/.config/hypr/hyprland.conf
git commit -m "feat(quickshell): add notification history panel with in-memory ring buffer"
```

---

## Task 2: DNF Updates Badge

**Files:**
- Create: `quickshell/.config/quickshell/services/Updates.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`
- Modify: `quickshell/.config/quickshell/modules/bar/StatusPill.qml`

**Design notes:**
- `dnf -q check-update` exit codes: 0 = no updates, 100 = updates available, anything else = error. Output (stdout) is the list of upgradable packages, one per line, with a trailing blank line + obsoletes block sometimes. Count = lines that look like `^[a-zA-Z0-9].*  *[0-9]`.
- Poll every 30 min via Timer (`interval: 1800000`).
- Expose `available: int`, `checking: bool`, `lastChecked: Date`. Hide badge when `available <= 0`.
- Click → spawn `kitty -e sudo dnf upgrade` via `Quickshell.execDetached`.
- IpcHandler `updates` with `refresh()` function.

- [ ] **Step 1: Create `services/Updates.qml`**

```qml
// quickshell/.config/quickshell/services/Updates.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int available: 0
    property bool checking: false
    property date lastChecked: new Date(0)

    function refresh() {
        if (proc.running) return;
        root.checking = true;
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", "-c", "dnf -q check-update 2>/dev/null; exit 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                let count = 0;
                for (const line of lines) {
                    if (/^[A-Za-z0-9][^ ]*\.[^ ]+\s+\S+\s+\S+/.test(line)) count++;
                }
                root.available = count;
                root.lastChecked = new Date();
                root.checking = false;
            }
        }
    }

    Timer {
        interval: 1800000     // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "updates"
        function refresh(): void { root.refresh(); }
    }
}
```

Notes on the regex: dnf check-update output rows look like `package.arch  version  repo`. Three whitespace-separated columns with the first one containing a dot (the arch separator). The regex catches that pattern, skips blank lines and the "Obsoleting Packages" header.

- [ ] **Step 2: Add to `services/qmldir`**

Append:
```
singleton Updates 1.0 Updates.qml
```

- [ ] **Step 3: Add updates icon to StatusPill**

Insert before the volume row (so badge appears leftmost):

```qml
// in contentItem: Row { ... } at the start, before the volume Row:

Row {
    anchors.verticalCenter: parent.verticalCenter
    visible: Updates.available > 0
    spacing: 4

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: "system_update"
        color: Theme.warning
        font.pixelSize: 16
        TapHandler {
            onTapped: Quickshell.execDetached(["kitty", "-e", "bash", "-c", "sudo dnf upgrade; read -n 1 -s -r -p 'Press any key to close...'"])
        }
    }
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Updates.available.toString()
        color: Theme.warning
        font.pixelSize: 11
    }
}
```

The "read -n 1" keeps kitty open after dnf finishes so the user can see output. Use `Theme.warning` for visibility (orange-ish).

- [ ] **Step 4: Reload + smoke test**

```bash
pgrep -af quickshell >/dev/null && pkill -SIGUSR2 quickshell
# Force refresh:
qs ipc call updates refresh
# If dnf check-update returns updates, StatusPill should show "system_update N" on the left.
# If 0 updates, the row stays hidden.
```

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/services/Updates.qml \
        quickshell/.config/quickshell/services/qmldir \
        quickshell/.config/quickshell/modules/bar/StatusPill.qml
git commit -m "feat(quickshell): add dnf updates badge to status pill"
```

---

## Task 3: Resources Pill (CPU/RAM/Nvidia/Claude)

**Files:**
- Create: `quickshell/.config/quickshell/services/Resources.qml`
- Create: `quickshell/.config/quickshell/modules/bar/ResourcesPill.qml`
- Modify: `quickshell/.config/quickshell/services/qmldir`
- Modify: `quickshell/.config/quickshell/modules/bar/BottomBar.qml`
- Delete: `quickshell/.config/quickshell/modules/bar/ClaudePill.qml`

**Design notes:**
- Resources.qml polls every 2 seconds:
  - CPU: read `/proc/stat` first line, compute delta against previous sample. `usage% = 100 * (1 - idleDelta / totalDelta)`
  - RAM: read `/proc/meminfo`, compute `100 * (MemTotal - MemAvailable) / MemTotal`
  - GPU (Nvidia): `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits` → parse `"util, mem_used, mem_total"`. If process fails or binary missing, set `nvidiaAvailable = false`.
- Read /proc files via FileView (re-load every tick — quickshell's FileView is sync-fast for small files) OR via separate Process "cat" calls — easier to do via Process with `cat /proc/stat /proc/meminfo` once per tick and parse.
- Actually simpler: one Process running `bash -c "head -1 /proc/stat; echo ---; head -3 /proc/meminfo"` and split on `---`.
- Severity colour ramp helper: `< 70 → Theme.text`, `70-90 → Theme.warning`, `≥ 90 → Theme.error`.

- [ ] **Step 1: Create `services/Resources.qml`**

```qml
// quickshell/.config/quickshell/services/Resources.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPct: 0
    property real ramPct: 0
    property real gpuUtilPct: 0
    property real gpuMemPct: 0
    property bool nvidiaAvailable: false

    property var _prevCpu: null    // {idle, total}

    function severity(pct) {
        if (pct >= 90) return "critical";
        if (pct >= 70) return "warning";
        return "ok";
    }

    function _parseCpuRam(text) {
        const blocks = text.split("---");
        if (blocks.length < 2) return;

        // CPU: "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
        const cpuLine = blocks[0].trim().split(/\s+/);
        if (cpuLine.length >= 5 && cpuLine[0] === "cpu") {
            const nums = cpuLine.slice(1).map(n => parseInt(n, 10) || 0);
            const idle = nums[3] + (nums[4] || 0);
            const total = nums.reduce((a, b) => a + b, 0);
            if (root._prevCpu !== null) {
                const idleDelta = idle - root._prevCpu.idle;
                const totalDelta = total - root._prevCpu.total;
                if (totalDelta > 0) {
                    root.cpuPct = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)));
                }
            }
            root._prevCpu = { idle: idle, total: total };
        }

        // MemInfo
        let memTotal = 0, memAvail = 0;
        for (const line of blocks[1].trim().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/);
            if (!m) continue;
            if (m[1] === "MemTotal") memTotal = parseInt(m[2], 10);
            else if (m[1] === "MemAvailable") memAvail = parseInt(m[2], 10);
        }
        if (memTotal > 0) {
            root.ramPct = Math.max(0, Math.min(100, 100 * (memTotal - memAvail) / memTotal));
        }
    }

    function _parseGpu(text) {
        const line = text.trim().split("\n")[0];
        if (!line) {
            root.nvidiaAvailable = false;
            return;
        }
        const parts = line.split(",").map(s => s.trim());
        if (parts.length < 3) {
            root.nvidiaAvailable = false;
            return;
        }
        const util = parseFloat(parts[0]);
        const memUsed = parseFloat(parts[1]);
        const memTotal = parseFloat(parts[2]);
        if (isNaN(util) || isNaN(memUsed) || isNaN(memTotal) || memTotal <= 0) {
            root.nvidiaAvailable = false;
            return;
        }
        root.gpuUtilPct = Math.max(0, Math.min(100, util));
        root.gpuMemPct = Math.max(0, Math.min(100, 100 * memUsed / memTotal));
        root.nvidiaAvailable = true;
    }

    Process {
        id: cpuRamProc
        command: ["bash", "-c", "head -1 /proc/stat; echo ---; head -3 /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root._parseCpuRam(this.text) }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector { onStreamFinished: root._parseGpu(this.text) }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.nvidiaAvailable = false;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuRamProc.running) cpuRamProc.running = true;
            if (!gpuProc.running) gpuProc.running = true;
        }
    }
}
```

- [ ] **Step 2: Add to `services/qmldir`**

Append:
```
singleton Resources 1.0 Resources.qml
```

- [ ] **Step 3: Create `modules/bar/ResourcesPill.qml`**

```qml
// quickshell/.config/quickshell/modules/bar/ResourcesPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    function rampColor(pct) {
        if (pct >= 90) return Theme.error;
        if (pct >= 70) return Theme.warning;
        return Theme.text;
    }

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 10

        // CPU
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "memory"
                color: root.rampColor(Resources.cpuPct)
                font.pixelSize: 14
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.cpuPct.toFixed(0) + "%"
                color: root.rampColor(Resources.cpuPct)
                font.pixelSize: 11
            }
        }

        // RAM
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "developer_board"
                color: root.rampColor(Resources.ramPct)
                font.pixelSize: 14
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.ramPct.toFixed(0) + "%"
                color: root.rampColor(Resources.ramPct)
                font.pixelSize: 11
            }
        }

        // GPU (Nvidia, optional)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Resources.nvidiaAvailable
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "auto_awesome_motion"
                color: root.rampColor(Math.max(Resources.gpuUtilPct, Resources.gpuMemPct))
                font.pixelSize: 14
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.gpuUtilPct.toFixed(0) + "%"
                color: root.rampColor(Resources.gpuUtilPct)
                font.pixelSize: 11
            }
        }

        // Claude (session / weekly)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: ClaudeUsage.status !== "error"
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "smart_toy"
                color: {
                    if (ClaudeUsage.status === "critical") return Theme.error;
                    if (ClaudeUsage.status === "warning") return Theme.warning;
                    return Theme.text;
                }
                font.pixelSize: 14
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: ClaudeUsage.sessionPct.toFixed(0) + "/" + ClaudeUsage.weeklyPct.toFixed(0) + "%"
                color: {
                    if (ClaudeUsage.status === "critical") return Theme.error;
                    if (ClaudeUsage.status === "warning") return Theme.warning;
                    return Theme.text;
                }
                font.pixelSize: 11
            }
        }
    }
}
```

- [ ] **Step 4: Replace ClaudePill with ResourcesPill in BottomBar.qml**

Change every `claude` identifier reference to `resources` and `ClaudePill` to `ResourcesPill`. Final pillRow block + PeekState + Connections:

```qml
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

    TrayPill {
        id: tray
        anchors.verticalCenter: parent.verticalCenter
        x: status.x - width - 8
    }

    ResourcesPill {
        id: resources
        anchors.verticalCenter: parent.verticalCenter
        x: tray.visible ? (tray.x - width - 8) : (status.x - width - 8)
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
    watchedItems: [launcher, workspaces, media, clock, resources, tray, status]
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
    target: resources
    function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
}
Connections {
    target: tray
    function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
}
Connections {
    target: status
    function onHoveredChanged() { peek.notifyWatchedHoverChanged(); }
}
```

- [ ] **Step 5: Delete ClaudePill.qml**

```bash
cd ~/dotfiles
git rm quickshell/.config/quickshell/modules/bar/ClaudePill.qml
```

- [ ] **Step 6: Reload + smoke test**

```bash
pgrep -af quickshell >/dev/null && pkill -SIGUSR2 quickshell
# Wait 4s, then:
qs log -j 2>/dev/null | tail -20    # check for QML errors
# Visually: hover bottom edge → bar peeks → ResourcesPill shows CPU/RAM/GPU/Claude
# Load test:
stress -c 8 --timeout 5  # or yes >/dev/null &; sleep 5; kill %1
# CPU% climbs above 70 → icon + text turn warning colour.
```

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles
git add quickshell/.config/quickshell/services/Resources.qml \
        quickshell/.config/quickshell/services/qmldir \
        quickshell/.config/quickshell/modules/bar/ResourcesPill.qml \
        quickshell/.config/quickshell/modules/bar/BottomBar.qml
git add -u quickshell/.config/quickshell/modules/bar/ClaudePill.qml
git commit -m "feat(quickshell): consolidate cpu/ram/gpu/claude into resources pill"
```

---

## Final Smoke Validation

After all three commits land:

1. **QML log clean:** `qs log -j 2>/dev/null | tail -50` shows no errors.
2. **Bar still peeks:** hover bottom edge → all pills slide in (launcher, workspaces, media, clock, resources, tray, status).
3. **NotificationHistory:** `notify-send foo bar` × 3, wait for toasts to expire, `qs ipc call notificationHistory toggle` → panel shows 3 entries → right-click one row → removed → "Clear all" → empty.
4. **Updates badge:** if `dnf check-update` finds updates, badge visible in StatusPill. Click → kitty opens with `dnf upgrade`.
5. **Resources pill:** running normally shows ~5-30% CPU. `stress -c 8 --timeout 10` → CPU% climbs to ~100% and goes Theme.error red. Nvidia visible if nvidia-smi works.

If any smoke fails, open a follow-up commit. Don't squash retroactively.

---

## Out-of-scope

- Tooltip popup on hover for ResourcesPill — spec mentions it but defer until visual feedback proves it useful.
- Persisting notification history to disk — in-memory only per spec.
- Auto-refreshing dnf inventory more aggressively than 30 min — manual `qs ipc call updates refresh` available.

