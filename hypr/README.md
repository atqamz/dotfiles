# hypr

Hyprland window manager configuration including lock screen and idle
settings. Stows into `~/.config/hypr/`.

The compositor config is Lua (`hyprland.lua`), required since Hyprland 0.55
retired the hyprlang window-rule matcher grammar. `hypridle.conf` and
`hyprlock.conf` stay hyprlang — they configure separate tools, not the
compositor.

## Per-host config

`hyprland.lua` holds shared settings only. Host-specific fragments (monitor
layout, workspace pinning, touchpad/touchscreen devices, host-only keybinds)
live in `hosts/<hostname>.lua` and are pulled in at the end of `hyprland.lua`
by resolving the live hostname at runtime — no symlink:

```lua
local host = host_name()           -- /etc/hostname, falling back to $HOSTNAME
if host then pcall(require, "hosts." .. host) end
```

Each `require`d file is a separate Lua scope, so a host file re-declares any
locals it needs (e.g. `mainMod`). Resolving by hostname instead of a mutable
`host.lua` symlink means the wrong host's fragment can never be loaded — the
file that runs is always the one named after the running machine.

Supported hostnames:

- `sfx14` — Acer Swift X14 (Intel iGPU + RTX 4050). Built-in eDP-1 driven at
  1920x1200@120 scale 1 (panel native is 2880x1800; integer scale avoids the
  XWayland fractional-upscale blur), optional external DP-1 (Wacom/touch panel)
  and HDMI-A-1.
- `pavg15` — HP Pavilion Gaming 15 (AMD Ryzen + GTX 1650). Built-in eDP-1
  1920x1080.

Adding a new host: drop `hosts/<short-hostname>.lua` — nothing else to wire up.
If no fragment matches the hostname, `require` is skipped with a log line; the
shared core + monitor fallback still load.

## Dependencies

- hyprland
- hyprlock
- hypridle
- hyprpolkitagent
- NVIDIA drivers (if using NVIDIA GPU)
