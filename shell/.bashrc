# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Ensure Wayland-aware clients launched from shells outside the compositor
# (e.g. a lingering TTY or SSH session) can still discover the active sockets.
_uid="$(id -u)"
if [ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$_uid" ]; then
    export XDG_RUNTIME_DIR="/run/user/$_uid"
fi
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    _wayland_sock="$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | head -n1)"
    if [ -n "$_wayland_sock" ]; then
        export WAYLAND_DISPLAY="${_wayland_sock##*/}"
    fi
fi
if [ -z "$SWAYSOCK" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    _sway_sock="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -n1)"
    if [ -n "$_sway_sock" ]; then
        export SWAYSOCK="$_sway_sock"
    fi
fi
unset _uid _wayland_sock _sway_sock

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
