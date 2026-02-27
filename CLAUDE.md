# Dotfiles repo conventions

## Structure

Each top-level directory is a GNU Stow package. Files inside mirror `$HOME`,
so `kitty/.config/kitty/kitty.conf` becomes `~/.config/kitty/kitty.conf`.

`STOW_DIRS` in the Makefile lists every active module. `make` restows them all;
`make delete` removes symlinks.

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
