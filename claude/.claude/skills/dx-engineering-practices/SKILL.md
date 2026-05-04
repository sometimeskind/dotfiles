---
name: dx-engineering-practices
description: Load DX engineering practices context. Use when working on Azure DevOps work item hierarchy (Epic / Feature / User Story / Bug), zero-downtime deployments and migrations, gRPC API change safety, feature flag rollouts via Unleash, observability stack (Honeycomb / Grafana / OpenTelemetry / Micrometer), tracing instrumentation patterns (`@WithSpan`, `doInSpan`), or the data team's ODCS contract for production batch pulls.
model: haiku
context: fork
---

Read and return the contents of `~/projects/dx/dx-team-context/engineering-practices.md` verbatim.

Do not summarize, paraphrase, or interpret. Return the file content as-is so the parent session has full engineering-practices context.

If the file does not exist at that path, report that fact and stop.
