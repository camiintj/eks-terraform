resource "aws_eks_addon" "container_storage_interface" {
  cluster_name              = aws_eks_cluster.this.name
  addon_name                = "aws-ebs-csi-driver"
  addon_version             = "v1.54.0-eksbuild.1"
  service_account_role_arn  = aws_iam_role.container_storage_interface.arn
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_iam_role" "container_storage_interface" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.kubernetes.arn
      }
    Condition = {
        StringEquals = {
          "${local.eks_oidc_url}:aud" = "sts.amazonaws.com"
          "${local.eks_oidc_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
   Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "container_storage_interface_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.container_storage_interface.name
}

#aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --region us-east-1
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
#https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html
#https://github.com/kubernetes-sigs/
#https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html#csi-iam-role