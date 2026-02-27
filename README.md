# atqa's dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Modules

| Module | Description |
|--------|-------------|
| `bashrc` | Shell configuration and aliases |
| `bin` | Helper scripts (`~/.local/bin`) |
| `claude` | Claude Code settings and status line |
| `gitconfig` | Git global configuration |
| `hypr` | Hyprland window manager, lock, and idle |
| `inputrc` | Readline input configuration |
| `kitty` | Terminal emulator config |
| `rofi` | Application launcher theme |
| `swaync` | Notification center |
| `tmux` | Terminal multiplexer |
| `waybar` | Status bar |
| `wlogout` | Logout menu |

Each module has its own `README.md` with setup notes and dependencies.

## Setup

```sh
# bootstrap system packages (Fedora)
./fedora-fresh.sh

# stow all modules
make

# remove symlinks
make delete
```

## Post-install

### SSH and GPG permissions

```sh
chown -R $USER:$USER ~/.ssh ~/.gnupg
chmod 700 ~/.ssh ~/.gnupg
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts ~/.ssh/config
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;
restorecon -Rv ~/.ssh ~/.gnupg
```

### GPG pinentry

Add to `~/.gnupg/gpg-agent.conf`:

```
pinentry-program /usr/bin/pinentry-rofi
```

### Password store

```sh
ln -s ~/password-store ~/.password-store
```

### SSH agent

```sh
systemctl --user enable --now ssh-agent.service
```

### Fonts

```sh
mkdir -p ~/.local/share/fonts
# place font files there
fc-cache -fv
```

### Firefox tweaks

Open `about:config` and set:

- `middlemouse.paste` = `false`
- `dom.events.testing.asyncClipboard` = `true`
