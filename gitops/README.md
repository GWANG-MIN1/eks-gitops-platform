# GitOps

The cluster's desired state lives here. ArgoCD watches this directory and reconciles
the cluster to match it — Git is the source of truth.

## App-of-apps

```
gitops/
├── bootstrap/
│   └── root-app.yaml     # the one Application you apply by hand
└── apps/                 # child Applications, each owning one concern
    ├── observability/    # (Phase 3) prometheus / grafana / loki
    ├── security/         # (Phase 4) kyverno policies, etc.
    └── sample-app/       # (Phase 2) a demo workload to prove the flow
```

`root-app.yaml` is the only thing applied manually. It points ArgoCD at `apps/`, and
every child Application there is then managed automatically — add a workload by
committing a new Application manifest, not by running `kubectl`.

## Bootstrap (Phase 2)

```bash
# Install ArgoCD (once)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Hand ArgoCD the keys to the kingdom
kubectl apply -f bootstrap/root-app.yaml
```

From then on, `git push` is the deploy mechanism.
