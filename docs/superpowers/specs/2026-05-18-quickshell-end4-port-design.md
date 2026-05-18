# Quickshell end-4 Port — Design

**Goal:** Port high-value end-4 (illogical-impulse / ii-qs) modules into the existing floating-pills quickshell config. Replace naive in-house modules with end-4-quality reimplementations adapted to the locked pure-black Theme palette. No matugen, no Material-You dynamic colour, no caelestia dependency.

**Branch:** Continue on `quickshell-floating-pills`. Each module is its own commit.

**Source:** `github.com/end-4/dots-hyprland`, path `dots/.config/quickshell/ii/` (cloned shallow at `/tmp/end-4` for reference reading only — code is rewritten, not copy-pasted, to drop heavy deps: Config, Translation, Appearance singletons, Cava, ScriptModel, GlobalStates, GlobalFocusGrab, StyledRectangularShadow, StringUtils, FileUtils).

---

## Locked Decisions

| Decision | Value |
|---|---|
| Phase order | Phase 1 = Tier 1 (new) + Rewrites; Phase 2 = Tier 2 (new) |
| GPU | Nvidia only (nvidia-smi parsing) |
| Resources pill | Consolidates CPU + RAM + GPU + Claude session% + Claude week% |
| Standalone ClaudePill | Removed in Phase 2 (when Resources lands) |
| Cheatsheet style | Centered overlay, categorized by `# section` comments in hyprland.conf, no periodic-table easter egg |
| Theme | Same pure-black palette (`Theme.background = #000`, `Theme.outlineVariant`) — no wallpaper-derived colour |
| Aesthetic | Floating pill / overlay capsule. Bar stays hidden-by-default with peek-on-hover. Overlays use scrim + centered card. |
| Out-of-scope | AI chat, Anime/Booru, Translator, Wallpaper selector, Background module, Dock, Overview, Lock, Polkit, SessionWarnings, Hyprsunset, AntiFlashbang, ScreenCorners, ScreenTranslator, Latex, Weather, Todo, SongRec, Pomodoro, OnScreenKeyboard, Crosshair, FloatingImage, FPS limiter, Recorder, Idle |
| Dependencies | No new system packages beyond: `nvidia-utils` (already present via nvidia role), `bluez-tools` (bluetoothctl, likely present), `dnf-plugins-core` (likely present). Verify in role tasks. |

---

## Phase 1 — Tier 1 (new) + Rewrites

### 1. MPRIS — media player integration

**New files:**
- `services/MprisService.qml` — singleton wrapping `Quickshell.Services.Mpris`. Tracks active player (prefer currently-playing, else first). Exposes: `hasPlayer`, `isPlaying`, `title`, `artist`, `artUrl`, `position`, `length`, `canTogglePlaying`, `canGoNext`, `canGoPrevious`. Methods: `togglePlaying()`, `next()`, `previous()`. IPC handler `mpris` with functions `playPause/next/previous/pauseAll`.
- `modules/bar/MediaPill.qml` — Pill, hidden when `!MprisService.hasPlayer`. Content: `MaterialIcon` (pause/music_note based on `isPlaying`) + truncated title (max 24 chars, ellipsized). Mouse: left → IPC `mediaControls.toggle`; middle → playPause; right → next.
- `modules/MediaControls.qml` — Scope + IpcHandler `mediaControls` (toggle/open/close) + per-screen PanelWindow scrim overlay, layer Overlay, keyboardFocus Exclusive. Centered StyledRect (420×220) shows: 80×80 art (Image or music_note placeholder) + title (bold large) + artist (variant small) + 4px-tall position bar (only when length > 0) + 3 circular buttons (skip_previous 40, play_arrow/pause 52, skip_next 40). Click outside scrim → close. ESC → close. Position bar uses a 1Hz Timer that calls `activePlayer.positionChanged()` while open + playing.

**Modified:**
- `services/qmldir` — add `singleton MprisService 1.0 MprisService.qml`.
- `modules/bar/BottomBar.qml` — insert `MediaPill { id: media; ... x: workspaces.x + workspaces.width + 8 }` between workspaces and clock. Add `media` to PeekState.watchedItems and Connections.
- `modules/Bar.qml` — no change.
- `shell.qml` — add `MediaControls {}`.
- `hypr/.config/hypr/hyprland.conf` — bind `MOD+M` → `qs ipc call mediaControls toggle`. Also bind XF86Audio Play/Pause/Next/Previous keys → `qs ipc call mpris playPause/next/previous`.

### 2. System tray

**New files:**
- `services/TrayService.qml` — wraps `Quickshell.Services.SystemTray`. Singleton exposing `items` (list of SystemTrayItem). No IPC needed.
- `modules/bar/TrayPill.qml` — Pill with a Row of SystemTrayItem icons (16px). Each icon: left-click → `item.activate()`; right-click → opens `item.menu` (use QsMenuAnchor). Hidden when no items. Each icon spaced 8px.

**Modified:**
- `services/qmldir` — add `singleton TrayService`.
- `modules/bar/BottomBar.qml` — insert `TrayPill` between StatusPill and ClaudePill. Right-anchored chain: `status` anchors right; `tray.x = status.x - tray.width - 8`; `claude.x = tray.x - claude.width - 8`. Add to PeekState watched.

### 3. Bluetooth toggle in StatusPill

**New files:**
- `services/Bluetooth.qml` — singleton. Polls `bluetoothctl show` and `bluetoothctl devices Connected` every 5s. Exposes: `powered` (bool), `connectedDeviceCount` (int), `connectedDeviceNames` (string list). Methods: `togglePowered()` → `bluetoothctl power on/off`.

**Modified:**
- `services/qmldir` — add `singleton Bluetooth`.
- `modules/bar/StatusPill.qml` — add a `MaterialIcon` between volume and network: `text: Bluetooth.powered ? (Bluetooth.connectedDeviceCount > 0 ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"`, color text/warning/textDim based on state. TapHandler → `Bluetooth.togglePowered()`. Hidden if `bluetoothctl` not found (Bluetooth.available property).

### 4. Cheatsheet overlay

**New files:**
- `services/HyprlandKeybinds.qml` — singleton. Reads `~/.config/hypr/hyprland.conf` via `FileView`. Parses `bind = MOD, KEY, dispatcher, args` lines. Groups by preceding `# Section: Name` comments (falls back to "Misc"). Exposes `categories` (list of `{ name, binds: [{mods, key, action, description}] }`).
- `modules/Cheatsheet.qml` — Scope + IpcHandler `cheatsheet` (toggle/open/close) + per-screen PanelWindow scrim overlay. Centered StyledRect (640×480) with: title "Keybinds", search TextField (live filter on key/action), scrollable ColumnLayout of category sections. Each section: header (textVariant + uppercase) + Repeater of bind rows. Each row: left = formatted mods+key chips (e.g. `SUPER + L`), right = action description. Use Theme tokens throughout. ESC and click-outside dismiss.

**Modified:**
- `modules/qmldir` — none (no qmldir file present).
- `shell.qml` — add `Cheatsheet {}`.
- `hypr/.config/hypr/hyprland.conf` — bind `MOD+slash` (Super+/) → `qs ipc call cheatsheet toggle`. Add section comments to existing binds so the cheatsheet can group them: `# Section: Window management`, `# Section: Workspaces`, etc.

### 5. Notifications rewrite

**Rewrite `modules/Notifications.qml`:**

Match end-4 NotificationPopup quality:
- Group consecutive notifications from same app into a stack with collapse animation
- Show app icon (use `notif.appIcon` resolved via `Quickshell.iconPath(...)`) in a 24×24 chip
- Inline action buttons under body if `notif.actions.values.length > 0`. Each action = small StyledRect button.
- Hover-to-pause: hover any toast pauses its expire timer. Leave → resume.
- Slide-in from right (NumberAnimation on x, 200ms OutCubic). Toasts stack with 8px spacing.
- Max 5 visible toasts; older spilled into a "+N more" pill at the top.
- Use `Theme.background` + `outlineVariant` 1px border (no shadow — pure black aesthetic).
- Keep existing tracking model (`server.trackedNotifications.values`), persistenceSupported, keepOnReload.

### 6. Osd rewrite

**Rewrite `modules/Osd.qml`:**

Match end-4 OnScreenDisplay quality:
- Split into `OsdValueIndicator` sub-component (capsule with icon + value bar + percentage).
- Support three kinds: `volume`, `brightness`, `microphone`.
- Bigger, more readable: 360×72 capsule (was 320×60).
- Animated value bar with spring-style ease (`OutBack` not OutCubic).
- Mute state: bar greyed, icon `volume_off`, value shows `--`.
- Brightness uses `brightnessctl -m` parsing (already works). Add IPC `osd.microphone` for mic mute via `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`.
- Auto-hide timer 1500ms (unchanged); refreshed on each change.
- Anchored bottom center, 80px margin (above the bar peek zone).

### 7. Launcher rewrite

**Rewrite `modules/Launcher.qml`:**

Match end-4 Overview/SearchBar quality (within minimal scope):
- Centered overlay, 600×480 card.
- Search TextField at top, large font, autofocus.
- Multiple search providers, results unified in one scrollable Repeater:
  - **Apps** (highest priority): `Quickshell.DesktopEntries` matched on `name`, `genericName`, `comment`. Top 8 results.
  - **Math**: if input matches `^[0-9+\-*/().\s]+$`, evaluate with `Function(...)` sandboxed. Show "= result" row.
  - **Commands**: prefix `>` runs raw shell command on Enter (via `Quickshell.execDetached`).
  - **Calculator unit conversion**: skip in v1 (complex, no killer use case).
- Each result row: icon + primary text + secondary text + small "↵" hint on hover.
- Keyboard nav: Up/Down to select, Enter to run, Esc to close.
- IPC handler `launcher` already exists; preserve.

### 8. Power rewrite

**Rewrite `modules/Power.qml`:**

Match end-4 SessionScreen quality:
- Bigger cards (160×160 vs current 128×128), spaced 24px.
- Each card: large icon (48px) + label.
- Animated hover state: scale to 1.04 with 120ms OutCubic, slight border colour shift.
- Add keyboard nav: arrow keys to select, Enter to fire, Esc to close.
- Add confirm step for Reboot/Shutdown: clicking surfaces a second confirmation (small inline button row) instead of firing immediately. Lock/Logout/Suspend fire immediately.
- Keep current actions list and IpcHandler.

### 9. Clipboard rewrite

**Rewrite `modules/Clipboard.qml`:**

Match end-4 Cliphist polish:
- Use `cliphist list` to backfill, but stream incremental via `cliphist watch` (or polling at 1s while open).
- Each entry shows: index (`#N`), truncated content preview, content type icon (image / text / link).
- For image entries, render inline thumbnail (PNG from `cliphist decode <id> | base64`).
- Click entry → `cliphist decode <id> | wl-copy` then close overlay.
- Right-click → delete from cliphist (`cliphist delete <id>`).
- Search filter at top, live filter on text content.
- Keyboard nav same as Launcher.

### 10. EmojiPicker rewrite

**Rewrite `modules/EmojiPicker.qml`:**

Match end-4 Emojis service:
- New `services/Emojis.qml` singleton that loads emoji JSON dataset from `/usr/share/quickshell-emojis/emoji.json` (or vendor minimal subset at `~/.config/quickshell/assets/emoji.json` — TBD: see implementation plan).
- EmojiPicker overlay: search bar + grid of emoji buttons (12 columns), grouped by category (Smileys, People, Animals, Food, Travel, Activity, Objects, Symbols, Flags). Click emoji → `wtype -M Ctrl -P shift+u <hex>` (or simpler: `wl-copy` + paste notification).
- Keyboard nav: typing filters; arrow keys move grid focus.
- Recent emojis stored in `~/.config/quickshell/state/emoji-recents.json` (capped at 24).

---

## Phase 2 — Tier 2 (new)

### 11. Notification history panel

**New file:** `modules/NotificationHistory.qml` — Scope + IpcHandler `notificationHistory` (toggle/open/close) + per-screen PanelWindow overlay. Centered StyledRect (480×600). Lists `server.trackedNotifications.values` filtered for `persistent` (and a separate in-memory log of dismissed-but-recently-seen). Each row: timestamp + app icon + summary + body. Right-click → dismiss. "Clear all" button at top. ESC dismisses panel.

**Modified:**
- `modules/Notifications.qml` (Phase 1 already rewritten) — extend to keep an in-memory ring buffer of last 50 dismissed notifications, expose via `Notifications.history` property used by the history panel.
- `shell.qml` — add `NotificationHistory {}`.
- `hypr/.config/hypr/hyprland.conf` — bind `MOD+N` → `qs ipc call notificationHistory toggle`.

### 12. Updates badge

**New files:**
- `services/Updates.qml` — singleton. Polls `dnf -q check-update` every 30 min (caches result, no auto-refresh in foreground unless explicitly triggered). Exposes `available` (int count), `lastChecked` (date), `checking` (bool). IPC handler `updates.refresh`.

**Modified:**
- `services/qmldir` — add `singleton Updates`.
- `modules/bar/StatusPill.qml` — add a `MaterialIcon "system_update"` + count to the left of the volume icon, visible only when `Updates.available > 0`. Click → opens kitty running `dnf upgrade` (interactive).

### 13. Resources pill (CPU / RAM / GPU / Claude)

**New files:**
- `services/Resources.qml` — singleton. Polls every 2s:
  - CPU: `/proc/stat` delta → percent
  - RAM: `/proc/meminfo` (MemTotal − MemAvailable) → percent
  - GPU (Nvidia): `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits` → util%, mem%
  - Exposes: `cpuPct`, `ramPct`, `gpuUtilPct`, `gpuMemPct`, `nvidiaAvailable` (bool, false if nvidia-smi missing or errors)
- `modules/bar/ResourcesPill.qml` — Pill with Row: CPU icon + %, RAM icon + %, GPU icon + % (if available), Claude session % + week %. Colors ramp from `Theme.text` → `Theme.warning` (>70%) → `Theme.error` (>90%). Hover → expanded tooltip popup with breakdown.

**Modified:**
- `services/qmldir` — add `singleton Resources`.
- `modules/bar/BottomBar.qml` — replace `ClaudePill` with `ResourcesPill` in the same position. Update PeekState watched list.
- `modules/bar/ClaudePill.qml` — **delete** (moved into ResourcesPill).
- `services/ClaudeUsage.qml` — **keep** (Resources reads from it).

---

## File Layout (final state)

```
quickshell/.config/quickshell/
  shell.qml                              # +Cheatsheet, +MediaControls, +NotificationHistory(P2)
  components/                            # unchanged
    Anim.qml CAnim.qml MaterialIcon.qml Theme.qml StyledRect.qml StyledText.qml StateLayer.qml qmldir
  services/
    Audio.qml Battery.qml ClaudeUsage.qml Network.qml Time.qml qmldir   # existing
    MprisService.qml                     # P1 new
    TrayService.qml                      # P1 new
    Bluetooth.qml                        # P1 new
    HyprlandKeybinds.qml                 # P1 new
    Emojis.qml                           # P1 new (for emoji-picker rewrite)
    Updates.qml                          # P2 new
    Resources.qml                        # P2 new
  modules/
    Bar.qml                              # unchanged
    Notifications.qml                    # P1 REWRITE
    Osd.qml                              # P1 REWRITE
    Launcher.qml                         # P1 REWRITE
    Power.qml                            # P1 REWRITE
    Clipboard.qml                        # P1 REWRITE
    EmojiPicker.qml                      # P1 REWRITE
    MediaControls.qml                    # P1 new
    Cheatsheet.qml                       # P1 new
    NotificationHistory.qml              # P2 new
    PassMenu.qml TagInput.qml WindowPicker.qml   # unchanged
    bar/
      Pill.qml PeekState.qml BottomBar.qml LauncherPill.qml WorkspacesPill.qml ClockPill.qml StatusPill.qml   # existing
      MediaPill.qml                      # P1 new
      TrayPill.qml                       # P1 new
      ClaudePill.qml                     # DELETED in P2
      ResourcesPill.qml                  # P2 new (subsumes claude)
```

---

## Hyprland keybinds (additions)

```ini
# Section: Media
bind = , XF86AudioPlay,  exec, qs ipc call mpris playPause
bind = , XF86AudioPause, exec, qs ipc call mpris playPause
bind = , XF86AudioNext,  exec, qs ipc call mpris next
bind = , XF86AudioPrev,  exec, qs ipc call mpris previous
bind = $mainMod, M,      exec, qs ipc call mediaControls toggle

# Section: Quickshell overlays
bind = $mainMod, slash,  exec, qs ipc call cheatsheet toggle
bind = $mainMod, N,      exec, qs ipc call notificationHistory toggle   # Phase 2
```

Existing keybinds get `# Section: <Name>` comments so the cheatsheet groups them sensibly.

---

## Testing checklist

**Per-module smoke tests** (each commit re-loads hot, then verify):
- MPRIS: `mpv ~/some.mp3` → MediaPill appears with title, MOD+M opens popup with art + controls; play/pause/next work; popup closes on Esc/click-outside.
- Tray: launch `slack` → TrayPill shows icon; left-click activates; right-click shows menu.
- Bluetooth: `bluetoothctl power off` → StatusPill BT icon = disabled; click → toggles back on; connect device → icon = `bluetooth_connected`.
- Cheatsheet: MOD+/ opens overlay; categories grouped; search filters; Esc dismisses.
- Notifications: `notify-send 'test' 'body'` → toast slides in from right; hover pauses timer; click action button works; >5 → "+N more".
- Osd: vol keys → bigger capsule with bouncy bar; brightness keys → brightness OSD; mute key → mic OSD.
- Launcher: type "fire" → Firefox top result; "1+1" → "= 2"; "> notify-send hi" → runs.
- Power: MOD+L → overlay; arrow keys nav; Enter on Reboot → confirm step; Lock fires immediately.
- Clipboard: copy text + image; MOD+V opens overlay; image entry shows thumbnail; click → wl-copy.
- EmojiPicker: MOD+. opens grid; search "smile"; click emoji → wl-copy; recents persist.

**Phase 2 smoke tests:**
- Notif history: MOD+N → panel lists dismissed notifs; clear-all works.
- Updates: `dnf check-update` returns N pkgs → badge shows N; click → kitty `dnf upgrade`.
- Resources: pill shows CPU%/RAM%/GPU%/claude%; nvidia-smi missing → GPU section hidden; load `stress -c 8` → CPU% climbs and colour ramps.

---

## Out-of-scope (explicitly skipped)

End-4 modules NOT being ported:
- **Sidebars**: AI Chat, Anime/Booru, Translator (right) — too heavy, doesn't fit minimal aesthetic.
- **Sidebars (right)**: Pomodoro, Todo, NightLight, WifiNetworks, BluetoothDevices full UI — only BT toggle in StatusPill needed.
- **Standalone**: Dock (hyprland workspaces handle it), Overview (hyprctl dispatch overview works), Lock (hyprlock), Polkit (separate daemon), SessionScreen replacement (already covered by Power rewrite), Background (hyprpaper), WallpaperSelector, ScreenCorners, ScreenTranslator, OnScreenKeyboard, Crosshair, FloatingImage, FPS limiter, Recorder.
- **Services**: Ai, Booru, GoogleCloud, LatexRenderer, SongRec, Weather, Todo, TimerService, Translation, Privacy indicator, EasyEffects, SessionWarnings, ConflictKiller, FirstRunExperience, Hyprsunset, HyprlandAntiFlashbangShader, Ydotool, KeyringStorage.
- **Idle** (Tier 2 not picked) — hypridle handles auto-lock already.

---

## Risks

- **Quickshell.Services.SystemTray**: not all tray clients work cleanly on Wayland. Slack, Discord usually fine; some Electron apps poor. Acceptable.
- **Quickshell.Services.Mpris** position polling: requires manual `positionChanged()` ticks — implemented in MediaControls Timer at 1Hz while popup open.
- **Cliphist watch mode**: needs verifying that `cliphist watch` exists in current version. Fallback: 1s polling.
- **Hyprland.conf parsing**: regex-based, may miss exotic bind forms (binde, bindl, bindr). Accept best-effort; user can hand-annotate sections.
- **DesktopEntries icons**: `Quickshell.iconPath()` may return empty for some apps; fall back to generic application icon.
- **Emoji dataset**: vendoring or system path TBD; default plan = vendor a compact JSON at `quickshell/.config/quickshell/assets/emoji.json` checked in.

---

## Out-of-band

- Existing `quickshell-rice-design.md` covered the floating-pills layout & hidden-by-default behavior — still valid. This spec extends it with content.
- Companion ansible role `roles/hyprland/tasks/main.yaml` should add packages `nvidia-utils` (already), `bluez-tools`, `cliphist`, `wtype` if not already pulled by other roles. Verify in implementation plan task.
