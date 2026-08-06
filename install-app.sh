#!/usr/bin/env bash
#
# Install dev CLI tools, Docker (Engine + Desktop), .NET SDK 9.0/10.0, Zed,
# kitty and a Nerd Font. Everything here is idempotent — safe to re-run.
#
#   ./install-app.sh          # everything below
#
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_not_root
ensure_dnf

# Terminal + dev CLI tooling. Comment out what you don't want.
DEV_TOOLS=(
  git gh          # version control + GitHub from the terminal
  lazygit         # TUI for git (COPR)
  ripgrep fd fzf  # fast search / find / fuzzy-finder
  bat eza zoxide  # better cat / ls / cd
  jq
  btop            # system monitor
  fastfetch       # system info banner
  tree unzip wget curl
  kitty           # GPU terminal emulator
  starship        # riced cross-shell prompt (COPR; config in .config/starship.toml)
)

# Language runtimes. Comment out any you don't need.
LANGUAGES=(
  golang    # go toolchain
  nodejs    # includes npm on Fedora
)

# Not installed by default — offered interactively at the end.
SUGGESTED=(
  neovim lazydocker yazi ncdu duf
)

section "Installing dev CLI tools"
pkg_install "${DEV_TOOLS[@]}"

section "Installing language runtimes"
pkg_install "${LANGUAGES[@]}"

section "Docker Engine"
install_docker_engine() {
  if command -v docker >/dev/null 2>&1; then
    ok "Docker Engine already installed"
  else
    log "Adding Docker's official repo"
    [[ -f /etc/yum.repos.d/docker-ce.repo ]] || \
      sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo \
      || sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  sudo systemctl enable --now docker.service
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    warn "Added $USER to the 'docker' group — log out and back in for it to apply."
  fi
  ok "Docker Engine ready"
}
install_docker_engine

section "Docker Desktop"
install_docker_desktop() {
  if rpm -q docker-desktop >/dev/null 2>&1; then
    ok "Docker Desktop already installed"
    return 0
  fi
  warn "GNOME: install the 'AppIndicator and KStatusNotifierItem' Shell extension so the tray icon shows."
  local tmp
  tmp="$(mktemp --suffix=.rpm)"
  log "Downloading Docker Desktop"
  curl -fL -o "$tmp" https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm
  sudo dnf install -y "$tmp"
  rm -f "$tmp"
  ok "Docker Desktop installed — launch it once from the app grid, then: systemctl --user enable --now docker-desktop"
}
install_docker_desktop

section ".NET SDK 9.0 + 10.0"
install_dotnet() {
  local root=/usr/share/dotnet
  local tmp channel
  tmp="$(mktemp)"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$tmp"
  chmod +x "$tmp"
  for channel in 9.0 10.0; do
    if [[ -x "$root/dotnet" ]] && "$root/dotnet" --list-sdks 2>/dev/null | grep -q "^${channel}\."; then
      ok ".NET SDK $channel already installed"
    else
      log "Installing .NET SDK $channel"
      sudo "$tmp" --channel "$channel" --install-dir "$root"
    fi
  done
  rm -f "$tmp"
  if [[ ! -f /etc/profile.d/dotnet.sh ]]; then
    sudo tee /etc/profile.d/dotnet.sh >/dev/null <<EOF
export DOTNET_ROOT=$root
export PATH="\$PATH:$root"
EOF
  fi
  sudo ln -sf "$root/dotnet" /usr/local/bin/dotnet
  ok ".NET SDKs ready (open a new shell for the PATH change)"
}
install_dotnet

section "Zed"
if [[ -x "$HOME/.local/bin/zed" ]]; then
  ok "Zed already installed"
else
  curl -f https://zed.dev/install.sh | sh
fi

section "JetBrainsMono Nerd Font"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
  ok "Nerd Font already installed"
else
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  tmp="$(mktemp -d)"
  curl -fL -o "$tmp/JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq "$tmp/JetBrainsMono.zip" -d "$font_dir"
  rm -rf "$tmp"
  fc-cache -f "$font_dir" >/dev/null
  ok "JetBrainsMono Nerd Font installed"
fi

section "Suggested extras"
echo "Not installed by default — worth a look: ${SUGGESTED[*]}"
echo "  neovim     — editor (pairs with LazyVim-style configs)"
echo "  lazydocker — TUI for Docker (COPR)"
echo "  yazi       — terminal file manager"
echo "  ncdu       — interactive disk usage"
echo "  duf        — friendlier 'df'"
if [[ -t 0 ]]; then
  read -r -p "Install these now? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] && pkg_install "${SUGGESTED[@]}"
fi

ok "Apps installed."
