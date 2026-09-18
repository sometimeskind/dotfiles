# Global Claude Code Guide

Applies to all projects. Project-level `CLAUDE.md` files take precedence where they conflict.

## Working Style

- Bias toward action: when asked to make a change, make it rather than describing it.
- For non-trivial tasks, state a brief plan with verifiable success criteria before implementing ("write a failing test for the bug, then make it pass"), not "make it work".
- If multiple interpretations exist, present them rather than picking one silently.
- Boy Scout: when you spot nearby improvements, raise them. Don't make unrelated changes silently.
- Surface risks and downsides, not only the reasons an approach is good.
- Never answer your own confirmation questions. If you ask "should I proceed?", wait.
- Keep end-of-turn summaries to one line unless the change was complex.

## Efficiency

- Batch related changes into one PR.
- Plan edits before starting. Read a file once, and read specific line ranges when you know what you need.
- Use the simplest tool: Grep/Glob over agents. Agents only when multi-round exploration is clearly needed.
- Don't retry a failed approach with small tweaks. Switch tactic.
- Trim command output with head/tail/grep; never `cat` large files.
- On a feature branch, if the full test suite takes more than ~5 minutes and you're reasonably confident it passes, push first so CI runs in parallel.
- Don't enter plan mode for tasks under ~50 lines of expected diff or for known fixes.
- Prefer project-local agents (`.claude/agents/`) and skills (`.claude/skills/`) over ad-hoc plan mode for recurring workflows.

## Risky Actions

Beyond the built-in confirmation for destructive and hard-to-reverse actions, confirm before:

- modifying CI/CD, removing dependencies, modifying shared infra
- creating, closing or commenting on PRs or tickets, sending messages, posting externally

Authorization for one instance does not cover future instances. When you hit an obstacle, find the root cause. Investigate unexpected state before acting on it: it may be in-progress work.

## Shell Commands

Quoted flag-like strings and runs of dashes inside quotes trigger permission prompts (a hook blocks the latter). Put non-trivial arguments in a temp file or script instead of complex quoting.

## Secrets

Never commit plaintext secrets. Use sealed secrets or env-specific stores. When in doubt, ask.

## Pinning Versions

Never pin from memory. Look up the current stable release first:

- GitHub-hosted: `gh release list --repo <org/repo> --limit 5`, pick the most recent non-prerelease.
- Docker Hub images usually have a corresponding GitHub repo; use `gh release list` there.
- If "stable" is ambiguous, ask before pinning.

## Commit Style

- One logical change per commit: `type: short description` (`feat:`, `fix:`, `chore:`).
- Reference the ticket in the PR or branch name, not necessarily every commit.
