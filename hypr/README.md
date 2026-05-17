# hypr

Hyprland window manager configuration including lock screen and idle
settings. Stows into `~/.config/hypr/`.

## Per-host config

`hyprland.conf` holds shared settings only. Host-specific fragments
(monitor layout, workspace pinning, touchpad/touchscreen devices, host-only
keybinds) live in `hosts/<hostname>.conf` and are pulled in via:

```
source = ~/.config/hypr/host.conf
```

at the end of `hyprland.conf`. The `host.conf` entry is a relative symlink
to `hosts/$(hostname -s).conf` created by the top-level `Makefile` after
`stow` runs (mirrors the `gnupg/` symlink pattern).

Supported hostnames:

- `sfx14` — Acer Swift X14 (Intel iGPU + RTX 4050). Built-in eDP-1
  1920x1200@120, optional external DP-1 (Wacom/touch panel) and HDMI-A-1.
- `pavg15` — HP Pavilion Gaming 15 (AMD Ryzen + GTX 1650). Built-in eDP-1
  1920x1080.

Adding a new host: drop `hosts/<short-hostname>.conf` and run `make`. If
the hostname has no corresponding fragment, hyprland logs an error sourcing
the dangling `host.conf` symlink but otherwise keeps running on the shared
core + monitor fallback.

## Dependencies

- hyprland
- hyprlock
- hypridle
- hyprpolkitagent
- NVIDIA drivers (if using NVIDIA GPU)
