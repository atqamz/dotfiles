# scripts

Custom scripts installed to `~/.local/bin/scripts/`. The parent directory
`~/.local/bin/` is left for installer-managed binaries (claude, uv, etc.) so
they don't land inside the dotfiles repo via stow's tree folding.

Includes clipboard history, screenshot, emoji picker, password menu, Hyprland
workspace helpers, and Waybar status scripts.

## Dependencies

- cliphist
- wl-clipboard (`wl-paste`, `wl-copy`)
- wtype
- grim
- slurp
- hyprpicker
- jq
- satty (optional, screenshot editor)
- rofi-wayland
- rofimoji
- pass
- notify-send (libnotify)
- python3
- nvidia-smi (optional, for GPU status)
- gpu-screen-recorder
- ffmpeg (provides ffprobe)
- v4l2-utils (v4l2-ctl, webcam overlay)
- mpv (open recording from notification)
- tesseract + tesseract-langpack-eng (OCR text extraction)
- hyprsunset (blue light filter)
- hypridle (idle lock daemon)
- pactl (pulseaudio-utils, audio sink enumeration)
- wpctl (wireplumber, audio device control)
- brightnessctl (keyboard backlight control)
- powerprofilesctl (power-profiles-daemon)
- upower (battery info)
- curl (weather data)
