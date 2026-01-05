resource "helm_release" "load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0"
  namespace = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.this.id
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.load_balancer_controller.arn
    },
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "serviceAccoount.name"
      value = "aws-load-balancer-controller"
    }
  ]

  depends_on = [ 
    aws_iam_role_policy_attachment.load_balancer_controller,
    aws_eks_node_group.this
   ]
}




#https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
#https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/
#https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release