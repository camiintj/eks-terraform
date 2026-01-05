resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.20.0"
  namespace = "external-dns"
  create_namespace = true

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_dns.arn
    }
  ]

  depends_on = [ 
    aws_iam_role_policy_attachment.external_dns,
    aws_eks_node_group.this  ]
}




#https://github.com/kubernetes-sigs/external-dns/tree/master/docs/tutorials
#https://github.com/kubernetes-sigs/external-dns/tree/master