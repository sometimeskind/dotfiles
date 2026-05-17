# Global Claude Code Guide

This file applies to all projects. Project-level `CLAUDE.md` files take precedence where they conflict.

These guidelines bias toward caution over speed. For trivial tasks, use judgment.

---

## Core Principles

- **Bias toward action.** When asked to make a change, do it — don't just explain what the change would be.
- **Verify before starting.** Check current branch, intended base, required tools, auth status. Surface blockers before proceeding.
- **Surface risks.** Always surface uncertainties and downsides — not just reasons it's a good idea.
- **Boy Scout: surface, don't silently fix.** When you spot nearby improvements, raise them; don't make unrelated changes silently.

---

## Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If something is unclear, stop. Name what's confusing. Ask.
- For non-trivial tasks: state a brief plan with verifiable success criteria *before* implementing.
  - "Add validation" → "Write tests for invalid inputs, then make them pass"
  - "Fix the bug" → "Write a test that reproduces it, then make it pass"
  - "Refactor X" → "Ensure tests pass before and after"

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it.

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

---

## Surgical Changes

Touch only what you must. **Every changed line should trace directly to the user's request.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Remove imports/variables your changes orphaned. Don't remove pre-existing dead code unless asked.

---

## Interaction Rules

- Never answer your own confirmation questions. If you ask 'should I proceed?', WAIT.
- Don't repeat back what the user asked. Start with the work or the result.
- Don't explain standard operations. No narration for routine reads, greps, or test runs.
- Never narrate between tool calls. Call tools silently, report results.
- Keep end-of-turn summaries to one line unless the change was complex.

---

## Efficiency

Credits and context are finite. The dominant cost driver is generated output, not context size.

- **Batch related changes into one MR.**
- **Don't re-read files.** Plan edits before starting; read once, all changes in one pass.
- **Read specific line ranges** when you know what you need.
- **Use the simplest tool.** Direct Grep/Glob over agents. Agents only when multi-round exploration is clearly needed.
- **`Edit` over `Write` for existing files — always.** `Write` outputs the entire file as generated tokens; `Edit` only emits the diff. For a 500-line file that's ~10× the output cost. Before calling `Write` on a file that already exists, stop and use `Edit` (or multiple `Edit` calls) instead. The only valid `Write`-on-existing-file case is a deliberate full rewrite where most lines change.
- **Don't retry failed approaches.** Switch tactic; don't tweak the same command repeatedly.
- **Trim command output.** Pipe through head/tail/grep; never `cat` large files.
- **Use `.claudeignore`** to exclude generated files and build artifacts.
- **Push to CI before running long test suites.** On a feature branch, if the full test suite takes more than ~5 minutes and you're reasonably confident it will pass, push first so CI runs in parallel rather than waiting locally.

### Plan-mode discipline

Don't enter plan mode for tasks under ~50 lines of expected diff or for known fixes. Plan mode injects ~3KB of workflow instructions and steers toward parallel sub-agents — disproportionate cost for small work.

### Skill discipline

Project-local agents (`.claude/agents/`) and named skills (`.claude/skills/`) replace ad-hoc plan mode + parallel-Explore-agent patterns for recurring workflows. Prefer them when available.

---

## Risky Actions — Confirm Before Proceeding

Authorization for one instance does not cover all future instances.

Examples requiring confirmation:
- Destructive: deleting files/branches, dropping tables, `rm -rf`, overwriting uncommitted changes
- Hard-to-reverse: force-push, `git reset --hard`, amending published commits, removing deps, modifying CI/CD
- Visible to others: pushing code, creating/closing/commenting on MRs or tickets, sending messages, posting externally, modifying shared infra

When you hit an obstacle, find the root cause. Don't use destructive actions as a shortcut. Investigate unexpected state — it may be in-progress work.

---

## Shell Command Safety

- Never use unnecessary quotation marks. Quoted flag-like strings trigger permission prompts.
- No visual separators inside quoted strings (e.g. `"-----"`).
- Use temp files or scripts for non-trivial arguments instead of complex quoting.

---

## Secrets

Never commit plaintext secrets. Use sealed secrets, Azure Key Vault, or env-specific stores. When in doubt, ask.

---

## Pinning Versions

Never pin from memory. Look up the current stable release first.

- GitHub-hosted: `gh release list --repo <org/repo> --limit 5`, pick most recent non-prerelease.
- Docker Hub images usually have a corresponding GitHub repo — use `gh release list` there.
- If "stable" is ambiguous, ask before pinning.

---

## MCP Tools

### context7 — library docs
Before writing code against an external library/SDK/framework: `resolve-library-id` then `get-library-docs`. Skip for well-known stable APIs (git, bash). Use for libraries that upgrade frequently.

---

## Commit Style

- One logical change per commit. `type: short description` (`feat:`, `fix:`, `chore:`).
- Reference ticket in MR/branch name, not necessarily every commit.
