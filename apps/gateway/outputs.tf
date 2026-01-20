# ===================================================================
# OUTPUTS - GATEWAY INFRASTRUCTURE
# ===================================================================

# ===================================================================
# SQS OUTPUTS
# ===================================================================

output "sqs_inbound_queue_url" {
  description = "URL da fila SQS inbound"
  value       = module.sqs_inbound.queue_url
}

output "sqs_inbound_queue_arn" {
  description = "ARN da fila SQS inbound"
  value       = module.sqs_inbound.queue_arn
}

output "sqs_inbound_queue_name" {
  description = "Nome da fila SQS inbound"
  value       = module.sqs_inbound.queue_name
}

output "sqs_inbound_dlq_url" {
  description = "URL da DLQ inbound"
  value       = module.sqs_inbound.dead_letter_queue_url
}

output "sqs_inbound_dlq_arn" {
  description = "ARN da DLQ inbound"
  value       = module.sqs_inbound.dead_letter_queue_arn
}

output "sqs_outbound_queue_url" {
  description = "URL da fila SQS outbound"
  value       = module.sqs_outbound.queue_url
}

output "sqs_outbound_queue_arn" {
  description = "ARN da fila SQS outbound"
  value       = module.sqs_outbound.queue_arn
}

output "sqs_outbound_queue_name" {
  description = "Nome da fila SQS outbound"
  value       = module.sqs_outbound.queue_name
}

output "sqs_outbound_dlq_url" {
  description = "URL da DLQ outbound"
  value       = module.sqs_outbound.dead_letter_queue_url
}

output "sqs_outbound_dlq_arn" {
  description = "ARN da DLQ outbound"
  value       = module.sqs_outbound.dead_letter_queue_arn
}

# ===================================================================
# S3 OUTPUTS
# ===================================================================

output "s3_audit_bucket_id" {
  description = "Nome do bucket S3 de auditoria"
  value       = module.s3_audit_logs.bucket_id
}

output "s3_audit_bucket_arn" {
  description = "ARN do bucket S3 de auditoria"
  value       = module.s3_audit_logs.bucket_arn
}

output "s3_audit_bucket_domain_name" {
  description = "Domain name do bucket S3 de auditoria"
  value       = module.s3_audit_logs.bucket_domain_name
}

# ===================================================================
# IAM OUTPUTS
# ===================================================================

output "iam_role_arn" {
  description = "ARN da IAM Role para workloads EKS"
  value       = var.create_iam_role ? aws_iam_role.gateway_workload[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para workloads EKS"
  value       = var.create_iam_role ? aws_iam_role.gateway_workload[0].name : null
}

output "sqs_policy_arn" {
  description = "ARN da policy SQS"
  value       = var.create_iam_role ? aws_iam_policy.sqs_access[0].arn : null
}

output "s3_policy_arn" {
  description = "ARN da policy S3"
  value       = var.create_iam_role ? aws_iam_policy.s3_access[0].arn : null
}

# ===================================================================
# KUBERNETES CONFIGURATION
# ===================================================================

output "k8s_service_account_annotation" {
  description = "Anotação para adicionar ao ServiceAccount Kubernetes"
  value       = var.create_iam_role ? "eks.amazonaws.com/role-arn: ${aws_iam_role.gateway_workload[0].arn}" : null
}

# ===================================================================
# ECR OUTPUTS
# ===================================================================

output "ecr_api_repository_url" {
  description = "URL do repositório ECR para Gateway API"
  value       = module.ecr_api.repository_url
}

output "ecr_api_repository_arn" {
  description = "ARN do repositório ECR para Gateway API"
  value       = module.ecr_api.repository_arn
}

output "ecr_worker_outbound_repository_url" {
  description = "URL do repositório ECR para Worker Outbound"
  value       = module.ecr_worker_outbound.repository_url
}

output "ecr_worker_outbound_repository_arn" {
  description = "ARN do repositório ECR para Worker Outbound"
  value       = module.ecr_worker_outbound.repository_arn
}

output "ecr_docker_login_command" {
  description = "Comando para fazer login no ECR"
  value       = module.ecr_api.docker_login_command
}

output "ecr_api_image_uri_latest" {
  description = "URI completo da imagem API com tag latest (para Kubernetes)"
  value       = module.ecr_api.image_uri_latest
}

output "ecr_worker_image_uri_latest" {
  description = "URI completo da imagem Worker com tag latest (para Kubernetes)"
  value       = module.ecr_worker_outbound.image_uri_latest
}

# ===================================================================
# SECRETS MANAGER OUTPUTS
# ===================================================================

output "gateway_secret_name" {
  description = "Nome completo do secret Gateway no Secrets Manager"
  value       = module.gateway_secret.secret_name
}

output "gateway_secret_arn" {
  description = "ARN do secret Gateway no Secrets Manager"
  value       = module.gateway_secret.secret_arn
}

output "populate_gateway_secret_command" {
  description = "Comando para popular o secret Gateway com valores reais"
  value       = <<-EOT
    # Popular secret com TODAS as variáveis de ambiente do Gateway:
    aws secretsmanager put-secret-value \
      --secret-id ne-stg-eks/gateway \
      --secret-string '{
        "TURNIO_API_TOKEN": "YOUR_REAL_TOKEN_HERE",
        "TURNIO_API_URL": "https://whatsapp.turn.io",
        "SQS_INBOUND_QUEUE": "${module.sqs_inbound.queue_name}",
        "SQS_OUTBOUND_QUEUE": "${module.sqs_outbound.queue_name}",
        "S3_AUDIT_BUCKET": "${module.s3_audit_logs.bucket_id}",
        "AWS_REGION": "us-east-1",
        "LOG_LEVEL": "INFO",
        "ENVIRONMENT": "staging"
      }' \
      --region us-east-1
    
    # Verificar:
    aws secretsmanager get-secret-value \
      --secret-id ne-stg-eks/gateway \
      --query SecretString \
      --region us-east-1
  EOT
}
