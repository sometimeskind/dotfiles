---
name: review-feedback
description: Process and implement code review feedback systematically. Use when the user pastes PR review comments, asks to address or fix review feedback, or says something like "fix these comments" / "here's my review".
---

# PR Review Feedback

Process review feedback on an open PR: echo each point back, categorize it, confirm the plan, implement changes, then verify all comments are resolved.

TRIGGER when: user pastes PR review comments, asks Claude to address or fix review feedback, or says something like "fix these comments" / "here's my review".
DO NOT TRIGGER when: user is asking for a general code review without specific comments to act on.

**Feedback or PR number:** $ARGUMENTS

## Steps

1. **Identify the PR**
   - If a PR number was given, fetch its details: `gh pr view <number>`
   - If no number was given, ask the user which PR they're reviewing
   - Note the linked issue number (for acceptance criteria reference)

2. **Intake feedback**
   - If feedback was pasted in `$ARGUMENTS`, parse it directly
   - If not, ask the user to paste their review comments before proceeding
   - For each comment, echo it back in a structured list:
     ```
     1. [category] — <short restatement of the comment>
        Plan: <what you will do to address it>
     ```
   - Categories:
     - **bug** — something is wrong or will break
     - **question** — user needs more information or an explanation
     - **design** — approach or architecture concern
     - **nit** — style or minor cleanup
     - **scope** — suggests work beyond the current PR
   - For `scope` items: flag them clearly and ask whether the user wants them addressed now or tracked as a separate issue. Do not implement scope changes without confirmation.
   - For `question` items: answer them immediately in your response before touching any code.
   - **Feedback from an agent reviewer** (`/code-review`, a fresh-context check, a subagent): the category says what kind of finding it is; the Plan line opens with a label that decides what you do. Use the repo's own procedure if it has one (homelab: `.claude/references/fresh-context-checks.md`, whose labels these copy); otherwise:
     - **CONTEST**: the finding is wrong and you can cite evidence the reviewer could have read (a file and symbol, a decision recorded in the issue or a doc). Change nothing; give the evidence. "This was intentional" is not evidence.
     - **ESCALATE**: the finding is wrong, but the evidence is outside anything the reviewer could read (something said in conversation, an unrecorded convention). Change nothing; tell the user, who decides whether it gets recorded.
     - **PROPOSE FIX**: the finding is valid. Fix it.
     - **DECLINE**: a nit not worth fixing. Record it in the summary; nothing else.
     - Never change a finding's severity; if a Blocker is really a nit, CONTEST it and say why. You wrote what was reviewed, so wanting to contest is not evidence that the reviewer is wrong.
   - **The operator's own comments** keep the flow above. If you disagree with one, say so with the same kind of checkable evidence (a file, a recorded decision) rather than silently skipping or quietly complying.
   - Confirm the plan with the user before making any changes. If any item is ambiguous, ask now — not after you've already pushed code.

3. **Implement changes**
   - Work through items sequentially using the numbered list above as your guide — address one item fully before moving to the next
   - Address all confirmed items (excluding deferred scope items)
   - One commit per logical group of changes; use the issue number in the message
   - Do not make unrequested changes while addressing feedback — stay focused

4. **Verify and report**
   - Re-read the changed files to confirm each comment is resolved
   - Post a summary to the user:
     ```
     Resolved:
     - #1 [bug] — <what changed, file:line>
     - #2 [nit] — <what changed, file:line>

     Deferred (separate issue):
     - #3 [scope] — <description> → tracked as #N

     Open (needs your input):
     - #4 [question] — <restate what you still need>
     ```
   - Push the branch: `git push origin <branch>`
   - Check CI: `gh pr checks <pr-number>`. A fine-grained PAT can't read Checks, so if that 403s, use `gh run list --branch <branch>`. If any check fails, diagnose and fix before handing back.

5. **Hand off**
   - Tell the user the PR is updated and ready for re-review
   - Do not mark the PR ready for review or request re-review on GitHub unless the user asks

## Important Guidelines

- **Work sequentially** — address one feedback item fully before moving to the next
- **Ask clarifying questions** on ambiguous feedback before touching code
- **Scope items require confirmation** — never implement them without user approval
- **Question items get answered first** — before any code changes
- **Follow CLAUDE.md conventions** for all changes
