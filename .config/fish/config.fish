# GLOBAL VARS
set -x EDITOR nvim
set -x BROWSER firefox
set -x SXHKD_SHELL /bin/bash

# PATH
set -U fish_user_paths "$HOME/.local/bin:$HOME/.config/polybar/scripts:$HOME/.scripts/bin" $fish_user_paths

# Aliases
## Editors
alias v='nvim'
alias vim='nvim'
alias r='ranger'
alias p='python3'
alias z='zathura'

## Dotfiles
alias fishrc='nvim $HOME/.config/fish/config.fish'
alias rangerrc='nvim $HOME/.config/ranger'
alias vimrc='nvim $HOME/.config/nvim/init.vim'
alias polybarrc='nvim $HOME/.config/polybar/config.ini' 
alias bspwmrc='nvim $HOME/.config/bspwm/bspwmrc'
alias kbinds='nvim $HOME/.config/sxhkd/sxhkdrc'

## Modern rust alternatives
alias ls='exa --icons --oneline'
alias l='exa --icons --header --group-directories-first -s type'
alias la='exa --icons --header --git --group-directories-first -s type --long --git --all'
alias less='bat'
alias find='fd'
alias grep='rg'

## Misc
alias sizeof='du -sh $1'
alias used='df --total block-size=G | grep dev/sd --color=never'
alias myps='watch ps o pid,ppid,stat,comm'
alias findman="man -k . | rofi -dmenu | awk '{print $1}' | xargs -r man -Tpdf | zathura -"
alias calc="bpython -ic 'from math import *;import numpy as np'"
alias cal='cal -m -y'
alias porn='mpv "http://www.pornhub.com/random"'
alias myip='curl http://ipecho.net/plain; echo'

# Setup abbriviations
if not set -q fish_abbreviations_set
    abbr_set
end

# Fish configs
fzf_configure_bindings --directory=\cf --git_log=\cg --git_status --processes=\cp
fish_vi_key_bindings
thefuck --alias | source

# Set theme
theme_gruvbox dark
starship init fish | source
