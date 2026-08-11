variable "repository_names" {
  type = list(string)
}

variable "ci_role_arn" {
  type        = string
  description = "IAM role ARN granted push access (GitHub Actions OIDC role)"
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
