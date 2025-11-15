# Yazi File Dialogs on Fedora Sway

This repo configures Sway + Waybar to use Yazi for every portal-based file
dialog. Follow the steps below from a clean Fedora install to get the same setup.

## 1. Base packages

```sh
sudo dnf upgrade --refresh
sudo dnf install git stow meson ninja gcc make pkg-config scdoc systemd-devel \
                 kitty yazi xdg-desktop-portal xdg-desktop-portal-wlr
```

## 2. Clone + stow these dotfiles

```sh
git clone https://example.com/atqa/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow shell git bin sway waybar xdg
```

This installs the helper scripts (under `~/.local/bin`), Sway config, and
portal config into your home directory.

## 3. Build `xdg-desktop-portal-termfilechooser`

Fedora doesn’t package this backend. Build it once from source:

```sh
git clone https://github.com/GermainZ/xdg-desktop-portal-termfilechooser.git ~/src/termfilechooser
cd ~/src/termfilechooser
meson setup build --prefix=/usr --buildtype=release
meson compile -C build
sudo meson install -C build
systemctl --user daemon-reload
systemctl --user enable --now xdg-desktop-portal-termfilechooser.service
```

## 4. Ensure the wrapper is executable

`bin/.local/bin/yazi-filechooser` ships with these dotfiles. Double-check it’s
on your PATH and has the execute bit:

```sh
chmod +x ~/.local/bin/yazi-filechooser
```

You can override which terminal it launches via `TERMCMD="alacritty -e"` or
change the Yazi binary via `YAZI_BIN=/path/to/yazi`.

## 5. Environment variables inside Sway

`sway/.config/sway/config.d/15-env.conf` exports:

```
setenv GTK_USE_PORTAL 1
setenv XDG_CURRENT_DESKTOP sway
setenv XDG_SESSION_DESKTOP sway
```

Reload Sway (`Mod+Shift+c`) or log out/in so every application sees these vars.

## 6. Restart user portal services

```sh
systemctl --user restart \
  xdg-desktop-portal-wlr.service \
  xdg-desktop-portal.service \
  xdg-desktop-portal-termfilechooser.service
```

This makes `portals.conf` take effect (it prefers the wlroots backend and the
termfilechooser implementation for `org.freedesktop.impl.portal.FileChooser`).

## 7. Test

Launch a Wayland app (e.g., `GTK_USE_PORTAL=1 firefox`) and trigger Open/Save.
You should see your terminal (kitty by default) spawn Yazi:

- Open dialogs: select files/directories and press `<Enter>`.
- Save dialogs: the wrapper creates a placeholder file in the recommended
  directory—move/rename it in Yazi, then open it to confirm.

Quitting without selecting anything cancels the dialog and removes the
placeholder.

Once this works, every GTK/Qt app using portals will automatically get Yazi
file dialogs inside your Sway session.
