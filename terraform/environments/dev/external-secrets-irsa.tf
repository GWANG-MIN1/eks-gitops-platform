# IRSA role for the External Secrets Operator (Phase 4).
#
# This is the payoff for the OIDC provider stood up in Phase 1: the ESO controller
# pod assumes this role via its ServiceAccount token — no static AWS keys anywhere.
# The role can read the SSM parameters under /eks-gitops/dev/ and decrypt them.
#
# IAM lives in Terraform (it's cloud state), the in-cluster ServiceAccount
# annotation lives in GitOps — see security/external-secrets/values.yaml. The role
# ARN below is the handoff between the two.

data "aws_caller_identity" "current" {}

locals {
  # ServiceAccount that assumes the role: <namespace>:<name> from the ESO chart.
  external_secrets_sa = "system:serviceaccount:external-secrets:external-secrets"

  # Parameter namespace ESO is allowed to read.
  ssm_parameter_prefix = "eks-gitops/${var.environment}"
}

data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = [local.external_secrets_sa]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  statement {
    sid    = "ReadSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.ssm_parameter_prefix}/*",
    ]
  }

  statement {
    sid       = "DecryptSecureStrings"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    # Only when KMS is called on behalf of SSM in this region — not a blanket
    # decrypt grant.
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  name   = "${var.cluster_name}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}
