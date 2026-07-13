terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Intentionally NO backend block: this config bootstraps the remote-state
  # backend itself, so it keeps its own state locally (bootstrap/terraform.tfstate).
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "eks-gitops-platform"
      Component = "tfstate-backend"
      ManagedBy = "terraform"
    }
  }
}
