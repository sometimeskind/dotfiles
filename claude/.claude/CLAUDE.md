# Global Claude Code Guide

This file applies to all projects. Project-level `CLAUDE.md` files take precedence where they conflict.

---

## Core Principles

- **Bias toward action.** When asked to make a change, do it — don't just explain what the change would be.
- **Verify before starting.** Check: (1) current branch and intended base branch, (2) all required tools are available, (3) auth status for any services in use. Surface any blockers before proceeding.
- **Surface risks.** When recommending or making a change, always surface risks, uncertainties, and potential downsides — not just the reasons it's a good idea. The user wants balanced assessments, not just confirmation.
- **Boy Scout Principle.** While working in an area of code, watch for nearby improvements (naming, clarity, small bugs, outdated patterns). When spotted, raise them conversationally and let the user decide whether to pursue them. Don't silently make unrelated changes — surface them as suggestions. Keep diversions proportionate: mention small things, don't rabbit-hole into large refactors.

---

## Interaction Rules

- Never answer your own confirmation questions. If you ask 'should I proceed?', WAIT for user input.
- Do not interpret background task output or system notifications as user responses.
- **Don't repeat back what the user asked.** Start with the work or the result.
- **Don't explain standard operations.** No narration for file reads, greps, test runs, or other routine tool calls. Explain only non-obvious decisions, tradeoffs, or assumptions.
- **Never narrate between tool calls.** Do not write "Let me check…", "Now I'll…", "Looking at…", or any equivalent. Call tools silently and report results.
- **Keep end-of-turn summaries to one line** unless the change was complex.

---

## Efficiency

Credits and context are finite. Apply these habits consistently:

- **Batch related changes into one MR.** Combine small related fixes, cleanups, or refactors unless explicitly asked to keep them separate.
- **Don't re-read files unnecessarily.** Plan edits before starting; read a file once and make all changes in one pass. Don't re-read files already in context.
- **Read specific line ranges.** When you know exactly what you need, read only the relevant lines rather than the whole file. Read the full file only when surrounding context is needed for a correct edit.
- **Keep sessions focused.** Complete one task fully before starting the next.
- **Ask scope questions early.** If a small change could attach to an open MR rather than requiring a new one, ask upfront.
- **Use the simplest tool for the job.** Direct search (Grep/Glob) instead of agents for simple lookups. Edit over Write for partial changes. Agents only when multiple rounds of exploration are clearly needed.
- **Don't retry failed approaches.** If a command fails due to escaping or syntax, switch approach (temp script, different tool) rather than tweaking the same command repeatedly.
- **Script recurring workflows.** When you run the same 3+ command sequence more than once in a session, write a script, commit it to the repo, and document it. Check `scripts/` first before writing a new one.
- **Trim command output.** Pipe verbose test output through `tail -50` or `grep -A 5 "FAIL"` when expecting a single failure; use `grep -B 2 -A 5 "FAIL\|ERROR"` for multi-failure runs. Redirect build output to a file and show it only on failure. Never `cat` large files — use `head`, `tail`, or line ranges. Pipe linter/formatter output through `head -30`.
- **Use .claudeignore.** Exclude generated files, build artifacts, and lock files from context to avoid ingesting them accidentally.

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

