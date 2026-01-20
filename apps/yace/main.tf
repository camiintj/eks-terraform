# ===================================================================
# YACE (Yet Another CloudWatch Exporter) - IRSA CONFIGURATION
# ===================================================================
# IAM Role e Policies para YACE acessar CloudWatch e SQS via IRSA
# (IAM Roles for Service Accounts)
#
# YACE precisa de acesso a:
# - CloudWatch: GetMetricData, GetMetricStatistics, ListMetrics
# - Resource Groups Tagging API: GetResources (service discovery)
# - SQS: GetQueueAttributes, ListQueues (para métricas SQS)
# ===================================================================

# ===================================================================
# IAM ROLE PARA YACE (IRSA)
# ===================================================================

resource "aws_iam_role" "yace" {
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
      Name        = "eks-express-yace"
      Description = "IAM Role para YACE CloudWatch Exporter acessar CloudWatch e SQS via IRSA"
    }
  )
}

# ===================================================================
# IAM POLICY - CLOUDWATCH READ ACCESS
# ===================================================================

resource "aws_iam_policy" "cloudwatch_read" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-yace-cloudwatch-read"
  description = "Permite YACE ler métricas do CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "eks-express-yace-cloudwatch-read"
      Description = "Permite YACE ler métricas do CloudWatch"
    }
  )
}

# ===================================================================
# IAM POLICY - RESOURCE DISCOVERY VIA TAGS
# ===================================================================

resource "aws_iam_policy" "resource_discovery" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-yace-resource-discovery"
  description = "Permite YACE descobrir recursos AWS via tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ResourceDiscoveryViaTags"
        Effect = "Allow"
        Action = [
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "eks-express-yace-resource-discovery"
      Description = "Permite YACE descobrir recursos via tags"
    }
  )
}

# ===================================================================
# IAM POLICY - SQS METADATA ACCESS
# ===================================================================

resource "aws_iam_policy" "sqs_metadata" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-yace-sqs-metadata"
  description = "Permite YACE ler metadados e atributos de filas SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSMetadataAccess"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues",
          "sqs:ListQueueTags"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "eks-express-yace-sqs-metadata"
      Description = "Permite YACE ler atributos de filas SQS"
    }
  )
}

# ===================================================================
# IAM ROLE POLICY ATTACHMENTS
# ===================================================================

# Attach CloudWatch Read policy
resource "aws_iam_role_policy_attachment" "cloudwatch_read" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.yace[0].name
  policy_arn = aws_iam_policy.cloudwatch_read[0].arn
}

# Attach Resource Discovery policy
resource "aws_iam_role_policy_attachment" "resource_discovery" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.yace[0].name
  policy_arn = aws_iam_policy.resource_discovery[0].arn
}

# Attach SQS Metadata policy
resource "aws_iam_role_policy_attachment" "sqs_metadata" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.yace[0].name
  policy_arn = aws_iam_policy.sqs_metadata[0].arn
}
