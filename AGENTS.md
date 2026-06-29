# AGENTS.md

Repo-specific rules. Global rules (`~/dotai/AGENTS.md`) apply unless overridden here.

## Layout

Per-tool dotfiles, symlinked into `~/.config` by the universe bootstrap. `hypr/` Hyprland lua (shared `hyprland.lua` + per-host `hosts/<hostname>.lua`), `fish/`, `fastfetch/`, `zed/`, `cs2/`.

## Rules

- No comments in the codebase. Code speaks. None at all, not even "why" — stricter than global.
- Keep functional pragmas only (shebangs, `# shellcheck disable=`).
- Lua must parse clean under Hyprland's lua provider: `hyprctl keyword`/`dispatch` are rejected for config calls — use `hyprctl eval 'hl.foo(...)'`.
