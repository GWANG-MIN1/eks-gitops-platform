TF_DIR := terraform/environments/dev

.PHONY: help fmt validate init plan apply destroy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

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
