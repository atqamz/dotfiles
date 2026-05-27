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

# ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# gpg pinentry tty fallback
export GPG_TTY=$(tty)

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

# gemini api key from pass (graphify-sync, memory-stale-report, ad-hoc graphify extract)
if command -v pass >/dev/null 2>&1; then
    GEMINI_API_KEY="$(pass show dotfiles/api-key/gemini 2>/dev/null)"
    [ -n "$GEMINI_API_KEY" ] && export GEMINI_API_KEY || unset GEMINI_API_KEY
fi

# bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# homebrew env vars (HOMEBREW_PREFIX, MANPATH, ...); PATH precedence fixed below
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# PATH precedence: system (dnf) > homebrew > everything else (node, bun, cargo, go).
# brew shellenv prepends itself; this re-sorts. Idempotent: dedupes on every shell.
__order_path() {
    local brew_bin=/home/linuxbrew/.linuxbrew/bin brew_sbin=/home/linuxbrew/.linuxbrew/sbin
    local sys="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    local rest
    rest="$(printf '%s' "$PATH" | tr ':' '\n' \
        | grep -vxE "/usr/local/sbin|/usr/local/bin|/usr/sbin|/usr/bin|/sbin|/bin|${brew_bin}|${brew_sbin}" \
        | awk 'NF && !seen[$0]++' | paste -sd ':')"
    if [ -x "$brew_bin/brew" ]; then
        export PATH="${sys}:${brew_bin}:${brew_sbin}:${rest}"
    else
        export PATH="${sys}:${rest}"
    fi
}
__order_path
