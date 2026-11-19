---
name: ticket-review
description: Help the user decide what to work on next by reviewing their assigned issues and recommending the best one to pick up. Use when the user asks what to work on, wants to pick a ticket, or asks what's next.
---

# Pick Next Ticket

Review open issues assigned to you and recommend the best one to start on next.

TRIGGER when: user asks what to work on next, wants to pick a ticket, or asks "what's assigned to me".
DO NOT TRIGGER when: user asks to review backlog health or issue quality across all issues — use `/groom-backlog` for that.

## Steps

1. **Fetch the operator's assigned issues** in the current repo (not `@me`: on pilot that resolves to the agents' GitHub App, sometimeskind/homelab#2139):
   ```bash
   gh issue list --state open --assignee sometimeskind --json number,title,body,labels,updatedAt
   ```

   **If the repo has `scripts/backlog-queue.py`** (homelab, sometimeskind/homelab#3001), run it instead: it prints who each open issue waits on. There the operator's work is what waits on them, so recommend from those states and skip steps 2 and 3:
   - `review`: a PR to review. These come first, oldest PR first: each one unblocks finished work.
   - `needs-design`: a decision. Read the comment that lists the options and present them.
   - `needs-operator`: a manual step. Read the comment that lists the steps.
   - Never recommend a `parked` issue. A `queue` issue is the agents' to progress: mention how many there are, and recommend one only if the user asks for something to build.

   Only the operator removes a state label; offer the `gh issue edit <N> --remove-label <label>` command once the decision or step is done.

2. **Filter to actionable issues** — skip any that:
   - Have no acceptance criteria (can't tell when done)
   - Have open blocking questions in the body or comments, including unresolved `[NEEDS CLARIFICATION: …]` markers
   - Are explicitly marked as blocked or waiting

3. **Rank the remaining issues** by:
   - Unblocking other work (dependencies first)
   - Smallest scope (prefer quick wins if priorities are otherwise equal)
   - Most recently updated (signal of active relevance)

4. **Recommend one issue** — present it with:
   - Issue number and title
   - One-sentence summary of what needs doing
   - Why you ranked it first
   - Any caveats or things to clarify before starting

5. **Offer alternatives** — briefly list the next 1–2 runners-up in case the top pick doesn't suit

6. **Hand off** — if the user confirms a choice, trigger the repo's `new-feature` skill if it has one (homelab does) to kick off the full implementation workflow; otherwise start on a branch per the repo's conventions

## Important Guidelines

- **Recommend, don't implement** — this skill ends when the user picks an issue
- **Surface blockers early** — if the top candidates all have gaps, say so rather than picking a bad ticket
- **For backlog health issues** (stale tickets, missing AC, duplicates) — point the user to `/groom-backlog` (homelab has one) instead of fixing them here
