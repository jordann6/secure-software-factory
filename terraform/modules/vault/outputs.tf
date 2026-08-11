output "kms_key_id" {
  value = aws_kms_key.vault.key_id
}

output "kms_key_arn" {
  value = aws_kms_key.vault.arn
}

output "irsa_role_arn" {
  value = aws_iam_role.vault.arn
}
