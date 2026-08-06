# Fedora dev machine setup

Bash setup scripts + tracked dotfiles for provisioning a **Fedora** developer
machine: Docker (Engine + Desktop), .NET SDK 9.0/10.0, Zed, dev CLI tooling,
a **kitty** terminal rice (Catppuccin Mocha + JetBrainsMono Nerd Font +
starship + fastfetch), and a **SilentSDDM** login screen in place of GDM.

No build system, test suite, or CI — scripts run directly and are written to
be idempotent (safe to re-run). Packages come from **`dnf`**, enabling
**COPR** for the handful of tools not in the main Fedora repos
(`lazygit`, `lazydocker`, `starship`).

## Quick start

```bash
chmod +x *.sh
./install.sh            # install everything, then deploy all configs
```

Prefer to run a piece at a time? Every step is its own script:

```bash
./install.sh install    # only the install-*.sh steps (packages)
./install.sh config     # only the config-*.sh steps (deploy dotfiles)
./install.sh apps       # just the apps            (install-app.sh)
./install.sh sddm       # install + activate SDDM/SilentSDDM
./install.sh --help
```

## How it's organised

| Script | What it does |
|---|---|
| `install.sh` | Entry point / orchestrator. Runs the steps below in order. |
| `lib.sh` | Shared helpers — sourced by the others, not run directly. |
| `install-app.sh` | Dev CLI tools, Docker Engine + Desktop, .NET SDK 9.0/10.0, Zed, kitty, a Nerd Font. Offers a few more tools interactively at the end. |
| `install-sddm.sh` | SDDM + its Qt6 deps + the SilentSDDM theme files. |
| `config-app.sh` | Deploys the kitty/btop/fastfetch/starship/lazygit configs from `.config/`. |
| `config-sddm.sh` | Activates the SilentSDDM theme and switches the display manager from GDM to SDDM. |

`lib.sh` provides `log`/`ok`/`warn`/`section` logging, `require_not_root`,
`ensure_dnf`, `pkg_install` (dnf wrapper with COPR translation), and
`deploy SRC DEST` (copies a config into place, backing up whatever was
there to `~/.config-backup/<timestamp>/`).

## What gets installed

- **Docker Engine** — official `docker-ce` repo; you're added to the `docker`
  group (log out/in to use `docker` without `sudo`).
- **Docker Desktop** — official RPM, runs alongside Engine in its own context.
- **.NET SDK 9.0 + 10.0** — side by side via `dotnet-install.sh` into
  `/usr/share/dotnet` (Microsoft's supported way to keep multiple SDKs
  installed together).
- **Zed** — official non-Flatpak installer, user-local (`~/.local/bin/zed`).
- **kitty** — terminal, themed Catppuccin Mocha, JetBrainsMono Nerd Font,
  starship prompt, fastfetch banner on shell start.
- **SilentSDDM** — cloned from
  [uiriansan/SilentSDDM](https://github.com/uiriansan/SilentSDDM), installed
  to `/usr/share/sddm/themes/silent`.
- Dev CLI tools: `git`, `gh`, `lazygit`, `ripgrep`, `fd`, `fzf`, `bat`, `eza`,
  `zoxide`, `jq`, `btop`, `fastfetch`, `starship`.
- Language runtimes: **Go** (`golang`), **Node.js** (`nodejs`, npm included).
- Suggested (opt-in prompt at the end of `install-app.sh`): `neovim`,
  `lazydocker`, `yazi`, `ncdu`, `duf`.

## Notes

- **Docker:** log out/in before running `docker` without `sudo`.
- **SDDM:** `config-sddm.sh` only *enables* `sddm.service` for the next boot —
  it never kills your current GDM session. **Test before rebooting**, a
  broken greeter can lock you out of the GUI:
  `cd /usr/share/sddm/themes/silent && ./test.sh`. Once you've confirmed it
  works, remove the old display manager yourself (the script tells you the
  exact command, e.g. `sudo dnf remove gdm`).
- To update the repo after tweaking a config live, copy it back into
  `.config/` and commit.
