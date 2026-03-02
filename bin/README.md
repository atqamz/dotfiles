# bin

Custom scripts installed to `~/.local/bin/scripts/`. The parent directory
`~/.local/bin/` is left for installer-managed binaries (claude, uv, etc.) so
they don't land inside the dotfiles repo via stow's tree folding.

Includes clipboard history, screenshot, emoji picker, password menu, Hyprland
workspace helpers, and Waybar status scripts.

## Dependencies

- cliphist
- wl-clipboard (`wl-paste`, `wl-copy`)
- wtype
- grim
- slurp
- rofi-wayland
- rofimoji
- pass
- notify-send (libnotify)
- python3
- nvidia-smi (optional, for GPU status)
