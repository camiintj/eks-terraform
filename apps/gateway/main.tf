# ===================================================================
# GATEWAY INFRASTRUCTURE - staging
# ===================================================================
# Infraestrutura para Gateway de Mensagens WhatsApp (Turn.io)
# - SQS FIFO Queues (Inbound/Outbound) com DLQ
# - S3 Bucket para auditoria com lifecycle policies
# - IAM Roles e Policies para acesso EKS
# ===================================================================

# ===================================================================
# SQS FIFO - INBOUND QUEUE
# ===================================================================

module "sqs_inbound" {
  source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/sqs?ref=main"

  name       = var.inbound_queue_name
  fifo_queue = true

  # FIFO Configuration
  content_based_deduplication = true
  deduplication_scope         = "queue"
  fifo_throughput_limit       = "perQueue"

  # Queue Behavior
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  max_message_size           = var.max_message_size
  sqs_managed_sse_enabled    = true

  # Dead Letter Queue
  create_dlq = true
  redrive_policy = {
    maxReceiveCount = var.dlq_max_receive_count
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "gateway-inbound"
      Queue       = "inbound"
      Description = "Fila FIFO para mensagens recebidas do Turn.io"
    }
  )
}

# ===================================================================
# SQS FIFO - OUTBOUND QUEUE
# ===================================================================

module "sqs_outbound" {
 source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/sqs?ref=main"

  name       = var.outbound_queue_name
  fifo_queue = true

  # FIFO Configuration
  content_based_deduplication = true
  deduplication_scope         = "queue"
  fifo_throughput_limit       = "perQueue"

  # Queue Behavior
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  max_message_size           = var.max_message_size
  sqs_managed_sse_enabled    = true

  # Dead Letter Queue
  create_dlq = true
  redrive_policy = {
    maxReceiveCount = var.dlq_max_receive_count
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "gateway-outbound"
      Queue       = "outbound"
      Description = "Fila FIFO para mensagens a serem enviadas ao Turn.io"
    }
  )
}

# ===================================================================
# S3 BUCKET - AUDIT LOGS
# ===================================================================

module "s3_audit_logs" {
  source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/s3?ref=main"

  bucket_name        = var.audit_bucket_name
  versioning_enabled = true
  sse_algorithm      = "AES256"

  # Lifecycle Policy para compliance (7 anos de retenção)
  lifecycle_rules = [
    {
      id      = "TransitionToIA"
      enabled = true

      transition = [
        {
          days          = var.lifecycle_transition_ia_days
          storage_class = "STANDARD_IA"
        },
        {
          days          = var.lifecycle_transition_glacier_days
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = var.lifecycle_expiration_days
      }
    },
    {
      id      = "CleanupIncompleteMultipart"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  tags = merge(
    var.common_tags,
    {
      Name           = "gateway-audit-logs"
      Purpose        = "audit-logs"
      Compliance     = "audit-logs"
      RetentionYears = "7"
      Description    = "Bucket S3 para armazenamento de logs de auditoria do Gateway"
    }
  )
}

# ===================================================================
# IAM ROLE PARA EKS WORKLOADS (IRSA)
# ===================================================================

resource "aws_iam_role" "gateway_workload" {
  count = var.create_iam_role ? 1 : 0

  name = "ne-${var.iam_role_name}"

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
      Name        = "gateway-eks-workload"
      Description = "IAM Role para workloads EKS do Gateway acessarem SQS e S3"
    }
  )
}

# ===================================================================
# IAM POLICY - SQS ACCESS
# ===================================================================

resource "aws_iam_policy" "sqs_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "ne-gateway-sqs-access"
  description = "Permite acesso às filas SQS do Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GatewaySQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          module.sqs_inbound.queue_arn,
          module.sqs_outbound.queue_arn,
          module.sqs_inbound.dead_letter_queue_arn,
          module.sqs_outbound.dead_letter_queue_arn
        ]
      },
      {
        Sid      = "GatewaySQSList"
        Effect   = "Allow"
        Action   = ["sqs:ListQueues"]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# IAM POLICY - S3 ACCESS
# ===================================================================

resource "aws_iam_policy" "s3_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "ne-gateway-s3-access"
  description = "Permite acesso ao bucket S3 de auditoria do Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GatewayS3AuditAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_audit_logs.bucket_arn,
          "${module.s3_audit_logs.bucket_arn}/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# ATTACH POLICIES TO ROLE
# ===================================================================

resource "aws_iam_role_policy_attachment" "sqs_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.gateway_workload[0].name
  policy_arn = aws_iam_policy.sqs_access[0].arn
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.gateway_workload[0].name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# ===================================================================
# ECR REPOSITORIES
# ===================================================================
# Repositórios para armazenar imagens Docker das aplicações

# Gateway API (FastAPI)
module "ecr_api" {
  source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/ecr?ref=main"

  name        = "gateway-api"
  prefix      = "ne"
  environment = var.environment

  # Scan de vulnerabilidades
  scan_on_push = true

  # Lifecycle - manter últimas 50 imagens
  max_image_count                = 50
  untagged_image_expiration_days = 3

  tags = {
    Name        = "gateway-api"
    Component   = "api"
    Description = "Repositorio ECR para imagens da API Gateway FastAPI"
    Application = "gateway"
    Project     = "gateway"
    Team        = "backend"
    # ManagedBy é adicionado pelo módulo
    # Environment é adicionado pelo módulo via var.environment
  }
}

# Gateway Worker Outbound
module "ecr_worker_outbound" {
  source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/ecr?ref=main"

  name        = "gateway-worker-outbound"
  prefix      = "ne"
  environment = var.environment

  # Scan de vulnerabilidades
  scan_on_push = true

  # Lifecycle - manter últimas 30 imagens
  max_image_count                = 30
  untagged_image_expiration_days = 3

  tags = {
    Name        = "gateway-worker-outbound"
    Component   = "worker"
    Description = "Repositorio ECR para imagens do Worker Outbound"
    Application = "gateway"
    Project     = "gateway"
    Team        = "backend"
    # ManagedBy é adicionado pelo módulo
    # Environment é adicionado pelo módulo via var.environment
  }
}

# ===================================================================
# IAM POLICY - ECR ACCESS
# ===================================================================
# Permite que CI/CD faça push de imagens para o ECR

resource "aws_iam_policy" "ecr_push" {
  count = var.create_iam_role ? 1 : 0

  name        = "ne-gateway-ecr-push"
  description = "Permite push de imagens Docker para ECR do Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GatewayECRPushAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          module.ecr_api.repository_arn,
          module.ecr_worker_outbound.repository_arn
        ]
      },
      {
        Sid      = "GetAuthorizationToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# Attach ECR policy to role (opcional - para CI/CD pode ser role separada)
resource "aws_iam_role_policy_attachment" "ecr_push" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.gateway_workload[0].name
  policy_arn = aws_iam_policy.ecr_push[0].arn
}

# ===================================================================
# SECRETS MANAGER
# ===================================================================
# Secret único para todas as credenciais do Gateway

module "gateway_secret" {
  source = "git::https://github.com/novaescolaorg/ne-terraform-modules.git//modules/secrets-manager?ref=main"

  name         = "gateway"
  description  = "All secrets for Gateway WhatsApp application - used by gateway-api and worker-outbound pods"
  cluster_name = "ne-stg-eks"
  environment  = var.environment

  # Cria secret com placeholder para todas as envs
  create_placeholder = true
  secret_json = {
    # Turn.io API
    TURNIO_API_TOKEN = "CHANGE_ME"
    TURNIO_API_URL   = "https://whatsapp.turn.io"

    # AWS Resources (podem ser obtidos do Terraform outputs também)
    SQS_INBOUND_QUEUE  = module.sqs_inbound.queue_name
    SQS_OUTBOUND_QUEUE = module.sqs_outbound.queue_name
    S3_AUDIT_BUCKET    = module.s3_audit_logs.bucket_id
    AWS_REGION         = "us-east-1"

    # Application configs
    LOG_LEVEL   = "INFO"
    ENVIRONMENT = "staging"
  }

  # Recovery window de 30 dias para produção
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    var.common_tags,
    {
      Name        = "gateway-all-credentials"
      SecretType  = "application-config"
      Description = "All configuration and credentials for Gateway application"
    }
  )
}
