# Upstream

Adapted from
[humanlayer/skills](https://github.com/humanlayer/skills/tree/4d69d20f6e9b57b4fcf0d501ccfb1be961f0f329/plugins/show-me)
`plugins/show-me/skills/show-me/SKILL.md` at `4d69d20f6e9b57b4fcf0d501ccfb1be961f0f329`
(2026-11-21; the skill itself last changed 2026-09-12), MIT (`LICENSE`). The upstream file
is a single prompt with no scripts, and it was read in full before adapting.

## What differs

- The React component-tree view and its diff are replaced by a resource tree, a request
  path and a table, which match what gets asked about here (infra, pipelines).
- The call-tree examples use a pipeline's names instead of a web app's.
- Mermaid is limited to text that gets rendered (PR bodies, issues, docs); a terminal shows
  it as source.
- The HTML step no longer runs `open` (macOS only, and pilot is headless). It publishes an
  Artifact only where the repo's rules allow the content to leave, and otherwise gives a
  file path.

## Updating

Third-party instructions: re-read the diff before taking any of it, never pull blind.

1. `gh api 'repos/humanlayer/skills/compare/4d69d20f6e9b57b4fcf0d501ccfb1be961f0f329...HEAD' --jq '.files[].filename'`
   and read every change under `plugins/show-me/`.
2. Take what still fits by hand (this copy is not a mirror), update the SHA and date above,
   and open a PR.
