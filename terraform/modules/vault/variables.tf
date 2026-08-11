variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider — used to scope Vault's IRSA trust policy"
}

variable "oidc_issuer" {
  type        = string
  description = "OIDC issuer hostname (without https://) — used as the IAM condition variable prefix"
}

variable "tags" {
  type    = map(string)
  default = {}
}
