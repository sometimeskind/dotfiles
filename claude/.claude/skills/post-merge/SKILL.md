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
gh pr list --author "@me" --state open
```

Then rebase each open branch onto the updated default branch (may be `main`, `master`, or `trunk`).

## Workflow

1. **Pull default branch** — `git checkout <default> && git pull`

2. **List open PRs** — `gh pr list --author "@me" --state open`

3. **Rebase each open branch:**
   ```bash
   git checkout <branch>
   git rebase <default>
   git push --force-with-lease origin <branch>
   ```

4. **Check CI on each rebased branch:**
   ```bash
   gh pr checks <pr-number>
   ```
   If a check fails: `gh run view <run-id> --log-failed`, diagnose, fix, repeat.

5. **Return to default branch** — `git checkout <default>`

## Guidelines

- Use `--force-with-lease`, never `--force`
- Check CI after every rebase push — rebasing can expose new failures
- Surface rebase conflicts to the user; do not resolve them unilaterally
