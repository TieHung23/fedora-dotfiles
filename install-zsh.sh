#!/usr/bin/env bash
#
# Install zsh + zsh-autosuggestions + zsh-syntax-highlighting.
# Deploying .zshrc and switching the login shell is done separately by
# ./config-zsh.sh — this script only installs packages.
#
#   ./install-zsh.sh
#
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_not_root
ensure_dnf

section "Installing zsh + plugins"
pkg_install zsh zsh-autosuggestions zsh-syntax-highlighting

ok "Run ./config-zsh.sh to deploy .zshrc and make zsh your login shell."
