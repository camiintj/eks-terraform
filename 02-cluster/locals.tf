locals {
    admin_user_arn = "arn:aws:iam::005988779053:user/eksexpress"
    eks_oidc_url = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")

}