# Quickshell Rice — Floating Pills, Opaque Black, Peek-on-Hover

**Date:** 2026-05-18
**Repo:** `atqamz/dotfiles`
**Targets:** `quickshell/.config/quickshell/`
**Supersedes:** Caelestia-style rewrite (master commit `1db76df`), rejected as ugly

## Intent

Replace current vertical-left-dock quickshell shell with floating pills along screen edges. Pure-black opaque pills, no wallpaper-derived color, no glass blur. Hidden by default, peek per-edge on mouse hover. Primary monitor only.

## Locked decisions

| Decision | Value |
|---|---|
| Layout | Floating pills (independent positioned widgets, no unified bar panel) |
| Pill placement | TopBar: launcher (TL), workspaces, claude usage, clock (TR). BottomBar: status (BR). |
| Palette | Pure black `#000` opaque, greyscale text, no accent color. Current `Theme.qml` palette already correct. |
| Monitors | Primary screen only. Multi-monitor: bar suppressed on secondary screens. |
| Visibility | Hidden by default. Per-edge peek-on-hover. Top edge shows top pills; bottom edge shows status pill. Per-edge state. |
| Power button | No visible pill. `MOD+L` → opens existing Power overlay (Lock first card, then Logout/Suspend/Reboot/Shutdown). |
| Overlay scope | Bar rewrite + minimal overlay reskin (root containers only). No new overlays. No overlay layout/behavior changes. |
| Architecture | Approach C: two `PanelWindow` instances per primary screen. TopBar window + BottomBar window. Each owns its own peek state machine. |

## Architecture

### Windows

**TopBar `PanelWindow`**
- `anchors: top=true, left=true, right=true`
- `WlrLayershell.exclusionMode: ExclusionMode.Ignore` (no reserved zone — windows tile full height)
- `WlrLayershell.layer: WlrLayer.Top`
- Height = pill height (28px) + edge slack (8px) = 36px
- Holds: LauncherPill (TL), WorkspacesPill (center-left), ClaudePill (center-right), ClockPill (TR)
- Single peek state shared by all four child pills

**BottomBar `PanelWindow`**
- `anchors: bottom=true, right=true`
- `WlrLayershell.exclusionMode: ExclusionMode.Ignore`
- `WlrLayershell.layer: WlrLayer.Top`
- Width = StatusPill `implicitWidth` + 8px slack; height = 36px (28px pill + 8px edge slack)
- Edge margin (6px gap from screen edge) realised by inner positioning: pill anchored `right=parent.right - 6, bottom=parent.bottom - 6` when Visible
- Holds: StatusPill (BR)
- Independent peek state

### Per-window peek state machine

```
Collapsed (hidden, mask = edge hot-zone strip only)
   └─ HoverHandler enters hot zone ─▶ Peeking
Peeking (sliding in, mask = full window rect)
   └─ slide animation done ─▶ Visible
Visible (pills fully on-screen, mask = union of pill rects)
   └─ HoverHandler exits all pill bounds + dwell timer ─▶ Hiding
Hiding (sliding out, mask = full window rect for tail of anim)
   └─ slide animation done ─▶ Collapsed
```

- Slide: `y` offset (top window) or inverse (bottom window). `-height` → `0`. Duration 200ms (`Theme.anim.durations.normal`), curve `OutCubic` in, `InCubic` out.
- Hot zone: 4px strip anchored to outer edge of window, full window width.
- Dwell on exit: 150ms grace before triggering Hiding (prevents flicker when crossing pill gaps).
- Mask transitions are instant (Quickshell `region` doesn't animate). Mask switches at state boundaries.

### Input mask

`PanelWindow.mask` is computed `Region`:
- **Collapsed:** thin edge strip (full-width × 4px) at outer edge only. Clicks elsewhere pass through to windows beneath.
- **Peeking / Visible / Hiding:** union of pill bounding rectangles. Gaps between pills pass through to windows beneath.

This guarantees no exclusive zone reservation: maximized windows render full-screen, pills float above, clicks pass through gaps.

### Primary screen filter

```qml
Variants {
  model: [Quickshell.primaryScreen]
  // fallback: Quickshell.screens.filter(s => s.name === Quickshell.primaryScreen.name)
}
```

Single instance spawns only on `Quickshell.primaryScreen`. Multi-monitor: secondary screens get nothing.

## File layout

```
quickshell/.config/quickshell/
  shell.qml                                unchanged
  components/
    Theme.qml                              unchanged (palette already correct)
    StyledRect.qml                         unchanged
    StyledText.qml                         unchanged
    MaterialIcon.qml                       unchanged
    StateLayer.qml                         unchanged
    Anim.qml                               unchanged
    CAnim.qml                              unchanged
    qmldir                                 unchanged
  services/
    Time.qml                               unchanged
    Audio.qml                              unchanged
    Network.qml                            unchanged
    Battery.qml                            unchanged
    ClaudeUsage.qml                        NEW — singleton, polls fetch-usage.sh
  modules/
    Bar.qml                                REPLACE — instantiates TopBar + BottomBar on primary
    bar/
      TopBar.qml                           NEW — PanelWindow, peek FSM, holds 4 pills
      BottomBar.qml                        NEW — PanelWindow, peek FSM, holds status pill
      Pill.qml                             NEW — reusable capsule container
      PeekState.qml                        NEW — peek FSM helper component
      LauncherPill.qml                     NEW — Material `apps` glyph, tap → launcher
      WorkspacesPill.qml                   NEW — 5 dots, active expands, urgent warns
      ClockPill.qml                        NEW — HH:MM bold + date variant
      ClaudePill.qml                       NEW — Material `smart_toy` + dual %
      StatusPill.qml                       NEW — vol + wifi + battery glyphs row
      OsIcon.qml                           DELETE
      Workspaces.qml                       DELETE
      Clock.qml                            DELETE
      StatusIcons.qml                      DELETE
      PowerButton.qml                      DELETE
    Launcher.qml                           PATCH — root container reskin only
    Notifications.qml                      PATCH — root container reskin only
    Osd.qml                                PATCH — root container reskin only
    Clipboard.qml                          PATCH — root container reskin only
    Power.qml                              PATCH — root + cards reskin only
    EmojiPicker.qml                        PATCH — root container reskin only
    PassMenu.qml                           PATCH — root container reskin only
    TagInput.qml                           PATCH — root container reskin only
    WindowPicker.qml                       PATCH — root container reskin only
```

External:
```
hypr/.config/hypr/hyprland.conf            PATCH — add `bind = SUPER, L, exec, qs ipc call session toggle`
                                                    (verify existing MOD+L hyprlock binding; swap if conflict)
```

## Component contracts

### `Pill.qml`

```qml
// usage:
// Pill {
//   contentItem: Row { spacing: 8; /* child glyphs / text */ }
//   horizontalPadding: 12   // optional, default 12
// }
//
// fixed from Theme:
//   bg     = Theme.background        (#000)
//   border = Theme.outlineVariant    (#262626), 1px
//   radius = Theme.radius.full       (capsule)
//   height = 28
```

All pills draw identically. Only `contentItem` varies. Implementation: wraps `StyledRect` with computed `implicitWidth = contentItem.implicitWidth + 2 * horizontalPadding`.

### `PeekState.qml`

```qml
// usage:
// PeekState {
//   id: peek
//   hotZoneItem: hotZone       // Item with HoverHandler at edge
//   visibleItems: [pill1, pill2, pill3, pill4]  // for mask region computation
//   slideTarget: contentColumn // QML item to translate during slide
//   slideFromY: -36            // collapsed y offset
//   slideToY: 0                // visible y offset
// }
//
// exposed:
//   property string state  // Collapsed | Peeking | Visible | Hiding
//   property Region mask
```

Encapsulates FSM. TopBar and BottomBar each instantiate one.

### `ClaudeUsage.qml` singleton

```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property real sessionPct: 0
  property real weeklyPct: 0
  property string sessionResetIso: ""
  property string weeklyResetIso: ""
  property string status: "ok"      // ok | warning | critical | error
  property string errorKind: ""     // populated when status == "error"

  function severity(pct) {
    if (pct >= 80) return "critical"
    if (pct >= 50) return "warning"
    return "ok"
  }

  Process {
    id: fetcher
    command: ["bash", "-c", "source \"$HOME/.claude/fetch-usage.sh\"; fetch_usage_data"]
    stdout: SplitParser { onRead: (line) => root._parse(line) }
  }

  function _parse(json) {
    try {
      const d = JSON.parse(json)
      if (d.error) {
        status = "error"; errorKind = d.error
        return
      }
      sessionPct = parseFloat(d.sessionUsage ?? 0)
      weeklyPct = parseFloat(d.weeklyUsage ?? 0)
      sessionResetIso = d.sessionResetAt ?? ""
      weeklyResetIso = d.weeklyResetAt ?? ""
      status = severity(Math.max(sessionPct, weeklyPct))
      errorKind = ""
    } catch (e) {
      status = "error"; errorKind = "parse"
    }
  }

  Timer {
    interval: 600000          // 10 minutes, matches fetch-usage.sh CACHE_MAX_AGE
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: fetcher.running = true
  }
}
```

Re-uses existing `~/.claude/fetch-usage.sh`. No new API calls; shares cache + rate-limit lock with the statusline.

### `ClaudePill.qml`

```
Row inside Pill:
  MaterialIcon { text: "smart_toy"; color: claudeColor; font.pixelSize: 14 }
  StyledText   { text: `${sessionPct.toFixed(0)}%`; color: claudeColor }
  StyledText   { text: `${weeklyPct.toFixed(0)}%`; color: claudeColorWeekly }

where claudeColor = ClaudeUsage.status === "critical" ? Theme.error
                  : ClaudeUsage.status === "warning"  ? Theme.warning
                  : Theme.text
```

Tap: no-op (display only). Hover tooltip: **deferred** — out of scope for this rice. Pill shows only the dual `{sessionPct}% {weeklyPct}%` and severity color. Tooltip infra (if added later) goes in a follow-up.

### `WorkspacesPill.qml`

```
Row inside Pill (5 fixed slots, ids 1..5):
  Repeater {
    model: 5
    StyledRect {
      readonly property int wsId: index + 1
      readonly property var ws: Hyprland.workspaces.find(w => w.id === wsId) ?? null
      readonly property bool active: ws?.active ?? false
      readonly property bool urgent: ws?.urgent ?? false
      width: active ? 28 : 6
      height: 6
      radius: Theme.radius.full
      color: active ? Theme.text : urgent ? Theme.warning : "#444"
      Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      TapHandler { onTapped: Hyprland.dispatch("workspace " + wsId) }
    }
  }
```

Fixed 5 slots regardless of Hyprland's current workspace set — dots always render in same positions. Tapping a slot whose workspace doesn't yet exist dispatches `workspace N` and Hyprland creates it. Pill width is fixed (no reflow when active dot moves between slots).

### `LauncherPill.qml`

```
MaterialIcon { text: "apps"; color: Theme.text; font.pixelSize: 18 }
inside Pill { width = height (square pill, still capsule radius) }
TapHandler { onTapped: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"]) }
```

### `ClockPill.qml`

```
Column inside Pill {
  StyledText { text: Qt.formatDateTime(Time.now, "HH:mm"); font.pixelSize: 14; font.bold: true; color: Theme.text }
}
```

Single line. Date hidden from default view (could surface via tooltip later — out of scope for this rice).

### `StatusPill.qml`

```
Row inside Pill {
  // volume
  MaterialIcon { text: Audio.muted ? "volume_off" : ...; color: Audio.muted ? Theme.textDim : Theme.text }
  TapHandler on volume icon { onTapped: Audio.toggleMute() }

  // wifi
  MaterialIcon { text: Network.connected ? "wifi" : "wifi_off"; color: Network.connected ? Theme.text : Theme.warning }

  // battery (hidden if !Battery.present)
  MaterialIcon { text: <battery_*>; color: <warn for low when not charging> }
  StyledText { text: Battery.percent + ""; visible: Battery.present }
}
```

Existing widget logic preserved; only wrapping changes (Pill instead of column-of-icons).

## Visual spec

### Palette (unchanged from `components/Theme.qml`)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#000000` | Pill bg, overlay root bg |
| `surface` | `#0a0a0a` | reserved (not used in bar) |
| `surfaceContainerLow` | `#101010` | nested cards within overlays |
| `surfaceContainer` | `#141414` | nested cards within overlays |
| `outlineVariant` | `#262626` | Pill border, overlay root border |
| `outline` | `#3a3a3a` | reserved |
| `text` | `#ffffff` | primary text, active workspace dot |
| `textVariant` | `#cccccc` | secondary text, units |
| `textMuted` | `#888888` | tertiary text |
| `textDim` | `#666666` | muted glyphs (muted audio) |
| `primary` | `#ffffff` | same as text (no accent) |
| `warning` | `#ffaa44` | low battery, no-wifi, claude warn |
| `error` | `#ff4444` | claude critical, battery alert |

### Pill metrics

| Property | Value |
|---|---|
| Height | 28px |
| Radius | `Theme.radius.full` (capsule) |
| Horizontal padding | 12px |
| Inner glyph/text gap | 8px |
| Edge margin from screen | 6px |
| Inter-pill horizontal gap | 8px |
| Hot-zone strip thickness | 4px |
| Slide duration | 200ms |
| Slide curve in / out | `OutCubic` / `InCubic` |
| Dwell on exit | 150ms |

### Typography

- All pill text: JetBrains Mono regular
- Clock HH:MM: 14px bold
- Status numbers: 11px
- Claude percentages: 12px
- Icon sizes: launcher 18px, status icons 16px, claude 14px

### Icons

- Material Icons (Fedora-packaged `material-icons-fonts`)
- Launcher pill: `apps` (replaces current `auto_awesome`)
- Claude pill: `smart_toy`
- Status: `volume_up` / `volume_down` / `volume_off` / `volume_mute`, `wifi` / `wifi_off`, battery family
- Workspaces: no glyph (bare StyledRect dots)

## Overlay reskin (root containers only)

Same change applied to each overlay's outermost StyledRect:

```
color:        Theme.background          (was Theme.surface)
border.color: Theme.outlineVariant      (was Theme.outline)
border.width: 1
radius:       Theme.radius.large
```

Internal cards/rows keep `Theme.surfaceContainerLow` / `Theme.surfaceContainer`. No layout, animation, or handler changes.

| File | Touchpoint |
|---|---|
| `Launcher.qml` | Root StyledRect |
| `Notifications.qml` | Per-toast StyledRect |
| `Osd.qml` | Pill container — also change radius to `Theme.radius.full` for capsule consistency |
| `Clipboard.qml` | Root StyledRect + per-row item bg → `surfaceContainerLow` |
| `Power.qml` | Outer StyledRect bg → `background`; card bg stays `surfaceContainer`; hover border → `Theme.text` (no accent) |
| `EmojiPicker.qml` | Root StyledRect |
| `PassMenu.qml` | Root StyledRect |
| `TagInput.qml` | Modal StyledRect |
| `WindowPicker.qml` | Root StyledRect |

## Hyprland integration

Add to `hypr/.config/hypr/hyprland.conf` (or active keybind file):

```
bind = SUPER, L, exec, qs ipc call session toggle
```

Verify and resolve any existing `bind = SUPER, L, exec, hyprlock` — replace with the above. Lock remains available via the Power overlay's leftmost card (which still fires `hyprlock`).

## Testing & verification

No automated test suite (QML/visual). Manual smoke after each commit:

1. Boots clean — no qmllint or runtime errors in `qs` stderr / `qs-test.log`. `Configuration Loaded` visible. Battery warnings on pavg15 expected (no BAT0).
2. Primary monitor only — multi-monitor setup confirms bar suppressed on secondary screens.
3. Peek per-edge — mouse to top edge slides in top 4 pills together; mouse to bottom edge slides in status pill; each fades back independently after dwell.
4. Pill taps — launcher → Launcher overlay; workspace dots → `hyprctl workspace N`; clock/claude no-op; status volume-icon → mute toggle.
5. MOD+L → Power overlay opens with Lock card first.
6. Claude usage — pill populates within 10s of shell start; polls again at 10min interval; severity colors trigger at correct thresholds (force test via mocked JSON or wait for real threshold).
7. Overlay alignment — open each overlay, confirm pure-black root bg, no leftover grey.
8. No exclusive zone — maximize a window, confirm it covers full screen height/width, pills float above.
9. Multi-display gotcha — unplug+replug external monitor, bar respawns only on primary.
10. Side-by-side screenshot vs previous (commit `1db76df`), attach to commit body.

## Out of scope

- Tooltip on claude pill (deferred to follow-up)
- Calendar pop on clock pill
- Quick-settings panel on status pill
- Tray icons (existing quickshell config doesn't have these; not regressing)
- Custom Nerd Font swap (sticking with Material Icons font)
- Animation polish beyond slide (no shimmer, glow, parallax)
- Wallpaper integration
- Multi-monitor support for the bar itself

## Rollback

Single-branch (master) work on dotfiles. If broken, `git revert <commit>` restores prior commit. No long-lived branches needed.
