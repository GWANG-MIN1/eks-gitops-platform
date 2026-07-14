# GitOps

The cluster's desired state lives here. ArgoCD watches this directory and reconciles
the cluster to match it — Git is the source of truth, and `git revert` is a rollback.

## App-of-apps

```
gitops/
├── bootstrap/
│   ├── argocd/           # pinned ArgoCD install (kustomize) — applied by hand once
│   └── root-app.yaml     # the one Application you apply by hand
└── apps/                 # child Applications, each owning one concern
    ├── sample-app.yaml   # (Phase 2) demo workload — proves the loop ✅
    ├── sample-app/       #           its manifests (deployment, service)
    ├── observability/    # (Phase 3) prometheus / grafana / loki
    └── security/         # (Phase 4) kyverno policies, etc.
```

`root-app.yaml` is the only Application applied manually. It points ArgoCD at `apps/`
(non-recursive), so each `*.yaml` there is a child Application ArgoCD then manages
automatically. Add a workload by committing a new Application manifest — not by
running `kubectl`.

## Bootstrap (Phase 2)

Two manual steps, once per cluster. Everything after that flows through Git.

```bash
# 1. Install ArgoCD (pinned version — see bootstrap/argocd/kustomization.yaml)
kubectl apply -k gitops/bootstrap/argocd
kubectl -n argocd rollout status deploy/argocd-server

# 2. Hand ArgoCD the keys: the app-of-apps root
kubectl apply -f gitops/bootstrap/root-app.yaml
```

Or via the Makefile: `make argocd-install && make argocd-root`.

## The GitOps loop

Once bootstrapped, deploying is just `git push`:

```
edit a manifest → git commit && git push → ArgoCD detects drift → sync → cluster converges
```

- **Automated sync** (`syncPolicy.automated`) means you don't click "Sync" — ArgoCD
  applies the new desired state on its own.
- **selfHeal** reverts manual `kubectl` edits back to what Git says.
- **prune** deletes resources you removed from Git.

### Verify it works

```bash
# Watch the Applications reconcile
kubectl -n argocd get applications
# root and sample-app should both go Synced / Healthy

# Reach the demo workload (ClusterIP — no public URL yet, by design)
kubectl -n sample-app port-forward svc/sample-app 8080:80
# then open http://localhost:8080

# See the loop close: bump replicas in apps/sample-app/deployment.yaml,
# push, and watch the new pods appear without touching kubectl.
kubectl -n sample-app get pods -w
```

The ArgoCD UI shows the same thing visually: `make argocd-ui` (then
`make argocd-password` for the initial admin login).
