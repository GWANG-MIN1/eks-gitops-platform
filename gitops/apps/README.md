# apps/

Child ArgoCD `Application` manifests — one per concern. The root Application
(`../bootstrap/root-app.yaml`) points here (non-recursive), so every `*.yaml` in
this directory is a child Application that gets picked up and synced automatically.
Each Application's own `path` points at a sibling folder holding the real manifests.

Children:

- `sample-app.yaml` → `sample-app/` — a small demo workload proving the GitOps loop
  end to end (Phase 2) ✅
- `observability/` — kube-prometheus-stack + Loki (Phase 3) ⬜
- `security/` — Kyverno policies and related guardrails (Phase 4) ⬜

Each is added as its phase lands, so this directory stays in sync with what the
cluster actually runs.
