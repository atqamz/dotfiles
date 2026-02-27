# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Modules

- **bashrc**: Shell configuration and aliases
- **bin**: Helper scripts (`~/.local/bin`)
- **claude**: Claude Code settings and status line script
- **gitconfig**: Git global configuration
- **hypr**: Hyprland window manager settings
- **inputrc**: Readline input configuration
- **kitty**: Terminal emulator config
- **rofi**: Application launcher and menus
- **swaync**: Notification center
- **tmux**: Terminal multiplexer
- **waybar**: Status bar configuration
- **wlogout**: Logout menu

## Scripts

Key utilities found in `bin/`:
- **cliphistory**: Clipboard history manager
- **hypr-***: various Hyprland helpers (workspaces, tagging)
- **passmenu**: Rofi interface for pass
- **screenshot**: Wayland screenshot tool
- **sshadd**: SSH agent helper

## Setup

1. **Bootstrap**
   Install system dependencies (Fedora):
   ```sh
   ./fedora-fresh.sh
   ```

2. **Install**
   Stow all modules:
   ```sh
   make
   ```

3. **Uninstall**
   Remove symlinks:
   ```sh
   make delete
   ```
