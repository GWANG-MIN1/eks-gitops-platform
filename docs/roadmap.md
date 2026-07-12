# Roadmap

A phased build. Each phase is independently `apply`-able and leaves the repo in a
working state. Checkboxes are updated as work lands so the status is always honest.

## Phase 1 — Terraform foundation 🚧

Goal: `terraform apply` in `environments/dev` brings up a reachable EKS cluster.

- [ ] Remote state backend (S3 + DynamoDB lock)
- [ ] VPC module (public/private subnets, NAT, ≥2 AZs)
- [ ] EKS module (control plane + managed node group)
- [ ] IAM roles for service accounts (IRSA) baseline
- [ ] `terraform fmt` / `validate` green in CI

## Phase 2 — GitOps with ArgoCD ⬜

Goal: cluster state is declared in Git and reconciled automatically.

- [ ] Install ArgoCD (bootstrap manifest)
- [ ] App-of-apps root Application
- [ ] Deploy a sample workload via GitOps
- [ ] Document the push → sync flow

## Phase 3 — Observability ⬜

Goal: metrics, dashboards, and logs available without manual setup.

- [ ] kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
- [ ] Loki for log aggregation
- [ ] Baseline dashboards and a couple of meaningful alerts

## Phase 4 — DevSecOps ⬜

Goal: security guardrails run automatically, not as an afterthought.

- [ ] Trivy image scanning in CI
- [ ] Kyverno admission policies (no `:latest`, resource limits required, etc.)
- [ ] kube-bench CIS benchmark run
- [ ] Secrets handling (External Secrets / SSM)

---

### Guardrails I'm holding myself to

- **Destroy daily.** EKS is not free — spin up to learn, tear down to sleep.
- **Every phase leaves `main` green.** No half-broken merges.
- **Honest status.** Checkboxes reflect what actually works, not what's planned.
