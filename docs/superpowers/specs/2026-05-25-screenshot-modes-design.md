# Screenshot: smart/region/window/fullscreen modes with post-capture editing

Issue: #6
Date: 2026-05-25

## Overview

Rewrite `scripts/.local/bin/scripts/screenshot` with four capture modes
(smart, region, window, fullscreen), four processing modes (all, copy, save,
edit), screen freeze during selection, and post-capture notification with edit
action. Follows omarchy's capture approach.

## CLI interface

```
screenshot [mode] [processing] [--delay=N] [--editor=<name>]
```

### Capture modes (arg 1, default: smart)

| Mode       | Behavior                                                                    |
|------------|-----------------------------------------------------------------------------|
| smart      | Show window + monitor rectangles + freeform region. Tiny selection (<20px area) snaps to containing window. |
| region     | Freeform region selection via slurp.                                        |
| window     | Pick from window rectangles only (no freeform).                             |
| fullscreen | Active monitor, no selection needed.                                        |

### Processing modes (arg 2, default: all)

| Mode | Behavior                                        |
|------|-------------------------------------------------|
| all  | Save to file + clipboard + notification w/ edit |
| copy | Clipboard only                                  |
| save | File only                                       |
| edit | Open editor directly (swappy/satty)             |

### Options

- `--editor=<name>` — override annotation editor binary
- `--delay=N` — delay N seconds before capture (for hover popups)

### Environment variables

- `SCREENSHOT_DIR` — output directory (default: `$XDG_PICTURES_DIR/Screenshots`
  or `~/Pictures/Screenshots`)
- `SCREENSHOT_EDITOR` — annotation editor binary (default: satty)

Editor resolution order: `--editor` flag > `$SCREENSHOT_EDITOR` > satty (if
available) > swappy (if available) > none.

## Capture flow

### Screen freeze

All modes except fullscreen freeze the screen during selection via
`hyprpicker -r -z`. Hyprpicker stays alive through grim capture (so grim
captures the frozen overlay). Killed via EXIT trap or explicit `cleanup_freeze`
after grim.

### Rectangle selection

`get_rectangles` returns geometries for the active workspace only: the focused
monitor rect (scale/transform-aware) plus all client windows on the active
workspace.

### Smart mode

1. Get rectangles before freeze
2. Freeze screen
3. Pipe rects to slurp (freeform + predefined rectangles)
4. If selection area < 20px: snap to containing window/monitor via regex match
5. `grim -g "$SELECTION"` while freeze alive
6. Kill freeze

### Region mode

1. Freeze screen
2. `slurp` freeform
3. `grim -g "$SELECTION"` while freeze alive
4. Kill freeze

### Window mode

1. Freeze screen
2. `get_rectangles | slurp -r` (predefined only)
3. `grim -g "$SELECTION"` while freeze alive
4. Kill freeze

### Fullscreen mode

1. Get focused monitor geometry (scale/transform-aware via jq)
2. `grim -g "$SELECTION"` (no freeze)

## Post-capture processing

### Mode: all

1. `grim -g "$SELECTION" "$filepath"` — save to file
2. `wl-copy < "$filepath"` — copy to clipboard
3. Background notification with Edit action (10s timeout, `-A` flag)

### Mode: copy

1. `grim -g "$SELECTION" - | wl-copy`

### Mode: save

1. `grim -g "$SELECTION" "$filepath"`

### Mode: edit

1. `grim -g "$SELECTION" "$tmpfile"`
2. `open_editor "$tmpfile"` — satty with `--early-exit` or swappy with `-o`
3. Clean up temp file

## Editor behavior

### satty

```
satty --filename "$filepath" --copy-command wl-copy --early-exit
```

### swappy

```
swappy -f "$filepath" -o "$save_path"
```

Swappy config (`swappy/.config/swappy/config`) sets `early_exit=true` and
`save_dir=$HOME/Pictures/Screenshots`.

## Keybindings

```
bind = , Print, exec, screenshot                           # smart -> all
bind = $mainMod SHIFT, S, exec, screenshot region edit     # region -> editor
bind = $mainMod, Print, exec, screenshot fullscreen        # fullscreen -> all
bind = $mainMod SHIFT, Print, exec, screenshot smart copy  # smart -> clipboard
```

## Script structure

Single file: `scripts/.local/bin/scripts/screenshot`

Top-level flow (no functions for capture — inline case blocks like omarchy):
- Arg parsing with validation
- `resolve_editor` — flag > env > satty > swappy > none
- `cleanup_freeze` — kill + wait hyprpicker, EXIT trap
- `JQ_MONITOR_GEO` — jq helper for scale/transform-aware monitor geometry
- `get_rectangles` — active workspace windows + monitor rect
- Mode case block — freeze, slurp, selection (with smart snap logic)
- `generate_filepath` / `open_editor` helpers
- Processing case block — grim + post-processing per mode

## Dependencies

### Required

- grim
- slurp
- hyprpicker
- wl-clipboard (wl-copy)
- jq

### Optional

- satty (preferred editor)
- swappy (fallback editor, stow module configures it)
- libnotify (notify-send, for `all` mode notifications)

## File changes

- `scripts/.local/bin/scripts/screenshot` — rewrite
- `hypr/.config/hypr/hyprland.conf` — replace screenshot keybinding
- `scripts/README.md` — add hyprpicker, satty to dependencies
- `swappy/.config/swappy/config` — new (early_exit, save_dir)
- `swappy/README.md` — new
- `Makefile` — add swappy to STOW_DIRS
