#!/usr/bin/env bash
#
# Shared helpers for the setup scripts. Source it from the others:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# Not meant to be run directly. Fedora/RHEL only — packages go through dnf,
# enabling COPR where a tool isn't in the main repos.

# ----------------------------------------------------------------------------
# pretty logging
# ----------------------------------------------------------------------------
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
log()  { printf "${BLUE}==>${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}  ✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}  !${RESET} %s\n" "$*"; }
section() { printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ----------------------------------------------------------------------------
# guards
# ----------------------------------------------------------------------------
require_not_root() {
  if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user (not root). It calls sudo when needed." >&2
    exit 1
  fi
}

require_fedora() {
  command -v dnf >/dev/null 2>&1 || { echo "This repo targets Fedora/RHEL (dnf not found)." >&2; exit 1; }
}

ensure_dnf() {
  require_fedora
  dnf copr --help >/dev/null 2>&1 && return 0
  # `dnf copr` lives in dnf5-plugins on dnf5 (Fedora 41+) and in
  # dnf-plugins-core on classic dnf — installing the wrong one is a silent no-op.
  local pkg=dnf-plugins-core
  command -v dnf5 >/dev/null 2>&1 && pkg=dnf5-plugins
  log "Installing $pkg (COPR support)"
  sudo dnf install -y "$pkg"
}

# ----------------------------------------------------------------------------
# package install — dnf, with COPR translation for a few tools
# ----------------------------------------------------------------------------
# token -> copr:REPO|PACKAGE for anything not in the main Fedora repos.
# Tokens absent from the map are passed to dnf unchanged.
declare -A PKG_MAP=(
  [lazygit]="copr:atim/lazygit|lazygit"
  [lazydocker]="copr:atim/lazydocker|lazydocker"
  [starship]="copr:atim/starship|starship"
  [ghostty]="copr:scottames/ghostty|ghostty"
  [yazi]="copr:lihaohong/yazi|yazi"
  [fd]="fd-find"
)

_copr_enabled=""
_copr_enable() {
  local repo="$1"
  case " $_copr_enabled " in *" $repo "*) return 0 ;; esac
  log "Enabling COPR: $repo"
  sudo dnf copr enable -y "$repo"
  _copr_enabled="$_copr_enabled $repo"
}

pkg_install() {
  log "Installing: $*"
  local tok mapped dnf_pkgs=()
  for tok in "$@"; do
    mapped="${PKG_MAP[$tok]-$tok}"
    case "$mapped" in
      copr:*)
        local rest="${mapped#copr:}"
        _copr_enable "${rest%%|*}"
        dnf_pkgs+=("${rest#*|}")
        ;;
      *) dnf_pkgs+=("$mapped") ;;
    esac
  done
  # --skip-unavailable (dnf5) keeps one bad/renamed package from aborting the batch.
  local skipflag=""
  dnf install --help 2>&1 | grep -q -- '--skip-unavailable' && skipflag="--skip-unavailable"
  sudo dnf install -y $skipflag "${dnf_pkgs[@]}"
}

# ----------------------------------------------------------------------------
# flatpak install — user scope
# ----------------------------------------------------------------------------
# Fedora's preinstalled flathub remote is *filtered* (it hides a chunk of the
# catalogue) and system-scoped, so we add our own user remote and install
# there. User scope also means no sudo, and no fighting the system remote.
ensure_flathub() {
  rpm -q flatpak >/dev/null 2>&1 || { log "Installing flatpak"; sudo dnf install -y flatpak; }
  if flatpak remotes --user --columns=name 2>/dev/null | grep -qx flathub; then
    return 0
  fi
  log "Adding the flathub remote (user)"
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# flatpak_install APP_ID... — install from flathub into the user installation.
flatpak_install() {
  ensure_flathub
  local app
  for app in "$@"; do
    if flatpak info --user "$app" >/dev/null 2>&1; then
      ok "$app already installed"
    else
      log "Installing $app"
      flatpak install --user --assumeyes flathub "$app"
    fi
  done
}

# ----------------------------------------------------------------------------
# config deployment (copy with backup)
# ----------------------------------------------------------------------------
# One shared backup dir per run so you can undo a whole apply at once.
: "${DOTFILES_BACKUP:=$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)}"

# deploy SRC DEST — replace DEST (a file or directory) with SRC, backing up
# whatever was there first. DEST becomes an exact copy of SRC.
deploy() {
  local src="$1" dest="$2"
  if [[ ! -e "$src" ]]; then
    warn "missing source: $src (skipped)"; return 0
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    local rel="${dest#"$HOME"/}"
    mkdir -p "$DOTFILES_BACKUP/$(dirname "$rel")"
    cp -a "$dest" "$DOTFILES_BACKUP/$rel"
    rm -rf "$dest"          # so cp doesn't nest a dir inside an existing one
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  ok "deployed ~/${dest#"$HOME"/}"
}
