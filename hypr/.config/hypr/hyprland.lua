-- Hyprland 0.55 Lua config (migrated from hyprland.conf).
-- Shared core. Per-host monitors/workspaces/devices live in hosts/<hostname>.lua,
-- required at EOF via the `host` symlink. Each require()d file is a SEPARATE lua
-- scope (per wiki Start.md), so locals defined here (mainMod, program vars) do NOT
-- cross into host files; host files re-declare what they need.

--------------------
--- FALLBACK MON ---
--------------------

-- Per-host monitor definitions live in hosts/<hostname>.lua (required at EOF).
-- This fallback handles any monitor not explicitly named there.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })


-------------------
--- ENV / APPS  ---
-------------------

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPR_WS_ROWS", "A,B,C,D,E,F,G,H")
hl.env("HYPR_WS_COLS", "10")
hl.env("HYPR_WS_PAIR_OFFSET", "4")
-- $HOME / $XDG_RUNTIME_DIR / $PATH do NOT auto-expand in lua strings; resolve via os.getenv().
hl.env("PATH", os.getenv("HOME") .. "/.local/bin/scripts:" .. os.getenv("HOME") .. "/.local/bin:" .. os.getenv("PATH"))
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/gnupg/S.gpg-agent.ssh")
hl.env("XDG_DATA_DIRS", os.getenv("HOME") .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")

local terminal    = "alacritty"
local fileManager = "nautilus"
local launcher    = "qs ipc call launcher toggle"
local powerMenu   = "qs ipc call session toggle"


-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    hl.exec_cmd("cliphist-watch")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hypr-workspace-pair row 1")
    hl.exec_cmd("hypr-vnc-passthrough")
end)


------------------------
--- LOOK AND BEHAVIOR ---
------------------------

hl.config({
    general = {
        gaps_in                 = 2,
        gaps_out                = 0,
        border_size             = 0,
        resize_on_border        = true,
        extend_border_grab_area = 24,
        allow_tearing           = false,
        layout                  = "dwindle",
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = false,
    },

    misc = {
        background_color        = 0x000000,
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        middle_click_paste      = false,
    },

    ecosystem = {
        no_update_news = true,
    },

    cursor = {
        no_hardware_cursors = 1,
    },

    dwindle = {
        force_split = 2,
    },
})


-------------
--- INPUT ---
-------------

hl.config({
    input = {
        kb_layout     = "us",
        follow_mouse  = 1,
        accel_profile = "flat",
        sensitivity   = 0,

        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
            tap_button_map = "lrm",
            tap_and_drag   = true,
            drag_lock      = 0,
        },

        -- Per-host: touchdevice / tablet output routing lives in hosts/<hostname>.lua.
    },
})

-- Per-host: device {} blocks for host-specific touchpads / touchscreens / tablets
-- live in hosts/<hostname>.lua.

hl.config({
    gestures = {
        workspace_swipe_distance                 = 100,
        workspace_swipe_invert                   = true,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

-- Section: Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs ipc call emoji toggle"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("qs ipc call pass toggle"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("qs ipc call tag toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd("qs ipc call windows toggle"))
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("qs ipc call overview toggle"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("qs ipc call settings toggle"))
hl.bind(mainMod .. " + CTRL + SHIFT + ALT + V", hl.dsp.exec_cmd("cliphist wipe"))

-- Section: System
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs ipc call cheatsheet toggle"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call mediaControls toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notificationHistory toggle"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs ipc call sidebarRight toggle"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("power-profile cycle"))
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("refresh all"))
hl.bind(mainMod .. " + CTRL + ALT + T", hl.dsp.exec_cmd("notification-time"))
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("notification-battery"))
hl.bind(mainMod .. " + CTRL + ALT + W", hl.dsp.exec_cmd("notification-weather"))
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("toggle-touchpad"), { locked = true })
hl.bind("XF86TouchpadOn", hl.dsp.exec_cmd("toggle-touchpad on"), { locked = true })
hl.bind("XF86TouchpadOff", hl.dsp.exec_cmd("toggle-touchpad off"), { locked = true })
hl.bind("Print", hl.dsp.exec_cmd("screenshot"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("screenshot region edit"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("screenshot fullscreen"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("screenshot smart copy"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("screen-record"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("screen-record --with-desktop-audio"))
hl.bind(mainMod .. " + SHIFT + ALT + R", hl.dsp.exec_cmd("screen-record --with-desktop-audio --with-microphone-audio"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("text-extract"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("color-picker"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("toggle-nightlight"))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.exec_cmd("toggle-idle"))
hl.bind(mainMod .. " + CTRL + comma", hl.dsp.exec_cmd("toggle-notifications"))
hl.bind(mainMod .. " + XF86AudioMute", hl.dsp.exec_cmd("audio-switch"))
hl.bind(mainMod .. " + Equal", hl.dsp.exec_cmd("zoom --in"), { repeating = true })
hl.bind(mainMod .. " + Minus", hl.dsp.exec_cmd("zoom --out"), { repeating = true })
hl.bind(mainMod .. " + CTRL + ALT + Z", hl.dsp.exec_cmd("zoom --reset"))
hl.bind(mainMod .. " + Backspace", hl.dsp.exec_cmd("window-transparency-toggle"))
hl.bind(mainMod .. " + SHIFT + Backspace", hl.dsp.exec_cmd("window-gaps-toggle"))
hl.bind(mainMod .. " + SHIFT + ALT + Q", hl.dsp.exec_cmd("window-close-all"))
hl.bind(mainMod .. " + CTRL + Delete", hl.dsp.exec_cmd("monitor-internal toggle"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("monitor-internal off"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("monitor-internal on"), { locked = true })
hl.bind(mainMod .. " + CTRL + SHIFT + Equal", hl.dsp.exec_cmd("monitor-scaling cycle"))

-- Section: Window management
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Q", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Section: Window groups
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.move({ into_group = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ into_group = "r" }))
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.move({ into_group = "u" }))
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.move({ into_group = "d" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.group.prev())   -- changegroupactive b (back)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.group.next())  -- changegroupactive f (forward)

-- Section: Focus
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind("CTRL + ALT + Tab", hl.dsp.focus({ monitor = "+1" }))

-- Section: Swap window
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))

-- Section: Resize window
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Section: Workspace to monitor
hl.bind(mainMod .. " + SHIFT + ALT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))

-- Section: Workspaces
hl.bind(mainMod .. " + 1", hl.dsp.exec_cmd("hypr-workspace-pair goto 1"))
hl.bind(mainMod .. " + 2", hl.dsp.exec_cmd("hypr-workspace-pair goto 2"))
hl.bind(mainMod .. " + 3", hl.dsp.exec_cmd("hypr-workspace-pair goto 3"))
hl.bind(mainMod .. " + 4", hl.dsp.exec_cmd("hypr-workspace-pair goto 4"))
hl.bind(mainMod .. " + 5", hl.dsp.exec_cmd("hypr-workspace-pair goto 5"))
hl.bind(mainMod .. " + 6", hl.dsp.exec_cmd("hypr-workspace-pair goto 6"))
hl.bind(mainMod .. " + 7", hl.dsp.exec_cmd("hypr-workspace-pair goto 7"))
hl.bind(mainMod .. " + 8", hl.dsp.exec_cmd("hypr-workspace-pair goto 8"))
hl.bind(mainMod .. " + 9", hl.dsp.exec_cmd("hypr-workspace-pair goto 9"))
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("hypr-workspace-pair goto 10"))

-- Section: Move to workspace
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.exec_cmd("hypr-workspace-grid move 1"))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.exec_cmd("hypr-workspace-grid move 2"))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd("hypr-workspace-grid move 3"))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.exec_cmd("hypr-workspace-grid move 4"))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.exec_cmd("hypr-workspace-grid move 5"))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.exec_cmd("hypr-workspace-grid move 6"))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.exec_cmd("hypr-workspace-grid move 7"))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.exec_cmd("hypr-workspace-grid move 8"))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.exec_cmd("hypr-workspace-grid move 9"))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.exec_cmd("hypr-workspace-grid move 10"))

-- Section: Workspace rows
hl.bind(mainMod .. " + Tab", hl.dsp.submap("wsrows"))

-- The wsrows submap: each key runs a workspace-pair command, then resets to global.
-- Original used `bindi` (ignore mods) on each entry; preserved as { ignore_mods = true }.
-- Two dispatches per key are combined into one function (exec then submap reset).
hl.define_submap("wsrows", function()
    hl.bind("Tab", function()
        hl.dispatch(hl.dsp.exec_cmd("hypr-workspace-pair cycle"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("1", function()
        hl.dispatch(hl.dsp.exec_cmd("hypr-workspace-pair row 1"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("2", function()
        hl.dispatch(hl.dsp.exec_cmd("hypr-workspace-pair row 2"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("3", function()
        hl.dispatch(hl.dsp.exec_cmd("hypr-workspace-pair row 3"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("4", function()
        hl.dispatch(hl.dsp.exec_cmd("hypr-workspace-pair row 4"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { ignore_mods = true })
    hl.bind("escape", hl.dsp.submap("reset"), { ignore_mods = true })
end)

-- Section: Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize())

-- Section: Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && qs ipc call osd volume"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call osd volume"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume"), { repeating = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd microphone"), { repeating = true, locked = true })

-- Section: Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+ && qs ipc call osd brightness"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%- && qs ipc call osd brightness"), { repeating = true, locked = true })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("keyboard-brightness up"), { repeating = true, locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("keyboard-brightness down"), { repeating = true, locked = true })
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd("keyboard-brightness cycle"), { locked = true })

-- Section: Media
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs ipc call mpris next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs ipc call mpris previous"), { locked = true })

-- Section: VNC passthrough (managed by hypr-vnc-passthrough daemon)
-- Empty submap -- all keys forwarded to focused VNC window.
-- Escape hatch: Ctrl+Alt exits passthrough if daemon dies.
hl.define_submap("passthrough", function()
    hl.bind("CTRL + Alt_L", hl.dsp.submap("reset"))
end)


----------------------------
--- WINDOWS AND WORKSPACES ---
----------------------------

-- Per-host: workspace -> monitor pinning lives in hosts/<hostname>.lua.

-- pinentry: float + keep focused (and center) so GPG prompts grab and hold input.
-- This rule was lost in the hyprlang->0.55 break; re-added here -- the reason for the migration.
hl.window_rule({
    match        = { class = "(pinentry-)(.*)" },
    float        = true,
    stay_focused = true,
    center       = true,
})


-----------------
--- PER-HOST  ---
-----------------

-- Required last so per-host monitors/workspaces/devices override or extend the
-- shared core. `host.lua` is symlinked by `make` to hosts/<hostname>.lua.
require("host")
