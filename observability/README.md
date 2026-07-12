# Observability

Metrics, dashboards, and logs for the platform — deployed *through* GitOps (see
[`../gitops`](../gitops)), not by hand, so the whole stack is reproducible.

## Planned stack (Phase 3)

| Concern | Tool |
|---------|------|
| Metrics + alerting | Prometheus + Alertmanager (kube-prometheus-stack) |
| Dashboards | Grafana |
| Logs | Loki + promtail |

## What lands here

- Helm values overrides for the stack (scrape configs, retention, resource limits).
- Baseline Grafana dashboards worth keeping.
- A small set of *meaningful* alerts (node pressure, pod crash-looping, cert expiry)
  rather than noisy defaults.

> Status: planned. Contents arrive with Phase 3.
