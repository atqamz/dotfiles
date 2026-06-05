# uwsm

Environment files for [uwsm](https://github.com/Vladimir-csp/uwsm) (Universal
Wayland Session Manager). On hosts where Hyprland is launched under uwsm
(`programs.hyprland.withUWSM = true` on NixOS/pavg15), `uwsm start` sources
these and imports the result into the systemd/dbus activation environment, so
user services and dispatched scripts inherit session env.

- `env` — general session env (NVIDIA offload, PATH, XDG_DATA_DIRS, gpg-agent
  SSH socket). Sourced for any uwsm compositor.
- `env-hyprland` — Hyprland-specific (cursor sizes, workspace-grid geometry).
  Suffix is `XDG_CURRENT_DESKTOP` lowercased.

These intentionally mirror the shared `hl.env(...)` block in
`hypr/.config/hypr/hyprland.lua` (dual, non-breaking): under uwsm `hl.env`
reaches the compositor but not the activation environment, so the env is
duplicated here. On the Fedora host (sfx14), Hyprland launches directly from a
wayland-sessions entry, uwsm never runs, and these files are inert — there
`hl.env` is the sole mechanism.

## Dependencies

- `uwsm` (only effective when Hyprland is started via `uwsm start`; harmless
  otherwise)
- `gnupg` (`gpgconf`, to resolve the gpg-agent SSH socket; the `env` block is
  guarded and skips the export when absent)
