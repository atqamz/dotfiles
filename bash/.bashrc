# .bashrc

# source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# user specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin/scripts:$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin/scripts:$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# user specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# deno
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
