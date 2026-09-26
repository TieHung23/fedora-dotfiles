#!/usr/bin/env bash
#
# Point greetd at tuigreet and switch the display manager from GDM (or SDDM)
# to greetd. Install the packages first with ./install-greetd.sh.
#
# Run in a REAL terminal — it needs your sudo password. This only enables
# greetd.service for the *next* boot; it does not kill your current session.
# If the greeter doesn't come up after rebooting, Ctrl+Alt+F3 still gets you
# a text login to switch back (the script prints the exact command).
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_not_root

command -v greetd >/dev/null 2>&1 && command -v tuigreet >/dev/null 2>&1 || {
  echo "greetd/tuigreet not installed. Run ./install-greetd.sh first." >&2; exit 1; }

# The greeter runs as a system user the package creates; its name differs
# between distros/package versions, so look it up rather than hardcode it.
greeter_user=""
for u in greetd greeter; do
  getent passwd "$u" >/dev/null && { greeter_user="$u"; break; }
done
[[ -n "$greeter_user" ]] || { echo "No greetd system user found (expected 'greetd' or 'greeter')." >&2; exit 1; }

section "Configuring tuigreet"
# --remember* keep the last user/session here; it has to be writable by the greeter.
sudo install -d -o "$greeter_user" -g "$greeter_user" -m 0755 /var/cache/tuigreet
if [[ -f /etc/greetd/config.toml ]] && ! sudo grep -q tuigreet /etc/greetd/config.toml; then
  sudo cp -a /etc/greetd/config.toml /etc/greetd/config.toml.orig
fi
# GNOME 50 (Fedora 44+) ships no X11 session, so there may be no xsessions
# dir at all — only hand tuigreet the session dirs that exist.
sessions=""
for d in /usr/share/wayland-sessions /usr/share/xsessions; do
  [[ -d "$d" ]] && sessions="${sessions:+$sessions:}$d"
done
sudo install -d /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --asterisks --remember --remember-user-session --sessions $sessions"
user = "$greeter_user"
TOML
ok "greetd configured (/etc/greetd/config.toml, greeter user: $greeter_user)."

section "Switching the display manager"
current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)" .service)"
if [[ "$current_dm" == "greetd" ]]; then
  ok "greetd is already the active display manager."
else
  log "Current display manager: ${current_dm:-unknown}. Enabling greetd.service for next boot."
  # --force: display-manager.service is already a symlink to the old DM's
  # unit (e.g. gdm.service); enable refuses to clobber it without this.
  sudo systemctl enable --force greetd.service
  ok "greetd.service will take over on next reboot (your current session is untouched)."
fi

echo
if [[ -n "$current_dm" && "$current_dm" != "greetd" ]]; then
  warn "If the greeter doesn't come up after rebooting, press Ctrl+Alt+F3, log in, and run:"
  echo "  sudo systemctl enable --force $current_dm.service && sudo reboot"
  echo
  warn "Keep $current_dm installed — disabled it costs nothing and it's your way back."
  echo "  (On Fedora Workstation, 'dnf remove gdm' can take GNOME packages with it.)"
fi
if [[ -d /usr/share/sddm/themes/silent ]]; then
  warn "Leftovers from the old SilentSDDM setup, safe to delete once greetd works:"
  echo "  sudo rm -rf /usr/share/sddm/themes/silent /etc/sddm.conf.d/silent.conf"
fi
