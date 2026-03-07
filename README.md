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

# 3. Stow the packages you want
stow --dir=~/src/dotfiles --target=~ zsh
stow --dir=~/src/dotfiles --target=~ ghostty
stow --dir=~/src/dotfiles --target=~ starship
# ...or all at once:
stow --dir=~/src/dotfiles --target=~ */
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
stow --dir=~/src/dotfiles --target=~ <package>

# Commit
git add <package>/
git commit -m "feat: add <package> config"
```

## Removing a package

```bash
stow --dir=~/src/dotfiles --target=~ -D <package>    # removes symlinks, leaves real files untouched
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

Never put secrets in dotfiles. Use `~/.secrets` for any tokens or credentials:

```bash
# ~/.secrets  (chmod 600, never committed)
export GITHUB_PERSONAL_ACCESS_TOKEN="..."
export SOME_API_KEY="..."
```

`.zshrc` sources `~/.secrets` automatically if the file exists. `~/.secrets` is in `.gitignore`.

## Updating

```bash
cd ~/src/dotfiles
git pull
stow --dir=~/src/dotfiles --target=~ */    # re-stow to pick up any new symlinks
```
