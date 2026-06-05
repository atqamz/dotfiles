# Dotfiles repo conventions

## Structure

Each top-level directory is a GNU Stow package. Files inside mirror `$HOME`,
so `hypr/.config/hypr/hyprland.conf` becomes `~/.config/hypr/hyprland.conf`.

`STOW_DIRS` in the Makefile lists every active module. `make` restows them all;
`make delete` removes symlinks.

## Dual consumption (stow and Home Manager)

This repo is the single source of truth for two consumers, so keep the stow
package-per-app layout (`<module>/.config/<app>/`) intact — it is the exact
shape both expect. Restructuring would silently break the Home Manager side.

- **GNU Stow (Fedora / sfx14)** symlinks every file into `$HOME` directly, as
  described above.
- **Home Manager (NixOS / pavg15)**, in a separate config repo, consumes the
  same tree two ways:
  - `hypr`, `quickshell`, and other raw configs are linked via
    `mkOutOfStoreSymlink` pointed at this directory, so live edits apply
    without a rebuild.
  - `bash`, `tmux`, `git`, `readline` are **not** symlinked — they are
    re-curated as Home Manager `programs.*` options. Editing those files here
    does not reach the NixOS box until that config is also updated; watch for
    drift.

Keep this repo tool-agnostic: no Nix (or other manager) references belong here.

## Module README

Every stow module must have a `README.md` at its root containing:

1. A short description of what the module configures.
2. A **Dependencies** section listing required packages (or stating "none").

Stow's default ignore list already excludes `README.*`, so these files are
never symlinked into `$HOME`.

## Adding a new module

1. Create the directory with files mirroring `$HOME`.
2. Add the directory name to `STOW_DIRS` in the Makefile.
3. Add backup targets to `BACKUP_TARGETS` in the Makefile if the files might
   already exist on a fresh system.
4. Create a `README.md` following the format above.

## Adding dependencies

List new dependencies in the module's `README.md` Dependencies section.

## Git workflow

Single maintainer — commit and push directly to `master`. No branches or PRs
needed.
