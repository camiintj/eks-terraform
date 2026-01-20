# ===================================================================
# MAKEFILE - GATEWAY INFRASTRUCTURE - staging
# ===================================================================
# Facilita operações comuns do Terraform
#
# USO:
#   make init                           # Usa profile padrão
#   make init PROFILE=meu-profile       # Usa profile específico
#   make plan AWS_PROFILE=meu-profile   # Usa variável de ambiente
# ===================================================================

.PHONY: help init plan apply destroy fmt validate

# Variáveis - podem ser sobrescritas via linha de comando
# Exemplo: make plan PROFILE=outro-profile
PROFILE ?= $(AWS_PROFILE)
REGION  ?= us-east-1

# Se nenhum profile for definido, use o padrão (apenas para local)
ifeq ($(PROFILE),)
	PROFILE := felipe-novaescola-staging
endif

help: ## Mostra ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicializa o Terraform com profile
	@echo "🚀 Initializing Terraform with profile: $(PROFILE)"
	AWS_PROFILE=$(PROFILE) terraform init -backend-config="profile=$(PROFILE)"

init-ci: ## Inicializa o Terraform para CI/CD (sem profile)
	@echo "🚀 Initializing Terraform for CI/CD (no profile)"
	terraform init

plan: ## Executa terraform plan
	@echo "📋 Running terraform plan with profile: $(PROFILE)"
	AWS_PROFILE=$(PROFILE) terraform plan -var-file="terraform.tfvars" -var="aws_profile=$(PROFILE)"

plan-ci: ## Executa terraform plan para CI/CD (sem profile)
	@echo "📋 Running terraform plan for CI/CD (no profile)"
	terraform plan -var-file="terraform.tfvars"

apply: ## Executa terraform apply
	@echo "✅ Running terraform apply with profile: $(PROFILE)"
	AWS_PROFILE=$(PROFILE) terraform apply -var-file="terraform.tfvars" -var="aws_profile=$(PROFILE)"

apply-auto: ## Executa terraform apply com auto-approve
	@echo "✅ Running terraform apply (auto-approve) with profile: $(PROFILE)"
	AWS_PROFILE=$(PROFILE) terraform apply -auto-approve -var-file="terraform.tfvars" -var="aws_profile=$(PROFILE)"

apply-ci: ## Executa terraform apply para CI/CD (sem profile)
	@echo "✅ Running terraform apply for CI/CD (no profile)"
	terraform apply -auto-approve -var-file="terraform.tfvars"

destroy: ## Executa terraform destroy
	AWS_PROFILE=$(PROFILE) terraform destroy

fmt: ## Formata os arquivos Terraform
	terraform fmt -recursive

validate: ## Valida a configuração
	terraform validate

refresh: ## Atualiza o state sem modificar recursos
	AWS_PROFILE=$(PROFILE) terraform refresh

output: ## Mostra os outputs
	AWS_PROFILE=$(PROFILE) terraform output

state-list: ## Lista os recursos no state
	AWS_PROFILE=$(PROFILE) terraform state list

# ===================================================================
# AWS CLI COMMANDS
# ===================================================================

aws-sqs-list: ## Lista todas as filas SQS
	aws sqs list-queues --profile $(PROFILE) --region $(REGION)

aws-s3-list: ## Lista todos os buckets S3
	aws s3 ls --profile $(PROFILE)

aws-iam-roles: ## Lista IAM roles
	aws iam list-roles --profile $(PROFILE) | grep gateway

# ===================================================================
# MONITORING COMMANDS
# ===================================================================

sqs-inbound-messages: ## Verifica mensagens na fila inbound
	@echo "Checking messages in ne-gateway-inbound.fifo..."
	@aws sqs get-queue-attributes \
		--profile $(PROFILE) \
		--region $(REGION) \
		--queue-url $$(aws sqs get-queue-url --profile $(PROFILE) --region $(REGION) --queue-name ne-gateway-inbound.fifo --query 'QueueUrl' --output text) \
		--attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

sqs-outbound-messages: ## Verifica mensagens na fila outbound
	@echo "Checking messages in ne-gateway-outbound.fifo..."
	@aws sqs get-queue-attributes \
		--profile $(PROFILE) \
		--region $(REGION) \
		--queue-url $$(aws sqs get-queue-url --profile $(PROFILE) --region $(REGION) --queue-name ne-gateway-outbound.fifo --query 'QueueUrl' --output text) \
		--attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

s3-bucket-size: ## Verifica tamanho do bucket de auditoria
	@echo "Checking bucket size..."
	@aws s3 ls s3://ne-gateway-audit-logs-staging-us-east-1 --recursive --summarize --human-readable --profile $(PROFILE)
