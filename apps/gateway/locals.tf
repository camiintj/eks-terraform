# ===================================================================
# LOCAL VARIABLES - eks-express
# ===================================================================

locals {
  # OIDC Provider do cluster EKS (remove o prefixo https://)
  oidc_provider = replace(data.terraform_remote_state.eks.outputs.kubernetes_oidc_provider_url, "https://", "")

  # ARN do OIDC provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.kubernetes_oidc_provider_arn

  # Kubernetes namespace e service account
  k8s_namespace       = "gateway"
  k8s_service_account = "gateway-sa"
}
