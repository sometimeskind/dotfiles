# dotfiles

Personal tooling configuration for Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Each top-level directory is a **Stow package** — a folder whose internal structure mirrors `$HOME`. Running `stow <package>` creates symlinks from `~/` into that package directory.

Example: `zsh/.zshrc` becomes `~/.zshrc` (symlink).

## Makefile

The repo includes a `Makefile` that wraps the verbose `stow --dir=... --target=...` flags:

```bash
make stow              # stow all packages
make stow PKG=music    # stow one package
make unstow PKG=zsh    # remove symlinks for one package
make restow            # restow everything (useful after a git pull)
make help              # list all targets
```

All targets accept an optional `PKG=<name>` to act on a single package instead of all of them.

## Setup on a new machine

### Linux

```bash
# 1. Install GNU Stow
sudo apt install stow        # Debian/Ubuntu
# sudo pacman -S stow        # Arch
# sudo dnf install stow      # Fedora

# 2. Clone this repo
git clone <repo-url> ~/src/dotfiles
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

### macOS

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install GNU Stow
brew install stow

# 3. Clone this repo
git clone <repo-url> ~/src/dotfiles
cd ~/src/dotfiles

# 4. Install git hooks
bash scripts/install-hooks.sh

# 5. Stow the packages you want
make stow PKG=zsh
make stow PKG=starship
# ...or all at once:
make stow
```

> **Note:** Some configs contain Linux-specific paths that need adjusting on macOS:
>
> - `zsh/.zshrc` — hardcodes `/home/linuxbrew/` (Homebrew prefix on macOS is `/opt/homebrew`), `/home/tom/` (your macOS username differs), and `/usr/bin/code` (VS Code path on macOS). Edit these after stowing.
> - `ghostty` — Ghostty is available on macOS; no changes needed.
> - `starship` — works on macOS without changes.

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
