# Observability

Metrics, dashboards, and logs for the platform — deployed *through* GitOps (see
[`../gitops`](../gitops)), not by hand, so the whole stack is reproducible.

This directory holds only the **Helm values**. The `Application` manifests that
consume them live in [`../gitops/apps/`](../gitops/apps), because that's what
ArgoCD watches.

## The stack (Phase 3)

| Concern | Tool | Chart | Values |
|---------|------|-------|--------|
| Metrics + alerting | Prometheus + Alertmanager | `kube-prometheus-stack` `87.16.1` | [`kube-prometheus-stack/values.yaml`](kube-prometheus-stack/values.yaml) |
| Dashboards | Grafana (bundled) | ↑ | ↑ |
| Alerts | PrometheusRule | ↑ | [`kube-prometheus-stack/alerts.yaml`](kube-prometheus-stack/alerts.yaml) |
| Log storage | Loki (SingleBinary) | `loki` `6.55.0` | [`loki/values.yaml`](loki/values.yaml) |
| Log collection | promtail (DaemonSet) | `promtail` `6.17.1` | [`promtail/values.yaml`](promtail/values.yaml) |

Charts are pulled from their upstream Helm repos and pinned; only the overrides
are in Git. Grafana gets Loki as a datasource automatically, so metrics and logs
sit side by side.

## Decisions worth knowing

**EKS has no scrapeable control plane.** etcd, the scheduler, and the
controller-manager are AWS-managed and unreachable, so their scrape targets and
alert rules are disabled. Left on, they'd sit permanently red and train you to
ignore the alerts — the most common way monitoring dies.

**Nothing is persisted.** No PVCs anywhere: Prometheus, Grafana, Alertmanager, and
Loki all use ephemeral storage. The EBS CSI driver isn't installed on this
cluster, so a PVC would sit `Pending` forever — and the cluster is destroyed
daily anyway. Making this durable is a real piece of work (EBS CSI addon, or S3 +
IRSA for Loki), not a flag.

**Few alerts, on purpose.** The chart's kubernetes-mixin rules already cover
crash-looping pods, node pressure, and full volumes. `alerts.yaml` only adds what
upstream can't know: whether Git and the cluster agree (ArgoCD sync/health) and
whether the delivery path actually delivers (sample-app).

**Grafana's password isn't in Git.** The chart default is used as-is for a
port-forward-only stack; Phase 4 moves it to External Secrets.

## Have a look

```bash
# Grafana — dashboards + logs (default login: admin / prom-operator)
kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000

# Prometheus — targets and alert rules
kubectl -n observability port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# http://localhost:9090/targets

# Logs, without leaving Grafana: Explore -> Loki -> {namespace="sample-app"}
```

> **Capacity note.** This stack roughly doubles what the cluster is running. Two
> `t3.medium` SPOT nodes fit it, but not with much room — if pods sit `Pending`,
> raise `node_desired_size` (or move to `t3.large`) in
> `terraform/environments/dev`.
