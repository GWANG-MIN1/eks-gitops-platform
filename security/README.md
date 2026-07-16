# Security (DevSecOps)

Security guardrails that run automatically — in CI and as cluster policy — rather
than as a manual review step.

## What runs (Phase 3→4)

| Layer | Tool | Where | What it does |
|-------|------|-------|--------------|
| Image scanning | Trivy | CI ([`security-ci.yml`](../.github/workflows/security-ci.yml)) | Fails the build on fixable CRITICAL CVEs; reports HIGH |
| IaC scanning | Trivy config | CI | Flags misconfigured Terraform / manifests (report-only) |
| Admission policy | Kyverno | cluster ([`kyverno/`](kyverno)) | Blocks/flags non-compliant pods |
| Benchmark | kube-bench | on demand ([`kube-bench/`](kube-bench)) | CIS EKS Benchmark report |
| Secrets | External Secrets | cluster ([`external-secrets/`](external-secrets)) | Pulls secrets from AWS SSM — refs in Git, values in AWS |

Kyverno and External Secrets are deployed through GitOps (`gitops/apps/`); their
Helm values and policies live here.

## Kyverno policies

Four ClusterPolicies, all in **Audit** mode to start:

- `disallow-latest-tag` — explicit image tag required, no `:latest`
- `require-resources` — CPU/memory requests + a memory limit (no CPU limit, on
  purpose — same call as the observability stack)
- `require-run-as-non-root` — `runAsNonRoot=true`
- `restrict-privileges` — no privilege escalation, not privileged, drop ALL caps

**Audit, then enforce.** New policies land in Audit so you can see what they'd
break before they break it — slamming Enforce on a live cluster is how platform
teams lose trust. Flip `validate.failureAction` to `Enforce` per policy once the
audit reports are clean.

**Scope.** Infrastructure namespaces (`kube-system`, `argocd`, `observability`,
`kyverno`, `external-secrets`, `kube-bench`, …) are excluded — their components
are managed upstream and don't all meet the restricted baseline. The policies
target *our* workloads. The Phase 2 `sample-app` was built to pass all four.

## kube-bench

On-demand, not GitOps-managed (it's a Job that completes, not a service):

```bash
make kube-bench   # apply, wait, print the report, clean up
```

Some FAIL/WARN results on EKS are expected and not actionable — the control plane
is AWS-managed, so control-plane checks can't be remediated from here. Read it for
the node and policy findings.

## External Secrets → AWS SSM

The pattern that keeps secrets out of Git: a reference lives in the repo, the
value lives in SSM Parameter Store, and the operator syncs it into a Kubernetes
Secret.

The operator is installed via GitOps. The account-specific pieces are set up once:

1. **IRSA role** — created by Terraform
   ([`external-secrets-irsa.tf`](../terraform/environments/dev/external-secrets-irsa.tf)),
   SSM read-only, scoped to `/eks-gitops/dev/*`. Annotate the operator's
   ServiceAccount with its ARN (`terraform output external_secrets_irsa_role_arn`).
2. **SecretStore + ExternalSecret** — see [`external-secrets/examples/`](external-secrets/examples),
   which also closes the Phase 3 loose end (Grafana's admin password → SSM).

## Principles

- **Shift left, and enforce at runtime.** CI scanning catches issues early;
  Kyverno stops non-compliant workloads at admission.
- **No secrets in Git. Ever.** See the repo `.gitignore` and External Secrets above.
