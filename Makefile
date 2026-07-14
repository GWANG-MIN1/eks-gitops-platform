TF_DIR := terraform/environments/dev

.PHONY: help fmt validate init plan apply destroy \
	argocd-install argocd-root argocd-password argocd-ui

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform
	terraform fmt -recursive

validate: ## Validate the dev environment (no backend)
	cd $(TF_DIR) && terraform init -backend=false && terraform validate

init: ## Init the dev environment
	cd $(TF_DIR) && terraform init

plan: ## Plan the dev environment
	cd $(TF_DIR) && terraform plan

apply: ## Apply the dev environment
	cd $(TF_DIR) && terraform apply

destroy: ## Tear it all down (do this when you're done for the day!)
	cd $(TF_DIR) && terraform destroy

# ---- GitOps / ArgoCD (Phase 2) — needs a running cluster + kubeconfig ----

argocd-install: ## Install ArgoCD (pinned) — run once
	kubectl apply -k gitops/bootstrap/argocd
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

argocd-root: ## Hand the cluster to ArgoCD (apply app-of-apps root)
	kubectl apply -f gitops/bootstrap/root-app.yaml

argocd-password: ## Print the initial ArgoCD admin password
	kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath='{.data.password}' | base64 -d && echo

argocd-ui: ## Port-forward the ArgoCD UI to https://localhost:8080
	kubectl -n argocd port-forward svc/argocd-server 8080:443
