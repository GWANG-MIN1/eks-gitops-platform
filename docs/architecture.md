# Architecture

This document captures the target design and the reasoning behind it. It is a living
document — sections get filled in as each phase is implemented.

## Overview

The platform is split into four layers, each owned by a different tool so
responsibilities stay clean:

| Layer | Owned by | Responsibility |
|-------|----------|----------------|
| Infrastructure | Terraform | VPC, EKS control plane, node groups, IAM |
| Delivery | ArgoCD (GitOps) | Reconcile in-cluster state from Git |
| Observability | Prometheus / Grafana / Loki | Metrics, dashboards, logs, alerts |
| Security | Trivy / Kyverno / kube-bench | Image scanning, admission policy, CIS checks |

## Why this split

- **Terraform stops at the cluster boundary.** It provisions the EKS cluster and the
  cloud resources around it (VPC, IAM, node groups) — but it does *not* manage
  in-cluster workloads. That job belongs to GitOps. Mixing the two (e.g. deploying
  Helm releases from Terraform) couples slow cloud state to fast app state and makes
  rollbacks painful.
- **ArgoCD owns everything inside the cluster** via an *app-of-apps* pattern: a single
  root `Application` points at `gitops/apps/`, and each child Application manages one
  concern (observability stack, security stack, sample workload). Git is the single
  source of truth; a `git revert` is a rollback.
- **Observability and security are add-ons deployed *through* GitOps**, not bolted on
  by hand — so they are reproducible and auditable like everything else.

## Network design (Phase 1)

- One VPC with public and private subnets across ≥2 AZs.
- EKS nodes live in **private** subnets; only load balancers sit in public subnets.
- NAT gateway for outbound; VPC endpoints considered later to cut NAT cost.

## Delivery flow (Phase 2)

```
developer → git push → ArgoCD detects drift → sync → cluster converges
```

## Open questions / decisions to revisit

- Managed node groups vs. Karpenter for autoscaling.
- Kyverno vs. OPA/Gatekeeper for admission policy.
- Loki storage backend (S3) sizing and retention.

_These are deliberately left open — they get answered as the corresponding phase is built._
