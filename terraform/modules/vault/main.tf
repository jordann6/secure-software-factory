resource "aws_kms_key" "vault" {
  description             = "Vault auto-unseal — ${var.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.cluster_name}-vault"
  target_key_id = aws_kms_key.vault.key_id
}

data "aws_iam_policy_document" "vault_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:sub"
      values   = ["system:serviceaccount:vault:vault"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vault" {
  name               = "${var.cluster_name}-vault-role"
  assume_role_policy = data.aws_iam_policy_document.vault_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "vault_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.vault.arn]
  }
}

resource "aws_iam_policy" "vault_kms" {
  name   = "${var.cluster_name}-vault-kms-policy"
  policy = data.aws_iam_policy_document.vault_kms.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "vault_kms" {
  policy_arn = aws_iam_policy.vault_kms.arn
  role       = aws_iam_role.vault.name
}
