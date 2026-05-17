# quickshell

Minimal black-themed [Quickshell](https://quickshell.outfoxxed.me) config.
Replaces waybar + swaync + wlogout + rofi launcher with a single QML shell.

## Scope (current)

- **Bar** (`modules/Bar.qml`) — top panel, black bg, JetBrains Mono. Shows
  Hyprland workspace indicators (left), then network/audio/battery/clock
  widgets (right). Audio polls `wpctl get-volume @DEFAULT_AUDIO_SINK@`
  every 2s; battery polls `/sys/class/power_supply/BAT{0,1}/{capacity,status}`
  every 30s; network polls `nmcli -t -f STATE general` every 2s.
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
- **Clipboard history** (`modules/Clipboard.qml`) — overlay listing
  `cliphist list` entries. Filter, Enter to `cliphist decode | wl-copy`
  back to the clipboard. IPC target `clipboard`. Replaces the legacy
  rofi-based `cliphistory` script.
- **Window picker** (`modules/WindowPicker.qml`) — overlay listing Hyprland
  toplevels via `hyprctl clients -j`. Filter by class or title, Enter to
  `hyprctl dispatch focuswindow`. IPC target `windows`. Replaces the
  legacy rofi-based `hypr-window-picker` script.
- **OSD** (`modules/Osd.qml`) — bottom-centre overlay that shows volume or
  brightness for 1.5s after a key press. Hyprland XF86Audio*/XF86MonBrightness*
  bindings chain `wpctl`/`brightnessctl` with `qs ipc call osd volume|brightness`
  so the OSD reads back the post-change value and auto-hides.
- **TagInput** (`modules/TagInput.qml`) — single-line text input dialog.
  Enter dispatches `hyprctl dispatch tagwindow <text>`. Prefix `-` to remove
  a tag. IPC target `tag`. Replaces the legacy rofi-based `hypr-tag-window`
  script.
- **PassMenu** (`modules/PassMenu.qml`) — overlay listing `*.gpg` entries
  under `$PASSWORD_STORE_DIR` (default `~/.password-store`). Enter runs
  `pass show -c` to copy the password to the clipboard. IPC target `pass`.
  Replaces the legacy rofi-based `passmenu` script.
- **EmojiPicker** (`modules/EmojiPicker.qml`) — overlay with a curated set
  of ~200 common emojis (hardcoded in the module since rofimoji is gone).
  Enter runs `wl-copy` to put the glyph on the clipboard. IPC target
  `emoji`. Replaces the legacy rofi/rofimoji-based `emojipicker` script.

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
| Bar | enriched | Has: workspaces, network, audio, battery, clock. Add: tray, brightness, mpris title |
| Notifications | minimal | Add: dismiss-all, history panel, do-not-disturb toggle |
| Launcher | minimal | App launcher only. Add: run mode, calculator, emoji, clipboard |
| Power menu | minimal | Lock/Logout/Suspend/Reboot/Shutdown buttons |
| Control center | TODO | Audio sinks, network, brightness, idle inhibit |
| Lock | use `hyprlock` | hyprlock owns the lock screen; quickshell stays out |
| OSD | minimal | Has: volume + brightness. Add: mic mute, capslock |
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
