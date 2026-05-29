# Phase 2: Control Center + Right Sidebar

## Overview

Add a right sidebar panel to quickshell with Android-style quick toggles, sliders, calendar, todo, pomodoro, notification history, volume mixer, WiFi/Bluetooth management, and night light control.

Reference: `~/repo/dots-hyprland/dots/.config/quickshell/ii/modules/ii/sidebarRight/`

## Architecture

Follow end-4's layered pattern:

```
IPC/keybind → SidebarRight.qml (PanelWindow, WlrLayer)
                └── SidebarRightContent.qml (ColumnLayout)
                    ├── QuickSliders (brightness, volume)
                    ├── QuickToggles (Android-style grid)
                    ├── CalendarWidget
                    ├── TodoWidget / PomodoroWidget (tabs)
                    └── NotificationHistory (existing, moved)
```

Toggle → ToggleModel → service mutation → property binding → UI re-render.
Dialog overlays: property-driven Loaders that activate on toggle expand.

## New Services

### Brightness.qml (singleton)

```
property real brightness: 0-1 (brightnessctl current / max)
property real max: brightnessctl max
function setBrightness(value): brightnessctl set ${value * 100}%
function increment(): brightnessctl set 10%+
function decrement(): brightnessctl set 10%-
Poll: 5s via brightnessctl -m (machine-readable)
```

### Hyprsunset.qml (singleton)

```
property bool active: false (process running)
property int temperature: 4000 (default kelvin)
function toggle(): pkill hyprsunset || hyprsunset -t $temperature
function setTemperature(k): kill + restart with new value
function fetchState(): pgrep hyprsunset
Poll: check process existence on 5s timer
```

### Idle.qml (singleton)

```
property bool inhibited: false (hypridle NOT running)
function toggle(): inhibited ? start hypridle : pkill hypridle
function fetchState(): pgrep hypridle → inhibited = (exit != 0)
Poll: 5s
```

### NotificationSilencing.qml (singleton)

For mako-based DND (if mako is running) or swaync DND, or generic flag-file:

```
property bool silenced: false
function toggle(): toggle state file ~/.local/state/toggles/notification-silencing
function fetchState(): check state file
```

Note: Our notifications are handled by quickshell's own NotificationHistory service (D-Bus server). DND mode = stop showing toasts. Implement as property on existing Notifications module:
- `property bool doNotDisturb: false`
- When true, new notifications go to history but no toast popup

### Enhanced services (modify existing)

**Audio.qml additions:**
```
property var outputDevices: [] (list from wpctl status)
property var inputDevices: []
property int micVolume: 0-100
property bool micMuted: false
function toggleMicMute()
function setMicVolume(pct)
function cycleSink(): switch default output
```

**Bluetooth.qml additions:**
```
property var devices: [] (bluetoothctl devices)
property bool scanning: false
function startScan(): bluetoothctl scan on
function stopScan(): bluetoothctl scan off
function connect(mac)
function disconnect(mac)
function pair(mac)
function forget(mac)
```

**Network.qml additions:**
```
property var wifiNetworks: [] (nmcli -t -f ... dev wifi list)
property bool scanning: false
function scan(): nmcli dev wifi rescan
function connect(ssid, password?)
function disconnect()
function toggleWifi(): nmcli radio wifi on/off
```

## New Modules

### SidebarRight.qml

PanelWindow anchored top/right/bottom. WlrLayershell.Top, exclusionMode Ignore, keyboardFocus OnDemand.

IPC target: `sidebar` (toggle/open/close)
Keybind: Super+A (matches common quick settings key)

Width: 380px. Opens/closes with slide animation from right edge.
Scrim overlay on rest of screen (semi-transparent black, click to close).
Escape to close.

### SidebarRightContent.qml

ColumnLayout with 8px padding, 8px spacing:

1. **Header row**: Clock + date (left), reload button, session button (right)
2. **QuickSliders**: Brightness + Volume sliders
3. **QuickToggles**: Android-style grid (3 columns)
4. **CalendarWidget**: Month view with navigation
5. **WidgetTabs**: SwipeView with Todo and Pomodoro tabs
6. **NotificationHistory**: Last 50 notifications (reuse existing service)

Scrollable via Flickable wrapping the ColumnLayout.

### QuickSliders.qml

Two sliders in a StyledRect:
- Brightness: MaterialIcon "brightness_6" + StyledSlider (0-1, maps to brightnessctl)
- Volume: MaterialIcon "volume_up" + StyledSlider (0-1.5, maps to wpctl)

Click icon to: brightness = no-op, volume = toggle mute.

### QuickToggles.qml (Android-style)

3-column grid of toggle tiles. Each tile: icon + name + optional status text.
Size 1 = icon only. Size 2 = icon + name + status.

Toggles (matching open issues):
| Toggle | Service | Icon | Issue |
|--------|---------|------|-------|
| WiFi | Network | wifi/wifi_off | — |
| Bluetooth | Bluetooth | bluetooth/bluetooth_disabled | — |
| Night Light | Hyprsunset | bedtime | #11 |
| Idle Inhibitor | Idle | coffee/coffee_maker | #12 |
| DND | Notifications | do_not_disturb_on/off | #13 |
| Mic Mute | Audio | mic/mic_off | #15 |

Each toggle = QuickToggleModel with:
- name, icon, statusText, toggled (bool), available (bool)
- mainAction (toggle), altAction (open dialog if has one)

WiFi and Bluetooth have expandable dialogs. Night light has temperature dialog.

### Toggle tile component

Following end-4's AndroidQuickToggleButton pattern:
- StyledRect with border radius
- Toggled state: primary color background
- Untoggled: surface color
- Icon left, name + status right (when expanded)
- Click = mainAction (toggle)
- Long press or alt-click = altAction (dialog)

### CalendarWidget.qml

Month grid (7 columns, 6 rows). Week starts Monday.
- Header: month/year text + left/right nav buttons
- Day header row: Mon-Sun
- Day cells: highlight today, dim other-month days
- Click day = no-op (or future: show events)
- Scroll/PageUp/PageDown to navigate months

Use JS helper for layout calculation (same algorithm as end-4's calendar_layout.js).

### TodoWidget.qml

Two tabs: Unfinished / Done (SwipeView).
- Each task: text + check button + delete button
- FAB "+" button to add new task
- Add dialog: text input + Add button
- Storage: JSON file at ~/.local/state/quickshell/todo.json
- Service: Todo.qml singleton (list, addTask, markDone, deleteItem)

### PomodoroWidget.qml

Three modes: Pomodoro (25min) / Short Break (5min) / Long Break (15min)
- Circular progress display
- Start/Pause/Reset buttons
- Count of completed pomodoros
- Notification on completion
- Storage: state persists in memory only (resets on QS restart)

### Dialogs

**WiFiDialog**: ListView of networks from Network.wifiNetworks. Click to connect. Password prompt for secured networks. Scanning indicator.

**BluetoothDialog**: ListView of devices from Bluetooth.devices. Click to connect/disconnect. Pair/forget buttons. Scanning indicator.

**NightLightDialog**: Temperature slider (1200K-6500K). Enable/disable toggle.

**VolumeDialog**: Per-app volume sliders (from Audio.outputDevices / pipewire node list). Device selector dropdown. Needs pipewire integration — defer to follow-up if Quickshell.Pipewire is not available.

## Keybinding

```
bind = $mainMod, A, exec, qs ipc call sidebar toggle
```

Note: Super+A is free in current hyprland.conf.

## Implementation Order

Split into incremental PRs:

### PR 1: Sidebar shell + quick toggles
- SidebarRight.qml, SidebarRightContent.qml (skeleton)
- QuickToggles.qml with 6 toggles
- New services: Brightness, Hyprsunset, Idle
- Enhanced: Audio (mic), Notifications (DND)
- Keybind Super+A
- Closes: #11, #12, #13, #15

### PR 2: Quick sliders + calendar
- QuickSliders.qml (brightness, volume)
- CalendarWidget.qml + calendar JS helper

### PR 3: Todo + Pomodoro
- Todo.qml service
- TodoWidget.qml
- PomodoroWidget.qml
- Timer.qml service

### PR 4: Dialogs
- WiFiDialog, BluetoothDialog, NightLightDialog
- Enhanced: Network (wifi scan/connect), Bluetooth (device management)
- VolumeDialog (if pipewire integration available)

### PR 5: Notification history integration
- Move/link existing NotificationHistory into sidebar
- Add notification count badge on sidebar trigger

## File Structure

```
quickshell/.config/quickshell/
├── modules/
│   ├── SidebarRight.qml
│   ├── sidebar/
│   │   ├── SidebarRightContent.qml
│   │   ├── QuickSliders.qml
│   │   ├── QuickToggles.qml
│   │   ├── QuickToggleModel.qml
│   │   ├── QuickToggleTile.qml
│   │   ├── toggles/
│   │   │   ├── WiFiToggle.qml
│   │   │   ├── BluetoothToggle.qml
│   │   │   ├── NightLightToggle.qml
│   │   │   ├── IdleToggle.qml
│   │   │   ├── DndToggle.qml
│   │   │   └── MicMuteToggle.qml
│   │   ├── CalendarWidget.qml
│   │   ├── calendar_layout.js
│   │   ├── TodoWidget.qml
│   │   ├── TaskList.qml
│   │   ├── PomodoroWidget.qml
│   │   └── dialogs/
│   │       ├── WiFiDialog.qml
│   │       ├── BluetoothDialog.qml
│   │       ├── NightLightDialog.qml
│   │       └── VolumeDialog.qml
├── services/
│   ├── Brightness.qml (new)
│   ├── Hyprsunset.qml (new)
│   ├── Idle.qml (new)
│   ├── Todo.qml (new)
│   ├── Timer.qml (new)
│   ├── Audio.qml (enhanced)
│   ├── Bluetooth.qml (enhanced)
│   └── Network.qml (enhanced)
```

## Dotmachines Changes

Add to hyprland_packages:
- hyprsunset (for night light, if not already present)

## Issues Closed

PR 1 closes: #10 (toggle system via services), #11, #12, #13, #15
PR 4 closes: #14 (audio switch via volume dialog device selector)
