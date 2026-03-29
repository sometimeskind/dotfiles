---
name: review-feedback
description: Process PR review comments systematically — categorize, confirm the plan, implement, and verify all items are resolved. Use when the user pastes review comments, asks to address feedback, or says "fix these comments" / "here's my review".
---

# PR Review Feedback

TRIGGER when: user pastes review comments, asks to address or fix feedback, or says "fix these comments".
DO NOT TRIGGER when: user wants a general code review with no specific comments to act on, or when feedback seems technically questionable and needs pushback evaluation before any code is touched.

**Feedback or PR number:** $ARGUMENTS

## Workflow

1. **Identify the PR** — if a number was given, fetch its details from your PR tool (e.g. `gh pr view <number>`); otherwise ask.

2. **Categorize each comment** and echo back a structured list:
   ```
   1. [category] — <short restatement>
      Plan: <what you will do>
   ```
   Categories: **bug**, **question**, **design**, **nit**, **scope**

   - `scope`: flag and ask whether to address now or track separately — never implement without confirmation
   - `question`: answer immediately before touching any code
   - Confirm the full plan with the user before making changes; ask about ambiguities now

3. **Implement** — work through items sequentially; one commit per logical group; stay focused, no unrequested changes

4. **Verify and report:**
   ```
   Resolved:   #1 [bug] — <what changed, file:line>
   Deferred:   #2 [scope] — tracked as #N
   Open:       #3 [question] — <what you still need>
   ```
   Push: `git push origin <branch>`
   Check CI status for the PR — diagnose and fix any failures before handing back (e.g. `gh pr checks <pr-number>` on GitHub)

5. **Hand off** — tell the user the PR is ready for re-review; do not request re-review on your platform unless asked

## Guidelines

- Answer `question` items first, before any code changes
- `scope` items require explicit user confirmation
- One feedback item fully resolved before moving to the next
