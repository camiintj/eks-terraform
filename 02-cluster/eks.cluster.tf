resource "aws_eks_cluster" "this" {
  name      = var.eks_cluster.name
  version   = var.eks_cluster.version
  role_arn  = aws_iam_role.eks_cluster.arn

  enabled_cluster_log_types = var.eks_cluster.enabled_cluster_log_types
  access_config {
    authentication_mode = var.eks_cluster.access_config.authentication_mode
  }

  vpc_config {
    subnet_ids = data.aws_subnets.private.ids
  }
  

  

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]
}

