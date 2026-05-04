---
name: dx-architecture
description: Load DX system architecture context. Use when discussing repos (integration-api, dx-ops-web, weather-api, unleash-api, digital-execution-grpc), modules (assembly, dfAdapter, notification, shared), gRPC integrations, external services (Data Fabric, Authz, DMS, MS Graph, Orchestration, Search), database schemas, infrastructure (Azure, Kubernetes, Linkerd, Terraform), or auth/feature-flag plumbing.
model: haiku
context: fork
---

Read and return the contents of `~/projects/dx/dx-team-context/architecture.md` verbatim.

Do not summarize, paraphrase, or interpret. Return the file content as-is so the parent session has full architecture context.

If the file does not exist at that path, report that fact and stop.
