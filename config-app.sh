#!/usr/bin/env bash
#
# Deploy terminal + CLI configs from this repo's .config/ into ~/.config
# (copy-with-backup). Existing files are backed up to
# ~/.config-backup/<timestamp>/.
#
# Deploying is a REPLACE, not a merge — anything you edited live but never
# copied back into this repo is overwritten (the backup is your undo). So take
# a group argument: callers that only care about one app don't get to stomp
# everything else.
#
#   ./config-app.sh          # all groups
#   ./config-app.sh terminal # ghostty, btop, fastfetch, starship, lazygit, default-terminal bits
#   ./config-app.sh zed      # Zed settings.json + debug.json only
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

SRC="$HERE/.config"
GROUP="${1:-all}"

TERMINAL_ITEMS=(ghostty btop fastfetch starship.toml lazygit xdg-terminals.list environment.d)
# Zed goes file by file, not as a directory: ~/.config/zed also holds themes/
# and extension state that deploy() would wipe.
ZED_ITEMS=(zed/settings.json zed/debug.json)

deploy_terminal() {
  section "Deploying terminal + CLI configs"
  local item
  for item in "${TERMINAL_ITEMS[@]}"; do
    deploy "$SRC/$item" "$HOME/.config/$item"
  done

  grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" 2>/dev/null || \
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
  grep -qxF 'fastfetch' "$HOME/.bashrc" 2>/dev/null || \
    echo 'fastfetch' >> "$HOME/.bashrc"
}

deploy_zed() {
  section "Deploying Zed configs"
  local item
  for item in "${ZED_ITEMS[@]}"; do
    deploy "$SRC/$item" "$HOME/.config/$item"
  done
}

case "$GROUP" in
  all)      deploy_terminal; deploy_zed ;;
  terminal) deploy_terminal ;;
  zed)      deploy_zed ;;
  *) echo "Unknown group: $GROUP (expected: all | terminal | zed)" >&2; exit 1 ;;
esac

ok "Configs deployed. Backups (if any) in ${DOTFILES_BACKUP/#$HOME/~}."
echo "Open a new shell (or new Ghostty window) to see the prompt + banner."
