if command -v gpgconf &> /dev/null
    set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpg-connect-agent updatestartuptty /bye &> /dev/null
end

set -l ninerouter_key /run/secrets/ninerouter-api-key
test -r "$ninerouter_key" && set -gx NINEROUTER_API_KEY (string trim < "$ninerouter_key")

if status is-interactive
    command -v starship &> /dev/null && starship init fish | source

    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source
    command -v mise &> /dev/null && mise activate fish | source

    command -v eza &> /dev/null && alias ls='eza --icons --group-directories-first -1'

    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    set -q XDG_CONFIG_HOME && set -l cConf $XDG_CONFIG_HOME/caelestia || set -l cConf $HOME/.config/caelestia
    source $cConf/user-config.fish 2> /dev/null
end
