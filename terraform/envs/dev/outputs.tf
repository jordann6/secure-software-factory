output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "vault_kms_key_id" {
  value       = module.vault.kms_key_id
  description = "Paste this into platform/vault/helm/values.yaml under VAULT_KMS_KEY_ID"
}

output "vault_irsa_role_arn" {
  value       = module.vault.irsa_role_arn
  description = "Paste this into platform/vault/helm/values.yaml under eks.amazonaws.com/role-arn"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Set this as the AWS_ROLE_ARN variable in your GitHub repo settings"
}
