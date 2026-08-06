# ~/.zshrc — Catppuccin Mocha rice

# --- history ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# --- completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- keybindings ---
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# --- plugins ---
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Catppuccin Mocha colors for autosuggestions (subtext0, dim)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6C7086"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Catppuccin Mocha colors for syntax highlighting
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#CDD6F4'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F38BA8'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#CBA6F7'
ZSH_HIGHLIGHT_STYLES[command]='fg=#89B4FA'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#89B4FA'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#89B4FA'
ZSH_HIGHLIGHT_STYLES[function]='fg=#89B4FA'
ZSH_HIGHLIGHT_STYLES[path]='fg=#94E2D5,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#A6E3A1'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#A6E3A1'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6C7086,italic'

# --- misc ---
export EDITOR=vim
export TERMINAL=kitty
alias ls='ls --color=auto'
alias ll='ls -alF'
alias grep='grep --color=auto'

eval "$(starship init zsh)"
fastfetch
