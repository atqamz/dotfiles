# Phase 1: Capture Suite Completion

## Overview

Complete the capture suite (issue #5, Phase 1) by fixing screen-record (#7) and adding text-extract (#8) and color-picker (#9). All scripts follow omarchy's patterns verbatim.

Reference: `~/repo/omarchy/bin/omarchy-capture-*`

## #7 Screen-record Fix

### Problem

Recording output files are broken/unplayable (261 bytes — just mp4 header, no frames). Direct `gpu-screen-recorder -w eDP-1 -o test.mp4` works fine (632KB+ valid file). Issue is in the script, not gsr itself.

### Root Cause Investigation

Compare our script against omarchy's line by line. Known diffs:

| Area | Ours | Omarchy |
|------|------|---------|
| Shell flags | `set -uo pipefail` | none |
| finalize_recording | removed | present (ffprobe + ffmpeg trim/normalize) |
| Indicator | `qs ipc call record start/stop` | `pkill -RTMIN+8 waybar` |
| bash-common | sourced (require_cmd) | not used |
| OUTPUT_DIR | `$XDG_VIDEOS_DIR/Recordings/` | `$XDG_VIDEOS_DIR/` (no subdir) |

### Fix Plan

Primary suspect: `set -uo pipefail` — omarchy has no shell flags. This can cause:
- `-u`: exit on unset variable (e.g. empty `audio_args[@]` on older bash)
- `-o pipefail`: any pipe failure kills the script (gsr pipe paths)

Fix 1: Remove `set -uo pipefail` to match omarchy exactly. No shell flags.

Fix 2: Add file size validation in wait loop — gsr creating 261-byte header then dying passes current check (`[[ ! -f $filename ]]` succeeds when header exists). Add minimum size check after loop.

Fix 3: Restore `finalize_recording` from omarchy (ffprobe warmup-packet check + ffmpeg trim first frame + loudnorm audio normalization).

Debug if fixes don't resolve:
1. `SCREENRECORD_DEBUG=true screen-record` → check `/tmp/screen-record.log` (truncate first)
2. Log computed gsr args before launch
3. Check if gsr process stays alive: `sleep 2 && pgrep -f gpu-screen-recorder`
4. Test monitor vs region capture separately

### Acceptance

- `screen-record` produces playable mp4 with video
- `screen-record --with-desktop-audio` captures audio
- Region and monitor capture both work
- Toggle (run again to stop) works
- QS recording indicator shows/hides
- Notification with preview thumbnail on stop

## #8 Text Extract (OCR)

### Reference

`omarchy-capture-text-extraction` — 27 lines, near-verbatim port.

### Script: `text-extract`

```bash
#!/usr/bin/env bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${BASH_COMMON:-$script_dir/bash-common}"

require_cmd grim
require_cmd slurp
require_cmd tesseract
require_cmd wl-copy

cleanup_freeze() {
  [[ -n ${PID:-} ]] && kill $PID 2>/dev/null
}
trap cleanup_freeze EXIT

hyprpicker -r -z >/dev/null 2>&1 &
PID=$!
sleep .1
SELECTION=$(slurp 2>/dev/null)

[[ -z $SELECTION ]] && exit 0

TEXT=$(grim -g "$SELECTION" - | tesseract stdin stdout --oem 1 --psm 6 -l "${OCR_LANGS:-eng}" --dpi 300 -c preserve_interword_spaces=1 2>/dev/null) || exit 1

[[ -z $TEXT ]] && exit 1

printf "%s" "$TEXT" | wl-copy
notify-send "Copied text from selection to clipboard"
```

### Keybinding

```
bind = $mainMod SHIFT, T, exec, text-extract
```

### Dependencies

- `tesseract` + `tesseract-langpack-eng` (add to dotmachines)

## #9 Color Picker

### Reference

`omarchy-menu` line 153: `pkill hyprpicker || hyprpicker -a`

### Script: `color-picker`

```bash
#!/usr/bin/env bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${BASH_COMMON:-$script_dir/bash-common}"

require_cmd hyprpicker

pkill hyprpicker 2>/dev/null && exit 0

COLOR=$(hyprpicker -a 2>/dev/null)
[[ -n $COLOR ]] && notify-send "Color picked: $COLOR" "Copied to clipboard"
```

Note: `hyprpicker -a` auto-copies to clipboard. The script adds toggle behavior (running while picker is active kills it) and a notification. Omarchy's version is a bare one-liner in the menu — we wrap it as a script for keybind consistency.

### Keybinding

```
bind = $mainMod SHIFT, C, exec, color-picker
```

### Dependencies

- `hyprpicker` (already installed)

## Hyprland Config Changes

Add to keybindings section after existing capture binds:

```
bind = $mainMod SHIFT, T, exec, text-extract
bind = $mainMod SHIFT, C, exec, color-picker
```

## Dotmachines Changes

Add to `workstations.yaml` base_packages.cli:

```yaml
- tesseract
- tesseract-langpack-eng
```

## Scripts README Changes

Add to dependencies:
- `tesseract` — OCR engine for text extraction
- `tesseract-langpack-eng` — English language pack

## Issue Closure

- #8 closed by text-extract PR
- #9 closed by color-picker PR
- #7 closed when recording output verified working
