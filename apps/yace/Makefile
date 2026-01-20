# ===================================================================
# MAKEFILE - YACE IRSA
# ===================================================================
# Comandos utilitários para gerenciar IRSA do YACE
# ===================================================================

.PHONY: help init plan apply destroy fmt validate

help: ## Mostra esta mensagem de ajuda
	@echo "YACE IRSA - Terraform Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Inicializa o Terraform
	terraform init

plan: ## Mostra o que será alterado
	terraform plan

apply: ## Aplica as mudanças
	terraform apply

destroy: ## Destroi os recursos (cuidado!)
	terraform destroy

fmt: ## Formata os arquivos Terraform
	terraform fmt -recursive

validate: ## Valida a configuração
	terraform validate

output: ## Mostra os outputs
	terraform output

state-list: ## Lista recursos no state
	terraform state list
