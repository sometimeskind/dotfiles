---
name: post-merge
description: Pull the default branch, rebase all open PR branches, and verify CI after a merge. Use when a PR has just been merged and the repo needs to be brought back into sync.
---

# Post-Merge Cleanup

TRIGGER when: a PR has just been merged.
DO NOT TRIGGER when: a PR is still open or under review.

## Quick start

```bash
git checkout main && git pull
```

Then list your open PRs in your hosting platform and rebase each branch onto the updated default branch (may be `main`, `master`, or `trunk`).

## Workflow

1. **Pull default branch** — `git checkout <default> && git pull`

2. **List open PRs** — query your hosting platform for open PRs authored by you (e.g. `gh pr list --author "@me" --state open` on GitHub)

3. **Rebase each open branch:**
   ```bash
   git checkout <branch>
   git rebase <default>
   git push --force-with-lease origin <branch>
   ```

4. **Check CI on each rebased branch** — check CI status for the PR (e.g. `gh pr checks <pr-number>` on GitHub).
   If a check fails, view the failed run logs, diagnose, fix, repeat.

5. **Return to default branch** — `git checkout <default>`

## Guidelines

- Use `--force-with-lease`, never `--force`
- Check CI after every rebase push — rebasing can expose new failures
- Surface rebase conflicts to the user; do not resolve them unilaterally
