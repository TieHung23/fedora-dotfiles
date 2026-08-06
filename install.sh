#!/usr/bin/env bash
#
# Fedora dev machine setup — one entry point.
#
# Runs the install-*.sh (packages) and config-*.sh (dotfiles) steps in order.
# Every step is also its own script you can run on its own — e.g.
# `./install-app.sh` just to install the apps, or `./config-app.sh` just to
# (re)deploy the terminal configs.
#
# Usage:
#   ./install.sh                 # full setup: install everything, then deploy all configs
#   ./install.sh install         # only the install-* steps (packages)
#   ./install.sh config          # only the config-* steps (deploy dotfiles)
#   ./install.sh apps            # apps only         (install-app.sh)
#   ./install.sh sddm            # install + activate SDDM/SilentSDDM
#   ./install.sh -h | --help
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

run() { section "▶ $1"; "$HERE/$1"; }
usage() { sed -n '2,17p' "$HERE/install.sh" | sed 's/^# \{0,1\}//'; exit 0; }

INSTALL_STEPS=(install-app.sh install-sddm.sh)
CONFIG_STEPS=(config-app.sh config-sddm.sh)

case "${1:-all}" in
  -h|--help) usage ;;
  all)
    ensure_dnf
    for s in "${INSTALL_STEPS[@]}"; do run "$s"; done
    for s in "${CONFIG_STEPS[@]}";  do run "$s"; done
    ;;
  install) ensure_dnf; for s in "${INSTALL_STEPS[@]}"; do run "$s"; done ;;
  config)  for s in "${CONFIG_STEPS[@]}"; do run "$s"; done ;;
  apps)    run install-app.sh ;;
  sddm)    run install-sddm.sh; run config-sddm.sh ;;
  *) echo "Unknown target: $1" >&2; usage ;;
esac

section "All done."
echo "- Log out/in for the 'docker' group to apply."
echo "- Open a new shell (or kitty window) for starship/fastfetch/.NET PATH."
echo "- TEST the SDDM theme (cd /usr/share/sddm/themes/silent && ./test.sh) before rebooting."
