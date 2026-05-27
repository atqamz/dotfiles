# Screen Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `screen-record` script (gpu-screen-recorder toggle) plus a quickshell recording indicator, ported near-verbatim from omarchy.

**Architecture:** Bash script handles capture/audio/finalize logic and signals a quickshell `RecordingIndicator` module over IPC (`qs ipc call record start|stop`). Falls back gracefully when quickshell is absent.

**Tech Stack:** bash, gpu-screen-recorder, hyprpicker, slurp, jq, ffmpeg/ffprobe, v4l2-ctl, mpv, Quickshell QML

**Spec:** `docs/superpowers/specs/2026-05-27-screen-record-design.md`

**Note:** No automated test suite for shell/QML in this repo. Verification is `bash -n` for syntax, loading quickshell for QML, and manual runtime checks (matches the screenshot script precedent). There is no qmllint available.

---

### Task 1: screen-record script

**Files:**
- Create: `scripts/.local/bin/scripts/screen-record`

- [ ] **Step 1: Write the full script**

Create `scripts/.local/bin/scripts/screen-record` with exactly:

```bash
#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${BASH_COMMON:-$script_dir/bash-common}"

require_cmd gpu-screen-recorder
require_cmd hyprpicker
require_cmd slurp
require_cmd jq

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings}"
mkdir -p "$OUTPUT_DIR"

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"
WEBCAM="false"
WEBCAM_DEVICE=""
RESOLUTION=""
STOP_RECORDING="false"
RECORDING_FILE="/tmp/screen-record-filename"
LOG_FILE=$([[ ${SCREENRECORD_DEBUG:-false} == "true" ]] && echo "/tmp/screen-record.log" || echo "/dev/null")

for arg in "$@"; do
  case "$arg" in
  --with-desktop-audio) DESKTOP_AUDIO="true" ;;
  --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
  --with-webcam) WEBCAM="true" ;;
  --webcam-device=*) WEBCAM_DEVICE="${arg#*=}" ;;
  --resolution=*) RESOLUTION="${arg#*=}" ;;
  --stop-recording) STOP_RECORDING="true" ;;
  esac
done

indicator() {
  qs ipc call record "$1" >/dev/null 2>&1 || true
}

start_webcam_overlay() {
  cleanup_webcam

  if [[ -z $WEBCAM_DEVICE ]]; then
    WEBCAM_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -m1 "^[[:space:]]*/dev/video" | tr -d '\t')
    if [[ -z $WEBCAM_DEVICE ]]; then
      notify-send "No webcam devices found" -u critical -t 3000
      return 1
    fi
  fi

  local scale=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')
  local target_width=$(awk "BEGIN {printf \"%.0f\", 360 * $scale}")
  local preferred_resolutions=("640x360" "1280x720" "1920x1080")
  local video_size_arg=""
  local available_formats=$(v4l2-ctl --list-formats-ext -d "$WEBCAM_DEVICE" 2>/dev/null)

  for resolution in "${preferred_resolutions[@]}"; do
    if echo "$available_formats" | grep -q "$resolution"; then
      video_size_arg="-video_size $resolution"
      break
    fi
  done

  ffplay -f v4l2 $video_size_arg -framerate 30 "$WEBCAM_DEVICE" \
    -vf "crop=iw/2:ih,scale=${target_width}:-1" \
    -window_title "WebcamOverlay" \
    -noborder \
    -fflags nobuffer -flags low_delay \
    -probesize 32 -analyzeduration 0 \
    -loglevel quiet &
  sleep 1
}

cleanup_webcam() {
  pkill -f "WebcamOverlay" 2>/dev/null
}

default_resolution() {
  local width height
  read -r width height < <(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"')
  if ((width > 3840 || height > 2160)); then
    echo "3840x2160"
  else
    echo "0x0"
  fi
}

get_rectangles() {
  local active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
  hyprctl monitors -j | jq -r --arg ws "$active_workspace" '
    .[] | select(.activeWorkspace.id == ($ws | tonumber)) |
    "\(.x),\(.y) \(.width / .scale | floor)x\(.height / .scale | floor)"'
  hyprctl clients -j | jq -r --arg ws "$active_workspace" '
    .[] | select(.workspace.id == ($ws | tonumber)) |
    "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

select_capture_target() {
  local rects=$(get_rectangles)
  hyprpicker -r -z >/dev/null 2>&1 &
  local picker_pid=$!
  sleep .1
  local selection=$(echo "$rects" | slurp 2>/dev/null)
  kill $picker_pid 2>/dev/null

  [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || return 1
  local sx=${BASH_REMATCH[1]} sy=${BASH_REMATCH[2]}
  local sw=${BASH_REMATCH[3]} sh=${BASH_REMATCH[4]}

  if ((sw * sh < 20)); then
    while IFS= read -r rect; do
      [[ $rect =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
      local rx=${BASH_REMATCH[1]} ry=${BASH_REMATCH[2]}
      local rw=${BASH_REMATCH[3]} rh=${BASH_REMATCH[4]}
      if ((sx >= rx && sx < rx + rw && sy >= ry && sy < ry + rh)); then
        sx=$rx sy=$ry sw=$rw sh=$rh
        break
      fi
    done <<<"$rects"
  fi

  local monitor=$(hyprctl monitors -j | jq -r --argjson x "$sx" --argjson y "$sy" --argjson w "$sw" --argjson h "$sh" '
    .[] | select(.x == $x and .y == $y and (.width / .scale | floor) == $w and (.height / .scale | floor) == $h) | .name' | head -1)

  if [[ -n $monitor ]]; then
    echo "monitor:$monitor"
    return
  fi

  echo "region:${sw}x${sh}+${sx}+${sy}"
}

start_screenrecording() {
  local capture_args=()
  local target

  if [[ ${SCREENRECORD_USE_PORTAL:-false} == "true" ]]; then
    target="portal"
    capture_args=(-w portal -s "${RESOLUTION:-$(default_resolution)}")
  else
    target=$(select_capture_target) || return 1

    case $target in
    monitor:*)
      capture_args=(-w "${target#monitor:}" -s "${RESOLUTION:-$(default_resolution)}")
      ;;
    region:*)
      capture_args=(-w "${target#region:}")
      [[ -n $RESOLUTION ]] && capture_args+=(-s "$RESOLUTION")
      ;;
    esac
  fi

  [[ $WEBCAM == "true" ]] && start_webcam_overlay

  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local audio_devices=""
  local audio_args=()

  [[ $DESKTOP_AUDIO == "true" ]] && audio_devices+="default_output"

  if [[ $MICROPHONE_AUDIO == "true" ]]; then
    [[ -n $audio_devices ]] && audio_devices+="|"
    audio_devices+="default_input"
  fi

  [[ -n $audio_devices ]] && audio_args+=(-a "$audio_devices" -ac aac)

  echo "===== $(date '+%F %T') args: $* target: $target =====" >>"$LOG_FILE"
  gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}" 2>>"$LOG_FILE" &
  local pid=$!

  while kill -0 $pid 2>/dev/null && [[ ! -f $filename ]]; do
    sleep 0.2
  done

  if kill -0 $pid 2>/dev/null; then
    echo "$filename" >"$RECORDING_FILE"
    indicator start
  fi
}

stop_screenrecording() {
  pkill -SIGINT -f "^gpu-screen-recorder"

  local count=0
  while pgrep -f "^gpu-screen-recorder" >/dev/null && ((count < 50)); do
    sleep 0.1
    count=$((count + 1))
  done

  indicator stop
  cleanup_webcam

  if pgrep -f "^gpu-screen-recorder" >/dev/null; then
    pkill -9 -f "^gpu-screen-recorder"
    notify-send "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
  else
    finalize_recording
    local filename=$(cat "$RECORDING_FILE" 2>/dev/null)
    echo "$filename"
    local preview="${filename%.mp4}-preview.png"

    ffmpeg -y -i "$filename" -ss 00:00:00.1 -vframes 1 -q:v 2 "$preview" -loglevel quiet 2>/dev/null

    (
      ACTION=$(notify-send "Screen recording saved" "Click to open" -t 10000 -i "${preview:-$filename}" -A "default=open")
      [[ $ACTION == "default" ]] && mpv "$filename"
      rm -f "$preview"
    ) &
  fi

  rm -f "$RECORDING_FILE"
}

screenrecording_active() {
  pgrep -f "^gpu-screen-recorder" >/dev/null
}

finalize_recording() {
  local latest
  latest=$(cat "$RECORDING_FILE" 2>/dev/null)
  [[ -f $latest ]] || return

  local video_codec=(-c:v copy)
  if ffprobe -v error -select_streams v:0 -read_intervals %+0.2 -show_entries packet=flags -of csv=p=0 "$latest" 2>/dev/null | grep -q D; then
    video_codec=(-c:v libx264 -preset veryfast -crf 20)
  fi

  local args=(-y -ss 0.1 -i "$latest" "${video_codec[@]}")
  if ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$latest" 2>/dev/null | grep -q audio; then
    args+=(-af "volume=enable='lt(t,0.4)':volume=0,afade=t=in:st=0.4:d=0.05,loudnorm=I=-14:TP=-1.5:LRA=11")
  fi

  local processed="${latest%.mp4}-processed.mp4"
  if ffmpeg "${args[@]}" "$processed" -loglevel quiet 2>/dev/null; then
    mv "$processed" "$latest"
  else
    rm -f "$processed"
  fi
}

if screenrecording_active; then
  stop_screenrecording
elif [[ $STOP_RECORDING == "true" ]]; then
  exit 1
else
  start_screenrecording || cleanup_webcam
fi
```

- [ ] **Step 2: Make executable and verify syntax**

Run:
```bash
chmod +x scripts/.local/bin/scripts/screen-record
bash -n scripts/.local/bin/scripts/screen-record && echo "syntax ok"
```
Expected: `syntax ok`

- [ ] **Step 3: Verify helper functions produce output (Hyprland session)**

Run:
```bash
bash -c 'source scripts/.local/bin/scripts/bash-common; source <(sed -n "/^get_rectangles()/,/^}/p" scripts/.local/bin/scripts/screen-record); get_rectangles | head -3'
```
Expected: lines like `0,0 1920x1200` (monitor + window geometries). If not on Hyprland, skip and rely on `bash -n`.

- [ ] **Step 4: Commit**

```bash
git add scripts/.local/bin/scripts/screen-record
git commit -m "add screen-record script with gpu-screen-recorder toggle"
```

---

### Task 2: RecordingIndicator quickshell module

**Files:**
- Create: `quickshell/.config/quickshell/modules/RecordingIndicator.qml`

- [ ] **Step 1: Write the module**

Create `quickshell/.config/quickshell/modules/RecordingIndicator.qml` with:

```qml
// quickshell/.config/quickshell/modules/RecordingIndicator.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services

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

            anchors {
                top: true
                right: true
            }

            margins {
                top: 8
                right: 8
            }

            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            StyledRect {
                id: pill
                implicitWidth: row.implicitWidth + 24
                implicitHeight: 28
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.full

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: Theme.error

                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "REC"
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify imports match existing modules**

Run:
```bash
grep -h "^import" quickshell/.config/quickshell/modules/Osd.qml quickshell/.config/quickshell/modules/bar/StatusPill.qml
```
Expected: confirms `qs.components` (StyledRect, StyledText, MaterialIcon), `qs.services` (Theme) are the correct import paths. The new module uses `StyledRect`, `StyledText`, `Theme` — all confirmed present in those files.

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/modules/RecordingIndicator.qml
git commit -m "add quickshell recording indicator module"
```

---

### Task 3: Register module in shell.qml

**Files:**
- Modify: `quickshell/.config/quickshell/shell.qml`

- [ ] **Step 1: Add RecordingIndicator to ShellRoot**

In `quickshell/.config/quickshell/shell.qml`, add `RecordingIndicator {}` after the `Osd {}` line:

```qml
    Osd {}
    RecordingIndicator {}
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "RecordingIndicator" quickshell/.config/quickshell/shell.qml
```
Expected: one line showing `RecordingIndicator {}`

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/shell.qml
git commit -m "register recording indicator in shell"
```

---

### Task 4: Keybindings

**Files:**
- Modify: `hypr/.config/hypr/hyprland.conf`

- [ ] **Step 1: Add screen-record keybindings**

In `hypr/.config/hypr/hyprland.conf`, in the `# Section: System` block, after the last screenshot bind (`bind = $mainMod SHIFT, Print, exec, screenshot smart copy` at line 158, before the blank line and `# Section: Window management` at line 160), add:

```
bind = $mainMod SHIFT, R, exec, screen-record
bind = $mainMod CTRL, R, exec, screen-record --with-desktop-audio
bind = $mainMod SHIFT ALT, R, exec, screen-record --with-desktop-audio --with-microphone-audio
```

- [ ] **Step 2: Verify no conflicts and binds present**

Run:
```bash
grep -n "screen-record" hypr/.config/hypr/hyprland.conf
```
Expected: three lines with the new binds.

- [ ] **Step 3: Commit**

```bash
git add hypr/.config/hypr/hyprland.conf
git commit -m "add screen-record keybindings"
```

---

### Task 5: Update scripts README

**Files:**
- Modify: `scripts/README.md`

- [ ] **Step 1: Add dependencies**

In `scripts/README.md`, add these lines after the `- nvidia-smi (optional, for GPU status)` line:

```
- gpu-screen-recorder
- ffmpeg (provides ffprobe)
- v4l2-utils (v4l2-ctl, webcam overlay)
- mpv (open recording from notification)
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "gpu-screen-recorder\|v4l2-utils\|mpv" scripts/README.md
```
Expected: the three new dependency lines present.

- [ ] **Step 3: Commit**

```bash
git add scripts/README.md
git commit -m "add screen-record dependencies to scripts README"
```

---

### Task 6: Manual verification (live Hyprland + quickshell, NVIDIA GPU)

This task requires a running session with gpu-screen-recorder installed.

- [ ] **Step 1: Restow**

Run:
```bash
make -C /home/atqa/dotfiles
```
Expected: stow links updated, no errors.

- [ ] **Step 2: Reload quickshell and Hyprland**

Run:
```bash
qs kill 2>/dev/null; qs >/dev/null 2>&1 & disown
hyprctl reload
```
Expected: quickshell restarts, config reloads `ok`.

- [ ] **Step 3: Test region recording + indicator**

Run `screen-record`, select a region by dragging.
Expected: REC indicator appears top-right (pulsing red dot). A recording file is being written to `~/Videos/Recordings/`.

- [ ] **Step 4: Stop recording**

Run `screen-record` again.
Expected: REC indicator disappears. Finalize runs. Notification "Screen recording saved" with clickable open action. Clicking opens the file in mpv.

- [ ] **Step 5: Test monitor snap**

Run `screen-record`, single-click (no drag) on a monitor.
Expected: snaps to full monitor capture (`-w <name>`).

- [ ] **Step 6: Test audio**

Run `screen-record --with-desktop-audio`, record a few seconds of audio playback, stop.
Expected: output file has a desktop audio track (`ffprobe ~/Videos/Recordings/<file>.mp4` shows an audio stream).

- [ ] **Step 7: Test stop-only no-op**

With nothing recording, run `screen-record --stop-recording`.
Expected: exits non-zero, no recording starts, no indicator.

- [ ] **Step 8: Test keybindings**

Press `Super+Shift+R` (start/stop), `Super+Ctrl+R` (desktop audio), `Super+Shift+Alt+R` (full audio).
Expected: each toggles recording with the right audio config.
