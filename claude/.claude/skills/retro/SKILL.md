---
name: retro
description: Review a coding session for friction and propose fixes to the agent's environment (a check, a hook, a pointer, a note, a deletion), not to the code. Use when the user types /retro or asks for a retrospective on a session.
disable-model-invocation: true
---

# Retro

Propose changes to the agent's **environment** so the next session of this kind goes better. The code the session produced is out of scope. You only propose: the user picks what gets built.

## Steps

1. **Pick the session.** Default to the current one. For another, read its transcript at `~/.claude/projects/<cwd-slug>/<session-id>.jsonl` in slices with `jq` or `grep`, never whole. If the current session was summarised, read its transcript for the part before the summary.

2. **List the friction moments**, before thinking about any fix. A **moment** is one specific point in the session:
   - several searches or reads to find one fact
   - a failed command and the retry that got past it
   - a correction from the user
   - a hook or permission block
   - a tool result far larger than what was needed from it
   - a fact the user had to supply because the agent could not reach it
   - a mistake caught late (review, CI, the user) that could have been caught early

   Record each as what the agent did and where (the command or the turn). This step is done when you have walked the session from its first turn to its last, not only the part you remember. If there are no moments, say the session was smooth and stop.

3. **Read the environment each moment touched**: the steering files that were loaded (global and project `CLAUDE.md`, path-scoped rules), the repo's check commands and CI workflows, the hooks in `settings.json`, and the notes or docs that cover the topic. When a check, hook or note already exists and did not fire, the candidate is to wire or sharpen it.

4. **Turn each moment into at most one candidate**, taking the highest rung of the fix ladder that fits.

5. **Present the candidates**, most costly friction first (time and tokens lost, risk of harm). For each: the moment, the fix, the file it lands in, and what the fix costs (context load, upkeep, the chance of blocking good work). Then wait for the user to pick.

6. **Build a picked candidate** through the repo's normal change workflow (issue, branch, PR).

## Fix ladder

Prefer the higher rung: a check can fail, a sentence can only be read.

| Rung | Fits when | Fix |
|------|-----------|-----|
| 1. Check | The mistake is mechanical: a fixed pattern, a banned command, a file in the wrong place | A hook, lint rule, test or CI job |
| 2. Access | A needed fact was out of reach | A log written to a file, a read-only credential, a tool |
| 3. Tool | A call cost far more than its answer was worth | A narrower command, a script, trimmed output |
| 4. Pointer | The fact existed and took long to find | One line in a file the agent already reads at that point, naming the target and when to open it |
| 5. Reviewer rule | A judgement call slipped past review | A rule in what the reviewer reads (the review skill or standards file) |
| 6. Note | A trap no check can catch | A note where the repo keeps its lessons |
| 7. Deletion | A steering line was ignored, stale, duplicated, or says what the agent does anyway | Remove it, or replace it with a rung above |

Always-loaded files (`CLAUDE.md`, skill descriptions) cost every session, so they come last: add to them only a pointer, or a safety rule that no check can enforce.

## Where fixes land

The repo's `CLAUDE.md` says where its hooks, notes and docs live; follow it. A fix that holds in every repo (a shell trap, a global hook, a global skill) goes in the dotfiles repo under `claude/.claude/`, as its own PR.

## Rules

- **Every candidate cites its moment.** A candidate with no moment behind it is generic advice: drop it.
- **Describe a moment by the agent's actions**: the command, the tool, the count. File contents, personal data and secrets seen in the session stay out of candidates, notes and issues.
- **One session is one data point.** Say so when a candidate rests on a single occurrence. If the repo mines its transcripts for recurring traps, use that as the evidence for "this keeps happening".
- **A proposed check is code.** Test it against the repo, including one case it must let through, before it can block anything.

Adapted from Matt Pocock's `retro` skill (github.com/mattpocock/skills, MIT).
