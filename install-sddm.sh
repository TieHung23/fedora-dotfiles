#!/usr/bin/env bash
#
# Install SDDM + its Qt6 deps, and the SilentSDDM login theme.
# Activating it (and switching away from GDM) is done separately by
# ./config-sddm.sh — this script only installs packages/files.
# https://github.com/uiriansan/SilentSDDM
#
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_not_root
ensure_dnf

section "Installing SDDM + Qt6 deps"
pkg_install sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia qt6-qtimageformats git

THEME_DIR="/usr/share/sddm/themes/silent"
if [[ -d "$THEME_DIR" ]]; then
  ok "SilentSDDM theme already present at $THEME_DIR"
else
  section "Installing the SilentSDDM theme"
  tmp="$(mktemp -d)"
  git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM "$tmp/SilentSDDM"
  sudo mkdir -p "$THEME_DIR"
  sudo cp -rf "$tmp/SilentSDDM/." "$THEME_DIR/"
  sudo cp -r "$THEME_DIR"/fonts/* /usr/share/fonts/ 2>/dev/null || true
  rm -rf "$tmp"
  ok "SilentSDDM installed to $THEME_DIR"
fi

ok "Run ./config-sddm.sh to activate the theme and switch GDM -> SDDM."
