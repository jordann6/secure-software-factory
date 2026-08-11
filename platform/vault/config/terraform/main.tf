provider "vault" {
  # Set VAULT_ADDR and VAULT_TOKEN in your environment before running
}

resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  description = "KV v2 secrets"
  options     = { version = "2" }
}

resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  description = "Kubernetes auth for EKS workloads"
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = var.kubernetes_host
  # Vault auto-discovers the CA cert and JWT reviewer token when running inside the cluster
}

resource "vault_policy" "demo_app" {
  name   = "demo-app"
  policy = file("${path.module}/../policies/demo-app.hcl")
}

resource "vault_kubernetes_auth_backend_role" "demo_app" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "demo-app"
  bound_service_account_names      = ["demo-app"]
  bound_service_account_namespaces = ["demo"]
  token_policies                   = [vault_policy.demo_app.name]
  token_ttl                        = 3600
}

resource "vault_aws_secret_backend" "aws" {
  path        = "aws"
  description = "Dynamic AWS credentials"
  region      = var.aws_region
}

resource "vault_aws_secret_backend_role" "demo_app" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "demo-app"
  credential_type = "iam_user"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["*"]
      }
    ]
  })
}

# Seed an example static secret — replace with real values via CI or manually
resource "vault_kv_secret_v2" "demo_app" {
  mount     = vault_mount.kv.path
  name      = "demo-app/config"
  data_json = jsonencode({
    api_key     = "change-me-in-vault"
    environment = "dev"
  })
}
