# Global Claude Code Guide

This file applies to all projects. Project-level `CLAUDE.md` files take precedence where they conflict.

---

## Platform Terminology Map

These abstract terms are used throughout this guide. Map them to your project's platform:

| Concept | GitHub | Azure DevOps | Jira/Linear |
|---|---|---|---|
| Ticket | Issue | Work Item | Issue/Ticket |
| Primary branch | `trunk` or `main` | `main` | `main` |
| Merge request | Pull Request (PR) | Pull Request (PR) | PR |
| CI status | `gh pr checks` | Pipeline status | CI status |
| CI logs | `gh run view --log-failed` | Pipeline run logs | CI logs |
| Diff review | `gh pr diff` | PR diff view | PR diff |
| Branch prefix | `feat/<issue#>-<slug>` | `feat/<workitem#>-<slug>` | `feat/<issue#>-<slug>` |

---

## Core Principles

- **Bias toward action.** When asked to make a change, do it — don't just explain what the change would be.
- **Verify before starting.** Check: (1) current branch and intended base branch, (2) all required tools are available, (3) auth status for any services in use. Surface any blockers before proceeding.
- **Surface risks.** When recommending or making a change, always surface risks, uncertainties, and potential downsides — not just the reasons it's a good idea. The user wants balanced assessments, not just confirmation.

---

## Branch and Ticket Workflow

### Never commit to the primary branch directly.

Always create a feature branch before modifying any files. Exception: standalone housekeeping files (logs, agent guidance) with no feature dependencies may go directly to the primary branch — but confirm with the user first.

### Branch naming

```
feat/<ticket-number>-<short-description>
fix/<ticket-number>-<short-description>
chore/<ticket-number>-<short-description>
```

### Creating a ticket

When a ticket is needed, include:
- A clear problem statement
- A checklist of acceptance criteria (every item must be completable and verifiable)

Ask whether to create a new ticket or attach work to an existing one. Do not assume.

Never re-open a closed or merged MR. Create a new branch and MR for additional changes; reference the old MR if related.

### Opening a merge request

1. Create the branch from the primary branch.
2. Open a **draft** merge request immediately after the first commit.
3. Write the MR description as a Markdown implementation plan with a checklist:
   ```markdown
   ## Plan
   - [x] Step 1 — already done
   - [ ] Step 2
   - [ ] Step 3
   ```
4. Make at least one commit per step. After each step, update the MR body to check it off (`- [ ]` → `- [x]`).
5. When all steps are done, mark the MR ready for review.

---

## Pre-Submission Checklist

Before marking a MR ready for review, verify all of the following:

- [ ] Tests pass locally (see Testing section below)
- [ ] Self-reviewed the full diff — left comments on anything unclear or incomplete
- [ ] Project documentation updated if affected by the change
- [ ] All acceptance criteria from the linked ticket are met
- [ ] No plaintext secrets committed
- [ ] No debug/temporary code left in

Fix any issues found before presenting the MR.

---

## Testing

Run tests locally before pushing. The specific commands depend on the project; consult the project-level `CLAUDE.md`. General rule: **never push failing tests**.

Common patterns:
- Validate config/manifests before applying: `<tool> validate` or `<tool> dry-run`
- Run the project test suite: check `Makefile`, `package.json`, CI config for the canonical test command
- For infrastructure changes: validate both syntax and plan before apply

---

## CI Validation

After pushing any branch or rebasing:

1. Check CI status immediately — don't wait to be asked.
2. If any check fails, diagnose using the CI logs and fix without waiting.
3. Do not consider a MR ready for review until CI is green.

This applies to new MRs and to branches rebased during post-merge cleanup.

---

## Post-Merge Cleanup

After a MR is merged:

1. Pull the primary branch locally.
2. Rebase any open feature branches onto the updated primary branch; check their CI immediately.
3. Validate the outcome of the merged change (use `kubectl`, integration tests, smoke tests, or whatever applies to the project). Do not apply fixes without checking with the user first.
4. If the merged MR body contained a **Test plan**, **Acceptance criteria**, or similar checklist, work through each item and confirm it is met before considering the work done.
5. Check out the primary branch before starting new work.

---

## Efficiency

Credits and context are finite. Apply these habits consistently:

- **Batch related changes into one MR.** Combine small related fixes, cleanups, or refactors unless explicitly asked to keep them separate.
- **Don't re-read files unnecessarily.** Plan edits before starting; read a file once and make all changes in one pass.
- **Keep sessions focused.** Complete one task fully before starting the next.
- **Ask scope questions early.** If a small change could attach to an open MR rather than requiring a new one, ask upfront.
- **Use the simplest tool for the job.** Direct search (Grep/Glob) instead of agents for simple lookups. Edit over Write for partial changes. Agents only when multiple rounds of exploration are clearly needed.
- **Don't retry failed approaches.** If a command fails due to escaping or syntax, switch approach (temp script, different tool) rather than tweaking the same command repeatedly.
- **Script recurring workflows.** When you run the same 3+ command sequence more than once in a session, write a script, commit it to the repo, and document it. Check `scripts/` first before writing a new one.

---

## Risky Actions — Confirm Before Proceeding

For actions that are hard to reverse, affect shared state, or could cause data loss, communicate the action and ask for confirmation before proceeding. Authorization for one instance does not cover all future instances.

Examples requiring confirmation:
- Destructive operations: deleting files/branches, dropping tables, `rm -rf`, overwriting uncommitted changes
- Hard-to-reverse operations: force-push, `git reset --hard`, amending published commits, removing dependencies, modifying CI/CD pipelines
- Actions visible to others: pushing code, creating/closing/commenting on MRs or tickets, sending messages, posting to external services, modifying shared infrastructure

When encountering an obstacle, do not use destructive actions as a shortcut. Identify root causes. Investigate unexpected state before deleting or overwriting — it may represent in-progress work.

---

## Shell Command Safety

- **Never use unnecessary quotation marks in shell commands.** Quoted strings (especially with `"..."`) can hide variable expansion and flag-like content, which triggers permission prompts every time.
- **No visual separators inside quoted strings.** Never use sequences of dashes or similar decorators (e.g. `"-----"`) in shell commands or arguments.
- Keep shell commands simple and unquoted where possible. Use temp files or scripts instead of complex quoting when arguments are non-trivial.

---

## Secrets

Never commit plaintext secrets. Use the project's designated secret management mechanism (sealed secrets, Azure Key Vault, environment-specific secret stores, etc.). When in doubt, ask.

---

## Pinning Versions

Never pin a container image version or package version from memory. Always look up the current stable release before pinning.

**GitHub-hosted projects** (covers most Kubernetes ecosystem tooling):
```bash
gh release list --repo <org/repo> --limit 5
```
Pick the most recent non-prerelease tag.

**Docker Hub images** — check whether the project has a GitHub repo and use `gh release list` there. Most official images (e.g. `homeassistant/home-assistant`, `linuxserver/*`) have a corresponding GitHub repo with releases.

**If the latest stable version is ambiguous or hard to determine** (e.g. no GitHub repo, irregular tagging scheme, unclear which tag is "stable"): ask the user before pinning rather than guessing.

---

## MCP Tools

### context7 — Up-to-date Library Documentation
When writing code or configuration that uses an external library, API, or framework, use context7 to fetch current documentation before writing. This prevents writing against stale API specs or deprecated fields.

**How:** Call `resolve-library-id("<library-name>")` first, then `get-library-docs(<id>, "<topic>")`.

**When to use:**
- Before writing manifests for Kubernetes APIs, Helm chart values, or CRD schemas
- Before implementing a feature that calls an external SDK or framework
- When uncertain whether a field, annotation, or option still exists in the current version

**When not to use:** For well-known, stable APIs you already know (e.g. basic git commands, standard bash). Use context7 for external libraries — especially those that upgrade frequently.

---

## Commit Style

- One logical change per commit.
- Commit messages: `type: short description` (e.g. `feat: add retry logic`, `fix: handle null response`, `chore: update dependencies`).
- Reference the ticket number in the MR or branch name — not necessarily in every commit message.

---

## Action Logging

When taking actions with external side effects (applying infrastructure changes, running database migrations, restarting services), log each action with a timestamp and short description of what it does and why. Format:

```
YYYY-MM-DD HH:MM:SS - <action> - <reason>
```

Store in a project-designated log file if one exists.
