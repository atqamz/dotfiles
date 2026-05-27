# Screen recording: gpu-screen-recorder toggle with quickshell indicator

Issue: #7 (parent #5, Phase 1 capture suite)
Date: 2026-05-27

## Overview

New `screen-record` script that toggles screen recording via gpu-screen-recorder
(NVENC GPU encoding). Ported near-verbatim from omarchy's
`omarchy-capture-screenrecording`, with the waybar indicator signal replaced by
a quickshell IPC call to a new `RecordingIndicator` module. Mirrors the
screenshot script's omarchy-faithful approach.

## Script: `screen-record`

Location: `scripts/.local/bin/scripts/screen-record`

### CLI interface

```
screen-record [--with-desktop-audio] [--with-microphone-audio] [--with-webcam]
              [--webcam-device=<dev>] [--resolution=<WxH>] [--stop-recording]
```

Toggle semantics: if a gpu-screen-recorder process is running, stop it;
otherwise start a new recording. `--stop-recording` only stops (no-op start if
nothing running).

### Detection and state

- Active check: `pgrep -f "^gpu-screen-recorder"`
- State file: `/tmp/screen-record-filename` stores the active recording path
- Debug log: `/tmp/screen-record.log` when `SCREENRECORD_DEBUG=true`, else
  `/dev/null`

### Output

- Directory: `${SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings}`
- `mkdir -p` the directory if missing
- Filename: `screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4`

### Start flow

1. Capture target selection (`select_capture_target`):
   - `get_rectangles` — monitor rects (scale-aware) + client window rects on the
     focused workspace, in slurp `"X,Y WxH"` format
   - Freeze screen: `hyprpicker -r -z &`, `sleep 0.1`
   - `echo "$rects" | slurp`, then kill hyprpicker
   - Selection regex allows negative X/Y (multi-monitor): `^(-?[0-9]+),(-?[0-9]+) ([0-9]+)x([0-9]+)$`
   - Bare click (area < 20px²) snaps to the containing rectangle
   - If selection exactly matches a monitor geometry, return `monitor:NAME`;
     otherwise `region:WxH+X+Y` (logical coords, gsr scales to physical)
   - Returns non-zero if the user cancelled
2. Build capture args:
   - `monitor:*` → `-w <name> -s "${RESOLUTION:-$(default_resolution)}"`
   - `region:*` → `-w <region>`, append `-s "$RESOLUTION"` only if set
   - `default_resolution`: `3840x2160` if monitor > 4K else `0x0`
3. Optional webcam overlay (`--with-webcam`):
   - Auto-detect first `/dev/video*` via `v4l2-ctl --list-devices` if no
     `--webcam-device`
   - Pick first available 16:9 resolution from `640x360 1280x720 1920x1080`
   - `ffplay` overlay window titled `WebcamOverlay`, cropped/scaled to monitor
     scale, low-latency flags
4. Audio devices:
   - `--with-desktop-audio` → `default_output`
   - `--with-microphone-audio` → `default_input`
   - Merged with `|` into one track; passed as `-a "$devices" -ac aac`
5. Launch: `gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}"`
6. Wait until the output file appears (process still alive), write path to state
   file, signal indicator on

### Stop flow

1. `pkill -SIGINT -f "^gpu-screen-recorder"` (SIGINT required for clean save)
2. Wait up to 5s (50 × 0.1s) for the process to exit
3. Signal indicator off, cleanup webcam (`pkill -f WebcamOverlay`)
4. If still alive: `pkill -9`, notify critical "may be corrupted"
5. Else `finalize_recording`, then preview + notification:
   - Preview thumbnail: `ffmpeg -y -i "$file" -ss 00:00:00.1 -vframes 1 -q:v 2 "$preview"`
   - Background notification with `-A "default=open"` → `mpv "$file"` on click
6. Remove state file

### finalize_recording

- Read active path from state file; skip if file missing
- Re-encode video only if the first GOP has discardable warmup packets
  (`ffprobe ... packet=flags ... | grep -q D`) → `libx264 -preset veryfast -crf 20`,
  else `-c:v copy`
- Trim first 0.1s (`-ss 0.1`); if audio present, mute first 400ms (drop PipeWire
  capture pop), 50ms fade-in, `loudnorm=I=-14:TP=-1.5:LRA=11`
- Single-pass ffmpeg to `${file%.mp4}-processed.mp4`, then `mv` over original on
  success

### Adaptations from omarchy

| omarchy | this script |
|---------|-------------|
| `OMARCHY_SCREENRECORD_DIR` | `SCREENRECORD_DIR` |
| `OMARCHY_SCREENRECORD_DEBUG` | `SCREENRECORD_DEBUG` |
| `OMARCHY_SCREENRECORD_USE_PORTAL` | `SCREENRECORD_USE_PORTAL` |
| output `$XDG_VIDEOS_DIR` | `$XDG_VIDEOS_DIR/Recordings` |
| `/tmp/omarchy-screenrecord-filename` | `/tmp/screen-record-filename` |
| `pkill -RTMIN+8 waybar` | `qs ipc call record start` / `qs ipc call record stop` (\|\| true) |
| (no source) | source `bash-common`, `require_cmd` |

IPC calls are guarded with `|| true` so the script works when quickshell is not
running.

## Quickshell indicator: `RecordingIndicator.qml`

Location: `quickshell/.config/quickshell/modules/RecordingIndicator.qml`
Registered in `shell.qml` alongside `Osd {}`: add `RecordingIndicator {}`.

Pattern mirrors `Osd.qml` — a `Scope` with an `IpcHandler` and per-screen
`Variants` of a `PanelWindow`.

```qml
Scope {
    id: root
    property bool recording: false

    IpcHandler {
        target: "record"
        function start(): void { root.recording = true; }
        function stop(): void { root.recording = false; }
        function toggle(): void { root.recording = !root.recording; }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.recording
            anchors { top: true; right: true }
            margins { top: 8; right: 8 }
            // ... red dot + REC label, click-through, pulse animation
        }
    }
}
```

Visual:
- Small pill: red filled circle (`Theme.error`) + "REC" label
- Subtle opacity pulse (SequentialAnimation, loops) to read as live
- `WlrLayershell.layer: WlrLayer.Top`, `keyboardFocus: None`, transparent panel
- Visible only when `recording == true`

## Keybindings

In `hypr/.config/hypr/hyprland.conf`:

```
bind = $mainMod SHIFT, R, exec, screen-record
bind = $mainMod CTRL, R, exec, screen-record --with-desktop-audio
bind = $mainMod SHIFT ALT, R, exec, screen-record --with-desktop-audio --with-microphone-audio
```

Monitor vs region is chosen at pick time (click-snap), so no `--fullscreen`
flag. Pressing the same bind while recording stops it (toggle).

## Dependencies

### New

- gpu-screen-recorder
- ffmpeg (provides ffmpeg + ffprobe)
- v4l2-utils (v4l2-ctl, for webcam autodetect)
- mpv (open-on-click from notification)

### Existing

- slurp, hyprpicker, jq, libnotify (notify-send)

New packages tracked in dotmachines (see #5 cross-cutting reference).

## File changes

- `scripts/.local/bin/scripts/screen-record` — new
- `scripts/README.md` — add gpu-screen-recorder, ffmpeg, v4l2-utils, mpv
- `quickshell/.config/quickshell/modules/RecordingIndicator.qml` — new
- `quickshell/.config/quickshell/shell.qml` — register `RecordingIndicator {}`
- `hypr/.config/hypr/hyprland.conf` — three keybindings

No new stow module (gpu-screen-recorder needs no managed config; output dir via
env/default).

## Verification

Requires a live Hyprland + quickshell session and an NVIDIA GPU:

1. `screen-record` → pick region → records; indicator shows top-right
2. `screen-record` again → stops; finalize runs; notification with Open action
3. Click a monitor (bare click) → snaps to full monitor capture
4. `screen-record --with-desktop-audio` → recording has desktop audio track
5. `screen-record --with-microphone-audio` → mic track present
6. `screen-record --stop-recording` with nothing running → exits non-zero, no-op
7. Output files land in `~/Videos/Recordings/screenrecording-*.mp4`
8. Keybindings toggle correctly on a live session
