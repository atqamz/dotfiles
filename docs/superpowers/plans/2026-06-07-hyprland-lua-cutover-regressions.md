# Hyprland lua-cutover regression sweep

Context: the hyprlang → lua config cutover (commit `f5b5a3c`, activated 2026-06-06)
silently broke every shell/QML consumer that used the old hyprlang interfaces.
Two fix passes already landed:

- `7dc7a97` — ported classic `hyprctl dispatch <verb>` calls to `hl.dsp.*` lua
  shorthand (workspace nav scripts, hypridle).
- `1124961` — `hyprctl keyword` also breaks under lua ("non-legacy parsers, use
  eval"); ported `monitor-scaling`, `monitor-internal`, and the `sfx14.lua` DP-1
  reposition binds to `hyprctl dispatch 'hl.monitor({...})'`. Also fixed the
  sfx14 panel modes (eDP-1 2880x1800@120 @1.5, DP-1 2240x1400@60 @1.25).
- `dce76ba` — removed all VNC (server passthrough + viewer).

This spec covers the regressions still unfixed. Background reference for the
mechanism and the exact lua mappings: `reference_hyprland_055_lua.md` in the
project memory.

## The core mechanism (reuse for every item)

Under the lua provider:

- `hyprctl keyword <kw> <val>` is rejected outright.
- `hyprctl dispatch <verb> <args>` is parsed AS LUA: it wraps to
  `hl.dispatch(<verb> <args>)`, so classic verbs (`workspace 2`, `exit`) fail.

Runtime config/dispatch must go through a lua eval: `hyprctl dispatch '<lua>'`.
The eval runs as a SIDE EFFECT, then the dispatcher wrapper prints a harmless
`error: ... hl.dispatch: expected a dispatcher` line to **stdout** (not stderr)
— the change still applies. Swallow it with `>/dev/null 2>&1 || true`.

Keyword → lua setter map (all verified live 2026-06-07):

| classic | lua eval |
|---|---|
| `keyword monitor "X,WxH@R,pos,S"` | `hl.monitor({output="X",mode="WxH@R",position="pos",scale=S})` |
| `keyword monitor "X,disable"` | `hl.monitor({output="X",disabled=true})` |
| `keyword general:gaps_in N` | `hl.config({general={gaps_in=N}})` |
| `keyword "device[NAME]:enabled" BOOL` | `hl.device({name="NAME",enabled=BOOL})` |
| `keyword cursor:zoom_factor V` | `hl.config({cursor={zoom_factor=V}})` |
| `dispatch exit` | `hl.dsp.exit()` |

`hl.dsp.exit` confirmed a function. `hl` runtime setters: `monitor`, `config`,
`device` (plus `get_monitors`/`get_monitor`/`get_config` readers).

---

## Item 1 — port remaining `hyprctl keyword` scripts

Same bug as `1124961`, four scripts still broken (every call silently no-ops):

- `scripts/.local/bin/scripts/zoom:32` — `cursor:zoom_factor`
- `scripts/.local/bin/scripts/toggle-touchpad:20,26` — `device[..]:enabled`
- `scripts/.local/bin/scripts/toggle-touchscreen:20,26` — `device[..]:enabled`
- `scripts/.local/bin/scripts/window-gaps-toggle:16,26` — `general:gaps_in`

Fix: convert each to `hyprctl dispatch '<lua>'` per the map above, building the
lua string with `printf` for variable interpolation, and `>/dev/null 2>&1 || true`.
Follow the helper pattern already in `monitor-internal` (`mon_eval()`) /
`monitor-scaling` (`apply_scale()`).

Note for `window-gaps-toggle`: under 0.55 `gaps_in` is now a CSS-style gap
(`hyprctl getoption general:gaps_in` shows `css gap data: 5 5 5 5`). Confirm the
save/restore logic reads the value correctly post-port; `hl.config({general={gaps_in=N}})`
with a single int applied cleanly in testing (5→13→5).

Verify each: run the script, confirm the property changed via `hyprctl getoption`
/ `hyprctl devices` / `hyprctl monitors`.

## Item 2 — fix the keybind cheatsheet (mod+/)

Symptom: `SUPER + slash` (`hyprland.lua:167`, `qs ipc call cheatsheet toggle`)
opens an empty cheatsheet. Empty-state text even says "add # Section: headers to
hyprland.conf".

Root cause: `quickshell/.config/quickshell/services/HyprlandKeybinds.qml`
- line 22 hardcodes `~/.config/hypr/hyprland.conf` — gone (lua now), at most a
  regenerated stub.
- `bindRe` (line 36) matches old hyprlang `bind[lemi]* = mods, key, action` —
  never matches `hl.bind(...)`.

Fix (rewrite the parser for lua):

1. Source files: parse BOTH `~/.config/hypr/hyprland.lua` and the active host
   file `~/.config/hypr/host.lua` (symlink → `hosts/<hostname>.lua`). Host files
   add binds (e.g. sfx14 reposition binds). A `FileView` per file, or read both
   and concatenate.
2. Bind regex: match `hl.bind("<keyspec>", <action>)`. Keyspec examples:
   `mainMod .. " + slash"`, `mainMod .. " + SHIFT + Q"`, `"XF86AudioPlay"`,
   `"switch:on:Lid Switch"`. Must resolve the `mainMod` local (`= "SUPER"`,
   declared in each file's own scope — see line ~34 of hyprland.lua and line 8
   of sfx14.lua). Strip the `mainMod ..` prefix and string-concat to a readable
   `SUPER + SHIFT + Q`.
3. Action: pull a human label from the second arg — `hl.dsp.exec_cmd("...")`,
   `hl.dsp.exec("...")`, `hl.dsp.focus{...}`, `hl.dsp.window.move{...}`, submaps,
   etc. At minimum show the inner string for exec/exec_cmd; map common
   dispatchers to readable verbs.
4. Section headers: lua keeps `-- Section: X` comments (preserved through the
   migration — confirmed present in hyprland.lua, ~17 sections). Update
   `sectionRe` to accept `--` as well as `#` comment leaders
   (`/^\s*(?:#+|--+)\s*Section:\s*(.+?)\s*#*\s*$/`).
5. Update the empty-state copy at `Cheatsheet.qml:226` to reference
   `hyprland.lua` and `-- Section:` headers.

Decision needed: parse the lua source (rich: section grouping + readable
actions, but a bespoke parser) vs. `hyprctl binds -j` (provider-agnostic,
structured, but no section grouping and actions are raw dispatcher form). Source
parsing preferred to keep the section-grouped UX; `hyprctl binds -j` is the
fallback if lua parsing proves brittle.

Verify: mod+/ shows all sections with binds; host-specific binds appear; the
search filter (Cheatsheet.qml:19-22) still works.

## Item 3 — fix logout fallback

`scripts/.local/bin/scripts/session-logout:17` runs `exec hyprctl dispatch exit`
as the non-uwsm path (sfx14 launches Hyprland directly, no uwsm → this branch is
the one that fires). Broken under lua: `hl.dispatch(exit)` errors (`exit` is nil).
So logout does nothing on sfx14.

Fix: `exec hyprctl dispatch 'hl.dsp.exit()'`. Keep the `uwsm stop` branch as-is.

Verify: trigger logout (Power.qml → Logout, or run `session-logout`) on a host
without uwsm — Hyprland should exit.

## Item 4 — monitor-internal lid-resume scale

`scripts/.local/bin/scripts/monitor-internal` `on()` reapplies the internal
panel with a hardcoded `scale=1` (faithful port of the old behavior). On sfx14
eDP-1 wants scale 1.5, so reopening the lid brings the panel back at the wrong
scale (1.0, tiny). The script is host-agnostic and can't know the per-host scale.

Options:
- Read the configured scale before disabling and restore it on re-enable
  (needs to persist across separate script invocations — use the `toggle` state
  store that already tracks `internal-monitor-off`).
- Or have `on()` re-trigger the host config rule for the internal output instead
  of forcing mode/scale (if the lua provider exposes a "reapply config" path).
- Simplest acceptable: store the pre-disable `scale` (from `hyprctl monitors -j`)
  in the toggle state and feed it back on enable.

Verify on sfx14: lid close → eDP-1 off; lid open → eDP-1 back at scale 1.5,
1920x1200 logical (no pillbox).

## Item 5 — verify `hyprctl setprop` (low priority)

`scripts/.local/bin/scripts/window-transparency-toggle:12` uses
`hyprctl setprop "address:$addr" opaque toggle`. `setprop` is a distinct IPC
command (not `keyword`/`dispatch`), so it likely still works under the lua
provider — but it was never tested post-cutover. Confirm it toggles opacity; if
broken, find the lua equivalent (`hl` window-prop setter or
`hl.dsp.setprop`-style).

---

## Out of scope / confirmed fine

Read-only / non-parsed `hyprctl` subcommands work under lua and need no change:
`monitors`, `clients`, `devices`, `getoption`, `activeworkspace`, `activewindow`,
`reload`, `hyprsunset`. The `7dc7a97` dispatch ports and the `1124961` keyword
ports are done. VNC is fully removed (`dce76ba`).
