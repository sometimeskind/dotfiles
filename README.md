# dotfiles

Personal tooling configuration for Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Each top-level directory is a **Stow package** — a folder whose internal structure mirrors `$HOME`. Running `stow <package>` creates symlinks from `~/` into that package directory.

Example: `zsh/.zshrc` becomes `~/.zshrc` (symlink).

## Makefile

The repo includes a `Makefile` that wraps the verbose `stow --dir=... --target=...` flags:

```bash
make stow              # stow all packages
make stow PKG=zsh      # stow one package
make unstow PKG=zsh    # remove symlinks for one package
make restow            # restow everything (useful after a git pull)
make help              # list all targets
```

All targets accept an optional `PKG=<name>` to act on a single package instead of all of them.

## Brew packages

These are the Homebrew packages assumed by configs in this repo.

| Package | Type | Purpose |
|---|---|---|
| `stow` | formula | required — symlink manager that makes this whole repo work |
| `starship` | formula | shell prompt (`starship/`) |
| `herdr` | formula | agent-aware terminal multiplexer — preferred by `.zshrc` auto-attach when installed |
| `tmux` | formula | terminal multiplexer (`tmux/`) — fallback when herdr is absent |
| `bat` | formula | better `cat` with syntax highlighting (`bat/`) |
| `ghostty` | cask (macOS) | terminal emulator (`ghostty/`) |
| `fzf` | formula | fuzzy finder — Ctrl+R history, Ctrl+T file picker |
| `fd` | formula | faster `find`, used by fzf for file/dir picking |
| `zoxide` | formula | smarter `cd` with frecency tracking (`z`/`zi`) |
| `eza` | formula | better `ls` with icons and git status |
| `1password-cli` | formula | `op` CLI — lazy-loads secrets into shell on start |
| `font-caskaydia-cove-nerd-font` | cask (macOS) | CaskaydiaCove Nerd Font, used by Ghostty config — on Linux install the Cascadia Code Nerd Font from the distro/image instead |

The shell enhancement tools (`fzf`, `fd`, `zoxide`, `eza`) are all optional — `.zshrc` guards each one with `command -v` and degrades gracefully if they are absent.

Also needed for neovim: neovim, rg, lazygit, luarocks, ast-grep, lua

Quick install of everything:

```bash
brew install stow starship herdr tmux bat fzf fd zoxide eza 1password-cli
brew install --cask ghostty font-caskaydia-cove-nerd-font
```

### External (out-of-repo) dependencies

Two things referenced by the `claude` package live outside this repo:

- **`herdr`** — installed via brew (see table above). The `claude/.claude/skills/herdr`
  symlink points at `~/.agents/skills/herdr`, which herdr itself provisions; until it
  exists the symlink dangles (harmless).
- **`moshi-hook`** (`~/.local/bin/moshi-hook`) — machine-local notification helper.
  All hooks that call it are guarded with an existence check, so machines without it
  are unaffected.

## Setup on a new machine

### Linux

```bash
# 1. Install GNU Stow
sudo apt install stow        # Debian/Ubuntu
# sudo pacman -S stow        # Arch
# sudo dnf install stow      # Fedora

# 2. Clone this repo (with submodules — zsh-vim-mode is a submodule)
git clone --recurse-submodules <repo-url> ~/src/dotfiles
cd ~/src/dotfiles

# 3. Install git hooks (runs lint/validation on every commit)
bash scripts/install-hooks.sh

# 4. Stow the packages you want
make stow PKG=zsh
make stow PKG=ghostty
make stow PKG=starship
# ...or all at once:
make stow
```

### Fedora CoreOS (uCore)

Immutable host — layer `zsh` with `rpm-ostree install zsh`, install everything
else with Homebrew-on-Linux, and stow only the headless packages (`zsh`,
`starship`, `bat`, `claude`, `nvim`; skip `tmux` and `ghostty`). The full
bootstrap for the `pilot` box is documented in `homelab/ucore/README.md`.

### macOS

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install GNU Stow
brew install stow

# 3. Clone this repo (with submodules — zsh-vim-mode is a submodule)
git clone --recurse-submodules <repo-url> ~/src/dotfiles
cd ~/src/dotfiles

# 4. Install git hooks
bash scripts/install-hooks.sh

# 5. Stow the packages you want
make stow PKG=zsh
make stow PKG=starship
# ...or all at once:
make stow
```

### Claude Code plugins

After stowing the `claude` package, install these plugins from within Claude Code:

```
/plugin install superpowers
/plugin install context7
/plugin install commit-commands
/plugin install security-guidance
/plugin install claude-md-management
/plugin install pr-review-toolkit
/plugin install claude-code-setup
/plugin install explanatory-output-style
/plugin install plugin-dev
/plugin install greptile
/plugin install hookify
/plugin install skill-creator
/plugin install learning-output-style
```

The `claude` package tracks `settings.json`. The plugin cache and install manifest are machine-local and not tracked.

> **Note:** Configs are portable across machines — no post-stow edits needed:
>
> - `zsh/.zshenv` — detects both Homebrew prefixes (`/opt/homebrew` on macOS, `/home/linuxbrew/.linuxbrew` on Linux) automatically.
> - `claude/.claude/settings.json` — all hook paths are `$HOME`-relative; the `moshi-hook` calls no-op on machines without it.
> - `ghostty`, `starship` — work everywhere as-is.

If a target file already exists (e.g. `~/.zshrc`), Stow will refuse to overwrite it. Back it up first:

```bash
mv ~/.zshrc ~/.zshrc.bak
stow zsh
```

## Adding a new config file

```bash
# Move the real file into the repo under the right package
mkdir -p ~/src/dotfiles/<package>/path/to/
mv ~/path/to/file ~/src/dotfiles/<package>/path/to/file

# Re-stow to create the symlink
make stow PKG=<package>

# Commit
git add <package>/
git commit -m "feat: add <package> config"
```

## Removing a package

```bash
make unstow PKG=<package>    # removes symlinks, leaves real files untouched
```

## Package layout

```
dotfiles/
├── bash/
│   └── .bashrc
├── git/
│   └── .gitconfig
├── zsh/
│   └── .zshrc
└── ...
```

Add new packages following the same pattern.

## Secrets

Never put secrets in dotfiles. Use the [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) to inject secrets at runtime instead of storing them in plaintext files.

```bash
# Fetch a secret inline
export GITHUB_TOKEN=$(op read "op://Private/GitHub PAT/credential")

# Or use op run to inject secrets into a process environment
op run --env-file=.env.tpl -- some-command
```

`.zshrc` loads secrets from 1Password automatically on shell start (requires `op` to be installed and signed in). Avoid using `~/.secrets` for new machines.

## Updating

```bash
cd ~/src/dotfiles
git pull
make restow    # re-stow to pick up any new symlinks
```
