#!/usr/bin/env bash
#
# Set up C# in Zed: language server (OmniSharp) + a working debugger.
#
# Zed ships no .NET debug adapter and there is none in the extension registry,
# so debugging goes through netcoredbg (Samsung's DAP-speaking .NET debugger)
# plus a dev extension that registers it as an adapter. This script does every
# part that can be automated:
#
#   1. netcoredbg  -> /usr/local/lib/netcoredbg  (upstream release, newer than
#                     the one the extension would auto-download, so it keeps up
#                     with the .NET 10 runtime)
#   2. rustup      -> ~/.rustup + ~/.cargo, only if missing. Zed compiles dev
#                     extensions to wasm itself and needs a Rust toolchain.
#   3. extension   -> ~/.local/share/zed/dev-extensions/netcoredbg (cloned +
#                     pre-built so Zed's install step is quick)
#
# The last step — "zed: install dev extension" — has no CLI equivalent and has
# to be clicked once in Zed. The script prints exactly what to do.
#
#   ./install-zed-csharp.sh
#
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_not_root

NETCOREDBG_DIR=/usr/local/lib/netcoredbg
EXT_DIR="$HOME/.local/share/zed/dev-extensions/netcoredbg"
EXT_REPO=https://github.com/qwadrox/zed-netcoredbg

command -v zed >/dev/null || { echo "Zed not found — run ./install-app.sh first." >&2; exit 1; }
command -v dotnet >/dev/null || { echo ".NET SDK not found — run ./install-app.sh first." >&2; exit 1; }

# ----------------------------------------------------------------------------
# 1. netcoredbg
# ----------------------------------------------------------------------------
section "netcoredbg (.NET debug adapter)"
install_netcoredbg() {
  case "$(uname -m)" in
    x86_64)  asset="netcoredbg-linux-amd64.tar.gz" ;;
    aarch64) asset="netcoredbg-linux-arm64.tar.gz" ;;
    *) echo "Unsupported architecture: $(uname -m)." >&2; return 1 ;;
  esac

  local tag="" url=""
  read -r tag url < <(
    curl -fsSL "https://api.github.com/repos/Samsung/netcoredbg/releases/latest" |
    python3 -c '
import json, sys
rel = json.load(sys.stdin)
asset = next(a for a in rel["assets"] if a["name"] == sys.argv[1])
print(rel["tag_name"], asset["browser_download_url"])
' "$asset" 2>/dev/null
  ) || true
  [[ -n "${url:-}" ]] || { echo "Could not resolve a netcoredbg download URL." >&2; return 1; }

  if [[ -f "$NETCOREDBG_DIR/.version" ]] && [[ "$(cat "$NETCOREDBG_DIR/.version")" == "$tag" ]]; then
    ok "netcoredbg $tag already installed"
    return 0
  fi

  local tmp; tmp="$(mktemp -d)"
  log "Downloading netcoredbg $tag"
  curl -fL --progress-bar -o "$tmp/n.tar.gz" "$url"
  tar -xzf "$tmp/n.tar.gz" -C "$tmp"
  # Archive unpacks into a single ./netcoredbg/ directory of native binary +
  # managed DLLs — they have to stay together.
  local src; src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"

  sudo rm -rf "$NETCOREDBG_DIR"
  sudo mkdir -p "$(dirname "$NETCOREDBG_DIR")"
  sudo cp -a "$src" "$NETCOREDBG_DIR"
  echo "$tag" | sudo tee "$NETCOREDBG_DIR/.version" >/dev/null
  sudo chmod +x "$NETCOREDBG_DIR/netcoredbg"
  sudo ln -sf "$NETCOREDBG_DIR/netcoredbg" /usr/local/bin/netcoredbg
  rm -rf "$tmp"
  ok "netcoredbg $tag -> $NETCOREDBG_DIR"
}
install_netcoredbg
# pipefail + head closing the pipe would otherwise make this a fatal SIGPIPE.
"$NETCOREDBG_DIR/netcoredbg" --version 2>&1 | head -2 | sed 's/^/    /' || true

# ----------------------------------------------------------------------------
# 2. Rust toolchain (Zed builds dev extensions to wasm with it)
# ----------------------------------------------------------------------------
section "Rust toolchain"
if command -v cargo >/dev/null 2>&1 || [[ -x "$HOME/.cargo/bin/cargo" ]]; then
  ok "cargo already available"
else
  warn "Zed compiles dev extensions itself and needs Rust (~1.5 GB in ~/.rustup + ~/.cargo)."
  log "Installing rustup (user-local; remove later with 'rustup self uninstall')"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
  ok "rustup installed"
fi
export PATH="$HOME/.cargo/bin:$PATH"
# Zed adds this target itself, but doing it here surfaces failures now, not
# behind a spinner in the extension installer.
rustup target add wasm32-wasip2 >/dev/null 2>&1 || warn "could not add wasm32-wasip2 target — Zed will retry on install"
ok "$(rustc --version)"

# rustup ran with --no-modify-path, so putting ~/.cargo/bin on PATH is on us —
# and it has to reach GUI-launched Zed, which never reads .zshrc. Without this
# "install dev extension" dies with "failed to run rustc: No such file".
section "Putting cargo on PATH"
env_file="$HOME/.config/environment.d/60-dev-path.conf"
if [[ -f "$env_file" ]] && grep -q '\.cargo/bin' "$env_file"; then
  ok "environment.d entry already present"
else
  mkdir -p "$(dirname "$env_file")"
  cat > "$env_file" <<'EOF'
# PATH for GUI-launched apps (systemd user session picks this up at login).
PATH=$HOME/.cargo/bin:$PATH
EOF
  ok "wrote ${env_file/#$HOME/\~}"
fi
if grep -q '\.cargo/bin' "$HOME/.zshrc" 2>/dev/null; then
  ok ".zshrc already exports it"
else
  warn ".zshrc has no ~/.cargo/bin entry — deploy this repo's .zshrc (./config-zsh.sh) or add it yourself"
fi
# Apply to the running session so Zed doesn't need a full logout first.
systemctl --user set-environment PATH="$HOME/.cargo/bin:$PATH" 2>/dev/null \
  && ok "running session updated (fully quit + relaunch Zed to pick it up)" \
  || warn "could not update the running session — log out and back in"

# ----------------------------------------------------------------------------
# 3. the dev extension
# ----------------------------------------------------------------------------
section "zed-netcoredbg extension"
if [[ -d "$EXT_DIR/.git" ]]; then
  log "Updating existing checkout"
  git -C "$EXT_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$EXT_DIR")"
  log "Cloning $EXT_REPO"
  git clone --depth 1 "$EXT_REPO" "$EXT_DIR"
fi

log "Pre-building (first build pulls crates; a few minutes)"
if (cd "$EXT_DIR" && cargo build --release --target wasm32-wasip2 >/dev/null 2>&1); then
  ok "extension builds cleanly"
else
  warn "pre-build failed — Zed will still try to build it during install and show the real error"
fi

# ----------------------------------------------------------------------------
# done — the one manual step
# ----------------------------------------------------------------------------
section "One manual step left"
cat <<EOF
Zed has no CLI for installing a dev extension, so do this once:

  1. FULLY QUIT Zed (not just close the window) and start it again — it has to
     be relaunched to inherit the PATH change above, or the install will fail
     with "failed to run rustc: No such file or directory".
  2. Ctrl-Shift-P  ->  "zed: install dev extension"
  3. Pick this directory:

       $EXT_DIR

  4. Ctrl-Shift-P -> "zed: extensions" -> install "C#" (OmniSharp language
     server). config-app.sh already sets auto_install_extensions, so it may
     be there already.

Then open a .NET project and hit F4 (debug: start) — or Ctrl-Shift-P ->
"debugger: start". Per-project configs go in .zed/debug.json; there is a
commented template at ~/.config/zed/debug.json.
EOF
