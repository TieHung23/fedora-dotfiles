#!/usr/bin/env bash
#
# Deploy .zshrc (Catppuccin Mocha history/autosuggestions/syntax-highlighting
# rice, reusing the same starship + fastfetch as bash) and make zsh the login
# shell. Install the packages first with ./install-zsh.sh.
#
# Run in a REAL terminal — chsh needs your password.
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

command -v zsh >/dev/null 2>&1 || { echo "zsh not installed. Run ./install-zsh.sh first." >&2; exit 1; }

section "Deploying .zshrc"
deploy "$HERE/.zshrc" "$HOME/.zshrc"

section "Setting zsh as your login shell"
zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$current_shell" == "$zsh_path" ]]; then
  ok "zsh is already your login shell."
else
  chsh -s "$zsh_path"
  ok "Login shell set to $zsh_path — takes effect on your next login."
fi
