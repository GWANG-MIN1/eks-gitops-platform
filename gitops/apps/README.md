# apps/

Child ArgoCD `Application` manifests — one per concern. The root Application
(`../bootstrap/root-app.yaml`) points here (non-recursive), so every `*.yaml` in
this directory is a child Application that gets picked up and synced automatically.
Each Application's own `path` points at a sibling folder holding the real manifests.

Children:

- `sample-app.yaml` → `sample-app/` — a small demo workload proving the GitOps loop
  end to end (Phase 2) ✅
- `kube-prometheus-stack.yaml` — Prometheus, Grafana, Alertmanager + platform
  alerts (Phase 3) ✅
- `loki.yaml` / `promtail.yaml` — log storage and collection (Phase 3) ✅
- `kyverno.yaml` — policy engine; `kyverno-policies.yaml` → `../../security/kyverno/policies/`
  (Phase 4) ✅
- `external-secrets.yaml` — External Secrets Operator (Phase 4) ✅

The Helm-based Applications are multi-source: chart from the upstream Helm repo,
values from `../../observability/` or `../../security/` in this repo.

Sync ordering, where it matters, uses `argocd.argoproj.io/sync-wave`: Kyverno
(wave 0) before its policies (wave 1); Loki before promtail.

Each is added as its phase lands, so this directory stays in sync with what the
cluster actually runs.
