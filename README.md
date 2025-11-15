# Dotfiles

Personal dotfiles for Atqa Munzir. Everything is laid out as Stow modules so the
tracked files can be symlinked straight into the home directory.

## Layout

- `shell/` – Bash environment (`.bashrc`, `.bash_profile`, `.inputrc`, etc.) plus
  `~/.config/environment.d/90-portals.conf`, which exports the portal-related
  environment variables for every user session.
- `git/` – Git configuration (`.gitconfig`).
- `bin/` – Helper scripts exposed via `~/.local/bin`. Notable utilities:
  - `passmenu`: themes `rofi -dmenu` with the same look Sway uses and reads from
    `pass`. The prompt, font, theme string, and extra rofi options can be
    overridden via `PASSMENU_PROMPT`, `PASSMENU_ROFI_FONT`,
    `PASSMENU_ROFI_THEME_STR`, and `PASSMENU_ROFI_ARGS`.
  - `sshadd`: loads `~/.ssh/id_ed25519` and `~/.ssh/id_rsa` non-interactively;
    it expects `ksshaskpass` (or any `SSH_ASKPASS`) to satisfy passphrase
    prompts.
  - `screenshot`: saves Wayland screenshots to `~/Pictures/Screenshots`
    (`grim`, `slurp`, `wl-copy`, `notify-send` optional). Pass `--copy` to send
    the capture straight to the clipboard. Used by the Sway bindings described
    below for area-to-clipboard (`$mod+Shift+s`) and full-screen-to-file (`F12`)
    captures.
  - `cliphistory`: clipboard history picker powered by `cliphist`, `wl-copy`,
    and the same rofi theme as the launcher. Invoked via `Mod+Ctrl+v` in Sway,
    restores whatever entry you select back onto the clipboard, and auto-types
    it via `wtype` when available.
  - `emoji-picker`: wraps `rofimoji` with the shared rofi theme, copies the
    selection, and immediately injects it into the focused window via `wtype`.
    Bound to `Mod+.`.
  - `yazi-filechooser`: wrapper used by `xdg-desktop-portal-termfilechooser` to
    launch Yazi in chooser mode (supports save dialogs, multi-select, etc.).
  - `waybar_cpustatus`: Python helper emitting Waybar-friendly JSON that shows
    CPU usage plus package temperature (reads `/proc/stat` and
    `/sys/class/hwmon/.../temp*_input`).
  - `waybar_gpustatus`: Python helper that shells out to `nvidia-smi` for GPU
    utilization + temperature. Without the proprietary NVIDIA CLI installed the
    module falls back to `--% --°C`.
- `sway/` – Wayland compositor configuration. It keeps every `rofi` invocation
  consistent, binds `Mod+Alt+p` to launch `passmenu`, themes window borders, and
  autostarts helpers like Waybar, clipboard history, and libinput-gestures. The
  default wallpaper/session background is set to pure black to keep the setup
  minimal.
- `waybar/` – Status bar configuration and CSS paired with the Sway colors.
  Clock output uses the `dd/MM/yyyy` format. Modules cover workspaces, audio,
  network, battery/tray, plus combined CPU + GPU status blocks powered by the
  helpers above.
- `xdg/` – Portal configuration. It forces `xdg-desktop-portal` to prefer the
  wlroots backend for everything and termfilechooser + Yazi for file dialogs.

## Bootstrapping

1. Install `stow` (`sudo dnf install stow` or equivalent) plus any helper
   dependencies you need (`pass`, `rofi-wayland`, `ksshaskpass`, etc.).
2. Clone this repo into `~/dotfiles`.
3. From inside the repo, stow whichever modules you want, e.g.
   ```sh
   stow shell git bin sway waybar xdg
   ```
   Re-run `stow` whenever you add new modules or update configs.

## Notes

- `bin/.local/bin/sshadd` expects KDE's `ksshaskpass` (or another askpass
  program) to be available so it can add keys without a TTY.
- Clipboard workflow relies on `cliphist`, `wl-clipboard`, `rofi` (Wayland
  build), plus `rofimoji` and `wtype` for the emoji picker.
- Waybar + the themed autostart expect `waybar`, `pavucontrol` (optional),
  `wpctl` (PipeWire), `playerctl`, `libinput-gestures`, and the Waybar helper
  dependencies noted in `DEPENDENCIES.md` (e.g. `python3`, `nvidia-smi`) to be
  installed.
- Need instructions for switching from Nouveau to the proprietary NVIDIA stack
  (so `nvidia-smi` exists)? See `docs/NVIDIA.md`.
- File dialogs rely on `xdg-desktop-portal-termfilechooser` plus `yazi`; check
  `xdg/.config/xdg-desktop-portal*`, `bin/yazi-filechooser`, or the step-by-step
  guide in `docs/YAZI-FILE-DIALOG.md` if you want to tweak or recreate it from scratch.
