# Upstream

Vendored unmodified from
[fabricioctelles/skills](https://github.com/fabricioctelles/skills/tree/304674ac08b98366bbdfd4e32f7d49c428077659/skills/okf-open-knowledge-format)
at `304674ac08b98366bbdfd4e32f7d49c428077659` (2026-10-04), Apache-2.0 (`LICENSE`).
Every file was read before vendoring: `scripts/validate.sh` only reads the bundle, and
`references/spec-v02.md` matches Google's
[OKF v0.2 spec](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/main/SPEC.md)
apart from `⇒` written as `=>`.

## Updating

Third-party instructions: re-read the diff before taking it, never pull blind.

1. `gh api 'repos/fabricioctelles/skills/compare/304674ac08b98366bbdfd4e32f7d49c428077659...HEAD' --jq '.files[].filename'`
   and read every change under `skills/okf-open-knowledge-format/`.
2. Copy the changed files in, update the SHA and date above, and open a PR.

When Google ships a new OKF version, check that the skill has caught up (its
`references/spec-v*.md`) before relying on it; the homelab repo's own check flags new
versions (`scripts/docs-index.sh --report`, `okf-version`).

## Local precedence

In a repo with its own OKF conventions (homelab: `docs/_agent/README.md` and the
`okf-conformance` note), those win over the skill's generic advice, for example its
suggestion to add `index.md` and `log.md` files.
