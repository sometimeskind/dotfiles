---
name: ticket-review
description: Review open issues assigned to you and recommend the best one to pick up next. Use when the user asks what to work on, wants to pick a ticket, or asks "what's assigned to me" / "what's next".
---

# Pick Next Ticket

TRIGGER when: user asks what to work on next, wants to pick a ticket, or asks "what's assigned to me".
DO NOT TRIGGER when: user wants to review backlog health or issue quality across all issues.

## Workflow

1. **Fetch assigned issues** — query your issue tracker for open issues assigned to you (e.g. `gh issue list --state open --assignee @me --json number,title,body,labels,updatedAt` on GitHub).

2. **Filter to actionable issues** — skip any that:
   - Have no acceptance criteria (can't tell when done)
   - Have open blocking questions in the body or comments
   - Are explicitly marked blocked or waiting

3. **Rank remaining issues** by:
   - Unblocks other work (dependencies first)
   - Smallest scope (prefer quick wins if priorities are equal)
   - Most recently updated (signal of active relevance)

4. **Recommend one issue** — present:
   - Issue number and title
   - One-sentence summary of what needs doing
   - Why it ranked first
   - Any caveats or things to clarify before starting

5. **Offer alternatives** — briefly list 1–2 runners-up in case the top pick doesn't suit

6. **Hand off** — if the user confirms a choice, help them kick off the implementation workflow

## Guidelines

- Recommend, don't implement — this skill ends when the user picks an issue
- Surface blockers early — if top candidates all have gaps, say so rather than picking a bad ticket
