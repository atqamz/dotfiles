# Dependencies

This repo is mostly configuration and small helper scripts. The table below lists
what needs to be installed for every module/script referenced in the configs.
Package names follow the generic Arch/Fedora/Debian naming where possible—adjust
for your distro.

## Waybar modules

| Module | File | External requirements | Notes |
| --- | --- | --- | --- |
| `clock`, `network`, `memory`, `battery`, `tray`, `pulseaudio` | `waybar/.config/waybar/config.jsonc` | Waybar itself (`waybar` package) and its runtime deps; `pulseaudio` module's on-click command needs `pavucontrol`. | No extra scripts required. |
| `custom/cpu_status` | `waybar/.config/waybar/config.jsonc`, script `bin/.local/bin/waybar_cpustatus` | `python3`; permission to read `/proc/stat` and `/sys/class/hwmon/hwmon5/temp1_input` (usually part of `video` group). | Script calculates CPU usage/temperature and emits JSON for Waybar. |
| `custom/gpu_status` | `waybar/.config/waybar/config.jsonc`, script `bin/.local/bin/waybar_gpustatus` | `python3`; NVIDIA proprietary utilities providing the `nvidia-smi` CLI. | Script shells out to `nvidia-smi --query-gpu=temperature.gpu,utilization.gpu`. Without `nvidia-smi` the module shows `--% --°C`. |

## Sway session helpers

| Feature | File | Required tools | Notes |
| --- | --- | --- | --- |
| Terminal + launcher | `sway/.config/sway/config.d/10-variables.conf` | `kitty`, `rofi-wayland` (for `$menu`), Nerd Font such as `Iosevka Nerd Font` for icons. | `$menu` builds a themed rofi invocation, so rofi must include dmenu/Wayland support. |
| Autostarted clipboard + gestures | `sway/.config/sway/config.d/60-autostart.conf` | `libinput-gestures`, `cliphist`, `wl-clipboard` (`wl-paste`, `wl-copy`). | `libinput-gestures` handles touchpad gestures, and the two `wl-paste ... cliphist store` commands feed the clipboard history. |
| SSH key helper | `bin/.local/bin/sshadd`, referenced from `60-autostart.conf` | `ssh-agent`/`ssh-add` from OpenSSH. | Adds `~/.ssh/id_ed25519`/`id_rsa` if they exist. |
| Clipboard picker (`$mod+Ctrl+v`) | `bin/.local/bin/cliphistory` | `cliphist`, `wl-copy`, `rofi (Wayland build)` | Provides a rofi interface to the cliphist history. |
| Emoji picker (`$mod+.`) | `bin/.local/bin/emojipicker` | `rofimoji`, `rofi`, `wl-paste`, `wtype` | Launches rofimoji inside a rofi dmenu for inserting emoji. |
| Pass menu (`$mod+Mod1+p`) | `bin/.local/bin/passmenu` | `pass`, `rofi`, working `gpg` setup | Wraps `pass` entries in a themed rofi selector. |
| Screenshot commands (`$mod+Shift+s`, `F12`) | `bin/.local/bin/screenshot` | `grim`, `slurp` (for area selection), `wl-clipboard` (`wl-copy`), `notify-send` (optional). | Captures area/fullscreen shots, optionally copies to clipboard, and can send a desktop notification. |
| Clipboard history daemon | `sway/.config/sway/config.d/60-autostart.conf`, `bin/.local/bin/cliphistory` | Same as clipboard picker above | The watcher commands keep history populated. |
| Exit prompt (`$mod+Shift+e`) | `sway/.config/sway/config.d/50-keybindings.conf` | `swaynag` (ships with sway). | No extra setup beyond sway itself. |
| Audio settings (`Waybar pulseaudio on-click`, possibly manual) | `waybar/.config/waybar/config.jsonc` | `pavucontrol`. | Launches PulseAudio volume control GUI when clicked. |

## Other helper scripts

| Script | File | External requirements | Notes |
| --- | --- | --- | --- |
| `cliphistory` | `bin/.local/bin/cliphistory` | See entry above (rofi, cliphist, wl-copy). | Uses env vars `CLIPHIST_*` for customization. |
| `emojipicker` | `bin/.local/bin/emojipicker` | See entry above. | Wraps `rofimoji` with rofi and simulates typing via `wtype`. |
| `passmenu` | `bin/.local/bin/passmenu` | See entry above. | Requires `.password-store` populated. |
| `screenshot` | `bin/.local/bin/screenshot` | `grim`, `slurp`, `wl-copy`, `notify-send` (optional). | Saves captures under `$HOME/Pictures/Screenshots` by default. |
| `sshadd` | `bin/.local/bin/sshadd` | OpenSSH client (`ssh-add`). | Non-interactive add so sway askpass can prompt. |
| `waybar_cpustatus` | `bin/.local/bin/waybar_cpustatus` | `python3`, readable CPU hwmon node. | Used exclusively by Waybar. |
| `waybar_gpustatus` | `bin/.local/bin/waybar_gpustatus` | `python3`, `nvidia-smi`. | Used exclusively by Waybar. |

> Tip: use your distro’s package manager to install the required CLIs (e.g.
> `sudo pacman -S cliphist wl-clipboard rofi grim slurp python3 nvidia-utils` on
> Arch). Some modules simply won’t render useful data until their dependency is
> present (e.g. `waybar_gpustatus` without `nvidia-smi`).
