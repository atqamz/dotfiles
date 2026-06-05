-- sfx14: Acer Swift X14 -- Intel iGPU + RTX 4050
-- Built-in eDP-1, optional external DP-1 (Wacom/touch panel), optional HDMI-A-1.
--
-- This file is require()d from hyprland.lua (via the `host` symlink) and runs in
-- its OWN lua scope: locals from hyprland.lua (mainMod, program vars) do NOT reach
-- here, so anything referenced below is re-declared locally.

local mainMod = "SUPER"

--------------
--- MONITORS ---
--------------

hl.monitor({ output = "eDP-1", mode = "1920x1200@120", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "1920x1200@60", position = "-1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })


-------------
--- INPUT ---
-------------

hl.config({
    input = {
        touchdevice = { output = "DP-1" },
        tablet      = { output = "DP-1" },
    },
})

hl.device({ name = "ilitek-ilitek-tp", output = "DP-1" })
hl.device({ name = "ilitek-ilitek-tp-mouse", output = "DP-1", enabled = true })
hl.device({ name = "syna7db5:00-06cb:ceb1-touchpad", accel_profile = "custom 0.5 0.0 1.0 2.0 3.0" })


--------------------
--- HOST KEYBINDS ---
--------------------

-- Reposition DP-1 left/right of eDP-1.
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd('hyprctl keyword monitor "DP-1,1920x1200@60,-1920x0,1"'))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.exec_cmd('hyprctl keyword monitor "DP-1,1920x1200@60,1920x0,1"'))

-- VNC into pavg15.
hl.bind(mainMod .. " + CTRL + ALT + 0", hl.dsp.exec_cmd("vnc-pavg15"))


----------------
--- WORKSPACES ---
----------------

-- Workspace grid mapping: A-D -> eDP-1, E-H -> DP-1.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default_name = "A1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", default_name = "A2" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", default_name = "A3" })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", default_name = "A4" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", default_name = "A5" })
hl.workspace_rule({ workspace = "6", monitor = "eDP-1", default_name = "A6" })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1", default_name = "A7" })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", default_name = "A8" })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", default_name = "A9" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1", default_name = "A10" })
hl.workspace_rule({ workspace = "11", monitor = "eDP-1", default_name = "B1" })
hl.workspace_rule({ workspace = "12", monitor = "eDP-1", default_name = "B2" })
hl.workspace_rule({ workspace = "13", monitor = "eDP-1", default_name = "B3" })
hl.workspace_rule({ workspace = "14", monitor = "eDP-1", default_name = "B4" })
hl.workspace_rule({ workspace = "15", monitor = "eDP-1", default_name = "B5" })
hl.workspace_rule({ workspace = "16", monitor = "eDP-1", default_name = "B6" })
hl.workspace_rule({ workspace = "17", monitor = "eDP-1", default_name = "B7" })
hl.workspace_rule({ workspace = "18", monitor = "eDP-1", default_name = "B8" })
hl.workspace_rule({ workspace = "19", monitor = "eDP-1", default_name = "B9" })
hl.workspace_rule({ workspace = "20", monitor = "eDP-1", default_name = "B10" })
hl.workspace_rule({ workspace = "21", monitor = "eDP-1", default_name = "C1" })
hl.workspace_rule({ workspace = "22", monitor = "eDP-1", default_name = "C2" })
hl.workspace_rule({ workspace = "23", monitor = "eDP-1", default_name = "C3" })
hl.workspace_rule({ workspace = "24", monitor = "eDP-1", default_name = "C4" })
hl.workspace_rule({ workspace = "25", monitor = "eDP-1", default_name = "C5" })
hl.workspace_rule({ workspace = "26", monitor = "eDP-1", default_name = "C6" })
hl.workspace_rule({ workspace = "27", monitor = "eDP-1", default_name = "C7" })
hl.workspace_rule({ workspace = "28", monitor = "eDP-1", default_name = "C8" })
hl.workspace_rule({ workspace = "29", monitor = "eDP-1", default_name = "C9" })
hl.workspace_rule({ workspace = "30", monitor = "eDP-1", default_name = "C10" })
hl.workspace_rule({ workspace = "31", monitor = "eDP-1", default_name = "D1" })
hl.workspace_rule({ workspace = "32", monitor = "eDP-1", default_name = "D2" })
hl.workspace_rule({ workspace = "33", monitor = "eDP-1", default_name = "D3" })
hl.workspace_rule({ workspace = "34", monitor = "eDP-1", default_name = "D4" })
hl.workspace_rule({ workspace = "35", monitor = "eDP-1", default_name = "D5" })
hl.workspace_rule({ workspace = "36", monitor = "eDP-1", default_name = "D6" })
hl.workspace_rule({ workspace = "37", monitor = "eDP-1", default_name = "D7" })
hl.workspace_rule({ workspace = "38", monitor = "eDP-1", default_name = "D8" })
hl.workspace_rule({ workspace = "39", monitor = "eDP-1", default_name = "D9" })
hl.workspace_rule({ workspace = "40", monitor = "eDP-1", default_name = "D10" })
hl.workspace_rule({ workspace = "41", monitor = "DP-1", default_name = "E1", default = true })
hl.workspace_rule({ workspace = "42", monitor = "DP-1", default_name = "E2" })
hl.workspace_rule({ workspace = "43", monitor = "DP-1", default_name = "E3" })
hl.workspace_rule({ workspace = "44", monitor = "DP-1", default_name = "E4" })
hl.workspace_rule({ workspace = "45", monitor = "DP-1", default_name = "E5" })
hl.workspace_rule({ workspace = "46", monitor = "DP-1", default_name = "E6" })
hl.workspace_rule({ workspace = "47", monitor = "DP-1", default_name = "E7" })
hl.workspace_rule({ workspace = "48", monitor = "DP-1", default_name = "E8" })
hl.workspace_rule({ workspace = "49", monitor = "DP-1", default_name = "E9" })
hl.workspace_rule({ workspace = "50", monitor = "DP-1", default_name = "E10" })
hl.workspace_rule({ workspace = "51", monitor = "DP-1", default_name = "F1" })
hl.workspace_rule({ workspace = "52", monitor = "DP-1", default_name = "F2" })
hl.workspace_rule({ workspace = "53", monitor = "DP-1", default_name = "F3" })
hl.workspace_rule({ workspace = "54", monitor = "DP-1", default_name = "F4" })
hl.workspace_rule({ workspace = "55", monitor = "DP-1", default_name = "F5" })
hl.workspace_rule({ workspace = "56", monitor = "DP-1", default_name = "F6" })
hl.workspace_rule({ workspace = "57", monitor = "DP-1", default_name = "F7" })
hl.workspace_rule({ workspace = "58", monitor = "DP-1", default_name = "F8" })
hl.workspace_rule({ workspace = "59", monitor = "DP-1", default_name = "F9" })
hl.workspace_rule({ workspace = "60", monitor = "DP-1", default_name = "F10" })
hl.workspace_rule({ workspace = "61", monitor = "DP-1", default_name = "G1" })
hl.workspace_rule({ workspace = "62", monitor = "DP-1", default_name = "G2" })
hl.workspace_rule({ workspace = "63", monitor = "DP-1", default_name = "G3" })
hl.workspace_rule({ workspace = "64", monitor = "DP-1", default_name = "G4" })
hl.workspace_rule({ workspace = "65", monitor = "DP-1", default_name = "G5" })
hl.workspace_rule({ workspace = "66", monitor = "DP-1", default_name = "G6" })
hl.workspace_rule({ workspace = "67", monitor = "DP-1", default_name = "G7" })
hl.workspace_rule({ workspace = "68", monitor = "DP-1", default_name = "G8" })
hl.workspace_rule({ workspace = "69", monitor = "DP-1", default_name = "G9" })
hl.workspace_rule({ workspace = "70", monitor = "DP-1", default_name = "G10" })
hl.workspace_rule({ workspace = "71", monitor = "DP-1", default_name = "H1" })
hl.workspace_rule({ workspace = "72", monitor = "DP-1", default_name = "H2" })
hl.workspace_rule({ workspace = "73", monitor = "DP-1", default_name = "H3" })
hl.workspace_rule({ workspace = "74", monitor = "DP-1", default_name = "H4" })
hl.workspace_rule({ workspace = "75", monitor = "DP-1", default_name = "H5" })
hl.workspace_rule({ workspace = "76", monitor = "DP-1", default_name = "H6" })
hl.workspace_rule({ workspace = "77", monitor = "DP-1", default_name = "H7" })
hl.workspace_rule({ workspace = "78", monitor = "DP-1", default_name = "H8" })
hl.workspace_rule({ workspace = "79", monitor = "DP-1", default_name = "H9" })
hl.workspace_rule({ workspace = "80", monitor = "DP-1", default_name = "H10" })
