resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.9.0"
  namespace = "kube-system"
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  values = [
    templatefile("${path.module}/helm/values.yaml", {
        NODEGROUP          = local.eks_cluster_node_group_name
        CLUSTER_NAME       = local.eks_cluster_name
        KARPENTER_ROLE_ARN = aws_iam_role.karpenter_controller.arn
    })
  ]


depends_on = [ 
    terraform_data.karpenter_crds,
    aws_iam_role_policy_attachment.karpenter_controller_custom_policy
 ]

}





#https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#https://karpenter.sh/docs/getting-started/migrating-from-cas/