# quickshell

Minimal black-themed [Quickshell](https://quickshell.outfoxxed.me) config.
Replaces waybar + swaync + wlogout + rofi launcher with a single QML shell.

## Scope (current)

- **Bar** (`modules/Bar.qml`) — top panel, black bg, JetBrains Mono. Shows
  Hyprland workspace indicators + clock.
- **Notifications** (`modules/Notifications.qml`) — D-Bus
  `org.freedesktop.Notifications` server, top-right toast stack, auto-dismiss
  on expire timeout or click.
- **Launcher** (`modules/Launcher.qml`) — full-screen overlay app launcher.
  Fuzzy substring search over `DesktopEntries.applications`, keyboard
  navigation (Up/Down + Enter), Escape or backdrop click to close. IPC
  target `launcher` (`qs ipc call launcher toggle|open|close`).
- **Power menu** (`modules/Power.qml`) — overlay session menu with Lock,
  Logout, Suspend, Reboot, Shutdown actions. IPC target `session`
  (`qs ipc call session toggle|open|close`).

## Inspiration

Heavily inspired by
[caelestia-dots/shell](https://github.com/caelestia-dots/shell) (pinned to
upstream commit `cf18cea3dad28ddda2f151b1b42a66f2fba1f84a` at time of fork).

Caelestia itself is **not vendored**: it requires a compiled Qt6 C++ plugin
(`Caelestia.Config`, `Caelestia.Toaster`, etc.) that is not packaged on
Fedora. The roadmap below ports caelestia patterns into pure QML over time.

## Roadmap

| Module | Status | Notes |
|---|---|---|
| Bar | minimal | Add: tray, audio slider, network indicator, battery, brightness |
| Notifications | minimal | Add: dismiss-all, history panel, do-not-disturb toggle |
| Launcher | minimal | App launcher only. Add: run mode, calculator, emoji, clipboard |
| Power menu | minimal | Lock/Logout/Suspend/Reboot/Shutdown buttons |
| Control center | TODO | Audio sinks, network, brightness, idle inhibit |
| Lock | use `hyprlock` | hyprlock owns the lock screen; quickshell stays out |
| OSD | TODO | Volume / brightness overlay on hotkey |
| Wallpaper engine | dropped | Single solid black background |

## Theme

Hardcoded:

- Background: `#000000`
- Surface: `#1a1a1a`
- Border: `#3a3a3a`
- Text primary: `#ffffff`
- Text secondary: `#cccccc`
- Text muted: `#888888`
- Font: JetBrains Mono

No dynamic colour-from-wallpaper. No light mode.

## Running

Started by Hyprland via `exec-once = qs` in
`~/.config/hypr/hyprland.conf`. Default profile reads `shell.qml` from
this directory.

Manual: `qs` (foreground) or `qs &` (background).

## Deps (installed via dotmachines `hyprland_packages`)

- `quickshell` (errornointernet/quickshell COPR)
- `qt6-qtdeclarative`, `qt6-qt5compat`, `qt6-qtsvg`, `qt6-qtwayland`,
  `qt6-qtimageformats`
- `material-symbols-fonts`
- `jetbrains-mono-fonts` (already in base_packages.fonts)
