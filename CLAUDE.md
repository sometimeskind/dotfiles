# dotfiles — Claude guidance

This is a personal dotfiles repo managed with GNU Stow.

## Structure

- Each top-level directory is a Stow package mirroring `$HOME`.
- `stow <package>` creates symlinks from `~/` into the package directory.
- Do not create files outside of package directories (except repo-level docs and scripts).

## Conventions

- Package names are lowercase, matching the tool name (e.g. `zsh`, `git`, `nvim`).
- Hidden files/dirs live inside packages at their real path (e.g. `nvim/.config/nvim/`).
- Keep one package per tool. Do not bundle unrelated configs.

## Workflow

See README.md for the full setup and usage workflow.

Use `make stow`, `make unstow`, and `make restow` (with optional `PKG=<name>`) rather than invoking `stow` directly.

## Branch and PR

Always create a feature branch and open a PR for every change — no direct commits to `main`.
