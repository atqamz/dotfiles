# atqa's dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Modules

| Module | Description |
|--------|-------------|
| `bash` | Shell configuration and aliases |
| `claude` | Claude Code settings and status line |
| `git` | Git global configuration |
| `gnupg` | GnuPG agent configuration (symlinked manually, not stowed) |
| `hypr` | Hyprland window manager, lock, and idle |
| `opencode` | OpenCode AI assistant config |
| `quickshell` | Quickshell desktop shell (bar, launcher, sidebar, overview) |
| `readline` | Readline input configuration |
| `scripts` | Helper scripts (`~/.local/bin/scripts`) |
| `swappy` | Screenshot editor configuration |
| `tmux` | Terminal multiplexer |
| `uwsm` | uwsm session environment (effective under uwsm-launched Hyprland) |
| `zed` | Zed editor settings and keymap |

Each module has its own `README.md` with setup notes and dependencies.

## Setup

System provisioning (packages, repos, services) is handled by the
[dotmachines](https://github.com/atqamz/dotmachines) Ansible playbooks, which
also stow these dotfiles via its `dotfiles` role.

To stow manually:

```sh
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

### Password store

```sh
ln -s ~/password-store ~/.password-store
```

### SSH agent

SSH is served by gpg-agent (`enable-ssh-support` in `gnupg/.gnupg/gpg-agent.conf`),
not a standalone `ssh-agent`. The personal SSH identity is the GPG `[A]` auth
subkey — append its keygrip to `~/.gnupg/sshcontrol` once per machine (see
`gnupg/README.md`). `SSH_AUTH_SOCK` is exported by `bash/.bashrc` (and the `uwsm`
env module under uwsm sessions).

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
