# quickshell

Dark-themed [Quickshell](https://quickshell.outfoxxed.me) desktop shell for
Hyprland. A single QML shell replacing waybar, swaync, wlogout, and the rofi
launcher stack.

## Layout

- `shell.qml` — root, loads every module.
- `components/` — singletons (`Theme`, `Config`) and styled primitives
  (`StyledRect`, `StyledText`, `MaterialIcon`, `Anim`/`CAnim`, …) plus the
  `Fuzzy.js` matcher shared by every search surface.
- `services/` — singleton backends (Audio, Battery, Network, Bluetooth,
  Resources, Mpris, Tray, Updates, Time, …).
- `modules/` — UI panels; `modules/bar/` the top bar, `modules/sidebar/`,
  `modules/overview/`, `modules/settings/`, `modules/dock/` their sub-trees.

## Modules

- **Bar** (`modules/bar/TopBar.qml`) — bottom auto-hide bar of grouped
  "islands": launcher, numbered workspaces and focused-window title (left),
  clock (centre), resources, media, tray and status (right).
- **Dock** (`modules/Dock.qml`), **Overview** (`modules/Overview.qml`),
  **right Sidebar** (`modules/SidebarRight.qml`), **Settings GUI**
  (`modules/Settings.qml`, backed by the `Config` store).
- **Notifications** (`modules/NotificationHistory.qml`) — `org.freedesktop`
  D-Bus server, toast stack, history panel.
- **OSD** (`modules/Osd.qml`) — volume/brightness overlay after a key press.
- Search overlays, all keyboard-driven and fuzzy-matched via `Fuzzy.js`:
  **Launcher** (`launcher`), **Clipboard** (`clipboard`, `cliphist`),
  **Window picker** (`windows`, `hyprctl clients`), **PassMenu** (`pass`,
  `pass show -c`), **EmojiPicker** (`emoji`). IPC: `qs ipc call <target> toggle`.
- **TagInput** (`tag`), **Power menu** (`session`), **Cheatsheet**.

## Theme

Driven by the `Theme` singleton (`components/Theme.qml`): Material Design 3
inspired dark palette anchored to pure black, exposed as semantic roles
(`surface*`, `text*`, `primary`, `outline*`). UI font is configurable
(`Config.options.appearance.fontFamily`, default Rubik); mono is JetBrains
Mono; icons use the **Material Icons Round** ligature set (deliberately not
Material Symbols, whose ligature names differ).

## Running

Started by Hyprland via `exec-once = qs` in `~/.config/hypr/hyprland.conf`.
Manual: `qs` (foreground), `qs &` (background), `qs log -f` (tail logs).

## Dependencies

Installed via the dotmachines `hyprland` role; listed here for reference.

- `quickshell` (errornointernet/quickshell COPR)
- `qt6-qtdeclarative`, `qt6-qt5compat`, `qt6-qtsvg`, `qt6-qtwayland`,
  `qt6-qtimageformats`
- Fonts: `google-rubik-fonts` (UI), `jetbrains-mono-fonts` (mono), and a
  **Material Icons Round** font providing the icon ligatures
- `cliphist`, `wl-clipboard` — clipboard history overlay
- `pass` — PassMenu
- `hyprland` (`hyprctl`) — workspaces, window picker, tag input
- `brightnessctl`, `wireplumber` (`wpctl`) — OSD volume/brightness
