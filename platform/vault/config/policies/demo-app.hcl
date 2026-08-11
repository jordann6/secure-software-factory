path "secret/data/demo-app/*" {
  capabilities = ["read"]
}

path "secret/metadata/demo-app/*" {
  capabilities = ["read", "list"]
}

path "aws/creds/demo-app" {
  capabilities = ["read"]
}
