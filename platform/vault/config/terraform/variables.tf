variable "kubernetes_host" {
  type        = string
  description = "EKS API server endpoint — from: terraform output cluster_endpoint"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
