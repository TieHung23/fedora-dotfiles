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
# Rust (rustup installs with --no-modify-path, so PATH is ours to set).
# GUI apps get this from .config/environment.d/60-dev-path.conf instead.
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
# User-local binaries — Zed's installer and the Claude Code CLI both land here.
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
# ls -> eza, same set CachyOS ships in its shell config. --icons needs the Nerd
# Font from install-app.sh; it degrades to no icons rather than breaking without.
# Guarded so a box without eza still gets a working ls.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -al --color=always --group-directories-first --icons'  # preferred listing
  alias la='eza -a --color=always --group-directories-first --icons'   # all files and dirs
  alias ll='eza -l --color=always --group-directories-first --icons'   # long format
  alias lt='eza -aT --color=always --group-directories-first --icons'  # tree listing
  alias l.="eza -a | grep -E '^\.'"                                    # dotfiles only
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
fi
alias grep='grep --color=auto'

eval "$(starship init zsh)"
fastfetch
