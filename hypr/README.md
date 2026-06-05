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
live in `hosts/<hostname>.lua` and are pulled in at the end of
`hyprland.lua` via:

```lua
require("host")
```

`host.lua` is a relative symlink to `hosts/$(hostname -s).lua` created by the
top-level `Makefile` after `stow` runs (mirrors the `gnupg/` symlink pattern).
Each `require`d file is a separate Lua scope, so a host file re-declares any
locals it needs (e.g. `mainMod`).

Supported hostnames:

- `sfx14` — Acer Swift X14 (Intel iGPU + RTX 4050). Built-in eDP-1
  1920x1200@120, optional external DP-1 (Wacom/touch panel) and HDMI-A-1.
- `pavg15` — HP Pavilion Gaming 15 (AMD Ryzen + GTX 1650). Built-in eDP-1
  1920x1080.

Adding a new host: drop `hosts/<short-hostname>.lua` and run `make`. If the
hostname has no corresponding fragment, `require("host")` errors on the
dangling symlink; the shared core + monitor fallback still load.

## Dependencies

- hyprland
- hyprlock
- hypridle
- hyprpolkitagent
- NVIDIA drivers (if using NVIDIA GPU)
