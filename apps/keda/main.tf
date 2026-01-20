# ===================================================================
# KEDA OPERATOR - IRSA CONFIGURATION
# ===================================================================
# IAM Role e Policies para KEDA Operator acessar recursos AWS via IRSA
# (IAM Roles for Service Accounts)
#
# KEDA precisa de acesso a:
# - SQS: GetQueueAttributes, GetQueueUrl, ListQueues (para SQS scaler)
# - CloudWatch: GetMetricStatistics (para CloudWatch scaler - opcional)
# ===================================================================

# ===================================================================
# IAM ROLE PARA KEDA OPERATOR (IRSA)
# ===================================================================

resource "aws_iam_role" "keda_operator" {
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
      Name        = "eks-express-keda-operator"
      Description = "IAM Role para KEDA Operator acessar SQS e CloudWatch via IRSA"
    }
  )
}

# ===================================================================
# IAM POLICY - SQS ACCESS (READ-ONLY)
# ===================================================================
# KEDA precisa apenas de permissões de leitura para monitorar filas

resource "aws_iam_policy" "sqs_read" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-keda-sqs-read"
  description = "Permite KEDA ler métricas de filas SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KEDASQSReadAccess"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues",
          "sqs:ListQueueTags"
        ]
        Resource = [
          "arn:aws:sqs:${local.region}:${local.account_id}:${var.sqs_queue_pattern}"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# IAM POLICY - CLOUDWATCH ACCESS (OPCIONAL)
# ===================================================================
# Permite KEDA usar CloudWatch metrics como trigger
# Comentado por padrão - descomentar se necessário

# resource "aws_iam_policy" "cloudwatch_read" {
#   count = var.create_iam_role ? 1 : 0
#
#   name        = "ne-keda-cloudwatch-read"
#   description = "Permite KEDA ler métricas do CloudWatch"
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "KEDACloudWatchReadAccess"
#         Effect = "Allow"
#         Action = [
#           "cloudwatch:GetMetricStatistics",
#           "cloudwatch:GetMetricData",
#           "cloudwatch:ListMetrics"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
#
#   tags = var.common_tags
# }

# ===================================================================
# ATTACH POLICIES TO ROLE
# ===================================================================

resource "aws_iam_role_policy_attachment" "sqs_read" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.keda_operator[0].name
  policy_arn = aws_iam_policy.sqs_read[0].arn
}

# resource "aws_iam_role_policy_attachment" "cloudwatch_read" {
#   count = var.create_iam_role ? 1 : 0
#
#   role       = aws_iam_role.keda_operator[0].name
#   policy_arn = aws_iam_policy.cloudwatch_read[0].arn
# }
