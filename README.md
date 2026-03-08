# dotfiles

Personal Linux tooling configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Each top-level directory is a **Stow package** — a folder whose internal structure mirrors `$HOME`. Running `stow <package>` creates symlinks from `~/` into that package directory.

Example: `zsh/.zshrc` becomes `~/.zshrc` (symlink).

## Setup on a new machine

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
stow --dir=$HOME/src/dotfiles --target=$HOME zsh
stow --dir=$HOME/src/dotfiles --target=$HOME ghostty
stow --dir=$HOME/src/dotfiles --target=$HOME starship
# ...or all at once:
stow --dir=$HOME/src/dotfiles --target=$HOME */
```

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
stow --dir=$HOME/src/dotfiles --target=$HOME <package>

# Commit
git add <package>/
git commit -m "feat: add <package> config"
```

## Removing a package

```bash
stow --dir=$HOME/src/dotfiles --target=$HOME -D <package>    # removes symlinks, leaves real files untouched
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
stow --dir=$HOME/src/dotfiles --target=$HOME */    # re-stow to pick up any new symlinks
```
