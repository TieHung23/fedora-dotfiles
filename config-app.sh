#!/usr/bin/env bash
#
# Deploy terminal + CLI configs from this repo's .config/ into ~/.config
# (copy-with-backup). Existing files are backed up to
# ~/.config-backup/<timestamp>/.
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

SRC="$HERE/.config"

section "Deploying terminal + CLI configs"
for item in kitty btop fastfetch starship.toml lazygit; do
  deploy "$SRC/$item" "$HOME/.config/$item"
done

grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" 2>/dev/null || \
  echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
grep -qxF 'fastfetch' "$HOME/.bashrc" 2>/dev/null || \
  echo 'fastfetch' >> "$HOME/.bashrc"

ok "Configs deployed. Backups (if any) in ${DOTFILES_BACKUP/#$HOME/~}."
echo "Open a new shell (or new kitty window) to see the prompt + banner."
