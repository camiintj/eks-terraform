# ===================================================================
# EXTERNAL-DNS - IRSA CONFIGURATION
# ===================================================================
# IAM Role e Policies para External DNS acessar recursos AWS via IRSA
# (IAM Roles for Service Accounts)
#
# External DNS precisa de acesso a:
# - Route53: ChangeResourceRecordSets para gerenciar registros DNS
# ===================================================================

# ===================================================================
# IAM ROLE PARA EXTERNAL-DNS (IRSA)
# ===================================================================

resource "aws_iam_role" "external_dns" {
  count = var.create_iam_role ? 1 : 0

  name = "eks-express-${var.iam_role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:${local.k8s_namespace}:${local.k8s_service_account}"
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "eks-express-external-dns"
      Description = "IAM Role para External DNS gerenciar registros Route53 via IRSA"
    }
  )
}

# ===================================================================
# IAM POLICY - ROUTE53 ACCESS
# ===================================================================
# External DNS precisa de permissão para criar/atualizar/deletar registros DNS

resource "aws_iam_policy" "route53_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-external-dns-route53"
  description = "Permite External DNS gerenciar registros Route53"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ExternalDNSRoute53Change"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = formatlist("arn:aws:route53:::hostedzone/%s", var.route53_hosted_zones)
      },
      {
        Sid    = "ExternalDNSRoute53List"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# ATTACH POLICY TO ROLE
# ===================================================================

resource "aws_iam_role_policy_attachment" "route53_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.route53_access[0].arn
}
