# apps/

Child ArgoCD `Application` manifests — one per concern. The root Application
(`../bootstrap/root-app.yaml`) points here, so anything committed to this directory
gets picked up and synced automatically.

Planned children:

- `sample-app/` — a small demo workload to prove the GitOps loop end to end (Phase 2)
- `observability/` — kube-prometheus-stack + Loki (Phase 3)
- `security/` — Kyverno policies and related guardrails (Phase 4)

Each will be added as its phase lands, so this directory stays in sync with what the
cluster actually runs.
