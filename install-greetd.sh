#!/usr/bin/env bash
#
# Install greetd + tuigreet — a TUI login screen that replaces GDM.
# Activating it (and switching away from GDM) is done separately by
# ./config-greetd.sh — this script only installs packages.
# https://sr.ht/~kennylevinsen/greetd/  https://github.com/apognu/tuigreet
#
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_not_root
ensure_dnf

section "Installing greetd + tuigreet"
# greetd-selinux: the policy module that lets greetd start sessions under
# SELinux enforcing — without it the greeter comes up but logins fail.
pkg_install greetd greetd-selinux tuigreet

ok "Run ./config-greetd.sh to configure tuigreet and switch GDM -> greetd."
