# Security (DevSecOps)

Security guardrails that run automatically — in CI and as cluster admission policy —
rather than as a manual review step.

## Planned controls (Phase 4)

| Layer | Tool | What it catches |
|-------|------|-----------------|
| Image scanning | Trivy | Known CVEs in container images, in CI |
| Admission policy | Kyverno | `:latest` tags, missing resource limits, privileged pods |
| Benchmark | kube-bench | CIS Kubernetes Benchmark drift |
| Secrets | External Secrets / SSM | Keeps secrets out of Git and manifests |

## Principles

- **Shift left, but also enforce at runtime.** CI scanning catches issues early;
  Kyverno stops non-compliant workloads from ever being admitted.
- **No secrets in Git.** Ever. See the repo `.gitignore` and the secrets tooling above.

> Status: planned. Contents arrive with Phase 4.
