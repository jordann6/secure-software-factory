# Secure Software Factory

A production-quality platform engineering showcase demonstrating end-to-end supply chain security and zero-trust secrets management on AWS EKS.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Actions (CI)                                            │
│  build → sign (Cosign keyless) → SBOM attest → scan attest     │
│  → update image digest in Helm values → ArgoCD detects change  │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│  EKS                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │  Kyverno     │  │  Vault (HA)  │  │  Vault Secrets     │    │
│  │  - sig check │  │  - KMS unseal│  │  Operator          │    │
│  │  - SBOM check│  │  - K8s auth  │  │  - injects secrets │    │
│  │  - scan check│  │  - dynamic   │  │    into pods       │    │
│  └──────────────┘  │    AWS creds │  └────────────────────┘    │
│                    └──────────────┘                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  demo-app (namespace: demo)                              │   │
│  │  - blocked if image unsigned or unattested               │   │
│  │  - secrets injected from Vault, never in env vars        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Security properties

- Every image in production was built by this CI system (keyless Cosign, OIDC-pinned to this repo)
- Every image has an attached SBOM and a passing vulnerability scan attestation
- Kyverno enforces all three at the API server, with no exceptions
- Secrets are short-lived and issued only to pods that can prove their ServiceAccount identity via Vault's Kubernetes auth
- No static IAM keys anywhere; CI uses OIDC federation, Vault uses IRSA + KMS auto-unseal

## Prerequisites

- AWS account with permissions to create EKS, IAM, KMS, ECR
- Terraform >= 1.6
- kubectl, helm, argocd CLI
- GitHub repository (fork this repo or push to your own)

## Quickstart

### 1. Bootstrap state backend

Create an S3 bucket and DynamoDB table for Terraform state, then update `terraform/envs/dev/backend.tf`.

### 2. Apply infrastructure

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform apply
```

### 3. Bootstrap ArgoCD

```bash
# Get kubeconfig
aws eks update-kubeconfig --name secure-factory-dev --region us-east-1

# Install ArgoCD (one-time)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply the app-of-apps (after updating repo URL in the file)
kubectl apply -f platform/argocd/bootstrap/app-of-apps.yaml
```

### 4. Initialize Vault

```bash
# Port-forward to Vault
kubectl port-forward -n vault svc/vault 8200:8200

# Initialize (auto-unseal via KMS, so no unseal keys needed)
vault operator init -key-shares=1 -key-threshold=1

# Configure Vault via Terraform
cd platform/vault/config/terraform
terraform init
terraform apply
```

### 5. Set GitHub Actions variables

In your GitHub repo settings → Variables:
- `AWS_ROLE_ARN`: output from `terraform output github_actions_role_arn`

### 6. Break things (demo)

```bash
# Try deploying an unsigned image; Kyverno blocks it
kubectl run bad --image=nginx:latest -n demo

# Try accessing Vault without the right ServiceAccount; denied
```

## Repository layout

```
.github/workflows/      CI pipeline (build, sign, attest, update digest)
terraform/
  modules/              eks, ecr, vault (reusable modules)
  envs/dev/             root module wiring everything together
platform/
  argocd/               app-of-apps bootstrap + per-tool Applications
  vault/helm/           Vault Helm values
  vault/config/         Vault configuration via Terraform (post-install)
  kyverno/policies/     ClusterPolicy enforcement rules
policy/conftest/        OPA/Conftest rules for Dockerfile and Helm charts
apps/demo-app/          Sample app: Dockerfile, Go source, Helm chart
```

## Values you must substitute

The GitHub org and repo are already wired to this repository. The following are account-specific and must be filled in before applying:

| Placeholder | Where | Source |
| --- | --- | --- |
| `REPLACE_WITH_YOUR_STATE_BUCKET`, `REPLACE_WITH_YOUR_LOCK_TABLE` | `terraform/envs/dev/backend.tf` | The S3 bucket and DynamoDB table from step 1 |
| `REPLACE_WITH_VAULT_IRSA_ROLE_ARN`, `REPLACE_WITH_KMS_KEY_ID` | `platform/vault/helm/values.yaml` | `terraform output` after step 2 |
| `REPLACE_WITH_ECR_REGISTRY` | `apps/demo-app/helm/values.yaml` | `terraform output` after step 2 |

If you fork this repo, also update the `repoURL` fields under `platform/argocd/` and the Cosign `subject` fields in `platform/kyverno/policies/` to point at your fork, since the signature policies are pinned to this repository's workflow identity.
