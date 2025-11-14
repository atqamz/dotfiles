# Dotfiles

Personal dotfiles for Atqa Munzir. Everything is laid out as Stow modules so the
tracked files can be symlinked straight into the home directory.

## Layout

- `shell/` – Bash environment (`.bashrc`, `.bash_profile`, `.inputrc`, etc.).
- `git/` – Git configuration (`.gitconfig`).
- `bin/` – Helper scripts exposed via `~/.local/bin`. Notable utilities:
  - `passmenu`: themes `rofi -dmenu` with the same look Sway uses and reads from
    `pass`. The prompt, font, theme string, and extra rofi options can be
    overridden via `PASSMENU_PROMPT`, `PASSMENU_ROFI_FONT`,
    `PASSMENU_ROFI_THEME_STR`, and `PASSMENU_ROFI_ARGS`.
  - `sshadd`: loads `~/.ssh/id_ed25519` and `~/.ssh/id_rsa` non-interactively;
    it expects `ksshaskpass` (or any `SSH_ASKPASS`) to satisfy passphrase
    prompts.
- `sway/` – Wayland compositor configuration. It keeps every `rofi` invocation
  consistent, binds `Mod+Alt+p` to launch `passmenu`, and autostarts `sshadd`
  once the session is up.

## Bootstrapping

1. Install `stow` (`sudo dnf install stow` or equivalent) plus any helper
   dependencies you need (`pass`, `rofi-wayland`, `ksshaskpass`, etc.).
2. Clone this repo into `~/dotfiles`.
3. From inside the repo, stow whichever modules you want, e.g.
   ```sh
   stow shell git bin sway
   ```
   Re-run `stow` whenever you add new modules or update configs.

## Notes

- `bin/.local/bin/sshadd` expects KDE's `ksshaskpass` (or another askpass
  program) to be available so it can add keys without a TTY.
