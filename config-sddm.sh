#!/usr/bin/env bash
#
# Activate the SilentSDDM theme and switch the display manager from GDM to
# SDDM. Install the theme first with ./install-sddm.sh.
#
# Run in a REAL terminal — it needs your sudo password. This only enables
# sddm.service for the *next* boot; it does not kill your current GDM
# session. TEST THE THEME BEFORE REBOOTING — a broken greeter can lock you
# out of the GUI.
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

THEME_DIR="/usr/share/sddm/themes/silent"
[[ -d "$THEME_DIR" ]] || { echo "SilentSDDM not installed ($THEME_DIR missing). Run ./install-sddm.sh first." >&2; exit 1; }

section "Activating the SilentSDDM theme"
sudo install -d /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/silent.conf >/dev/null <<EOF
[Theme]
Current=silent

[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=$THEME_DIR/components/,QT_IM_MODULE=qtvirtualkeyboard
EOF
ok "Theme configured (drop-in at /etc/sddm.conf.d/silent.conf)."

section "Switching the display manager"
current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)" .service)"
if [[ "$current_dm" == "sddm" ]]; then
  ok "SDDM is already the active display manager."
else
  log "Current display manager: ${current_dm:-unknown}. Enabling sddm.service for next boot."
  # --force: display-manager.service is already a symlink to the old DM's
  # unit (e.g. gdm.service); enable refuses to clobber it without this.
  sudo systemctl enable --force sddm.service
  ok "sddm.service will take over on next reboot (your current session is untouched)."
fi

echo
warn "TEST BEFORE REBOOTING — a broken greeter can lock you out of the GUI:"
echo "  cd $THEME_DIR && ./test.sh"
echo
if [[ -n "$current_dm" && "$current_dm" != "sddm" ]]; then
  warn "Once you've rebooted and confirmed SDDM/SilentSDDM works, remove the old DM yourself:"
  echo "  sudo dnf remove $current_dm"
fi
