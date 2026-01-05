resource "aws_eks_addon" "metrics_server" {
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "metrics-server"
  addon_version     = "v0.8.0-eksbuild.6"
}









#aws eks describe-addon-versions --addon-name metrics-server --region us-east-1
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
#https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html
#https://github.com/kubernetes-sigs/