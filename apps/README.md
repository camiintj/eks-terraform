# Applications Infrastructure

Este diretório contém a infraestrutura do Terraform para todas as **aplicações** da Nova Escola que rodam no cluster EKS.

> **Nota**: A infraestrutura base do EKS está em `/eks` na raiz do repositório, pois é infraestrutura compartilhada.

## Estrutura

```
apps/
├── argocd/                  # ArgoCD Secrets e configurações
├── argocd-image-updater/    # ArgoCD Image Updater IRSA + Git Secret
├── external-secrets/        # External Secrets Operator IRSA
├── keda/                    # KEDA Operator IRSA
├── gateway/                 # Gateway WhatsApp (Turn.io)
└── [futuras-apps]           # Outras aplicações (ex: api, frontend, workers, etc)
```

## O que vai em apps/?

Cada aplicação tem recursos específicos como:
- **SQS queues** - Filas de mensagens
- **S3 buckets** - Armazenamento de objetos
- **SNS topics** - Notificações
- **RDS databases** - Bancos de dados
- **ElastiCache** - Cache
- **Secrets** - Segredos no Secrets Manager
- **IAM roles (IRSA)** - Roles para Service Accounts Kubernetes
- **ECR repositories** - Repositórios de imagens Docker

## Aplicações Especiais (Platform)

Algumas aplicações são componentes de plataforma que fornecem serviços para outras apps:

- **argocd/**: Secrets para ArgoCD (senha admin, SSH keys, etc)
- **argocd-image-updater/**: IAM Role (IRSA) para Image Updater acessar ECR + Secret para Git
- **external-secrets/**: IAM Role (IRSA) para External Secrets acessar Secrets Manager
- **keda/**: IAM Role (IRSA) para KEDA Operator acessar SQS

Essas aplicações criam principalmente IAM Roles, Policies e Secrets, não criam recursos de aplicação.

## Padrão de Organização

Cada aplicação tem sua própria pasta com:
- `main.tf` - Recursos principais da aplicação
- `variables.tf` - Variáveis de entrada
- `outputs.tf` - Outputs (URLs, ARNs, etc)
- `backend.tf` - Configuração do backend S3
- `provider.tf` - Configuração do provider AWS
- `terraform.tfvars` - Valores das variáveis (apenas se não contiver secrets)
- `locals.tf` - Variáveis locais e transformações
- `data.tf` - Data sources (buscar recursos existentes)
- `Makefile` - Comandos úteis para o Terraform
- `README.md` - Documentação específica da aplicação

## Como Adicionar uma Nova Aplicação

1. Crie uma nova pasta dentro de `apps/[nome-da-app]`
2. Copie os arquivos base de uma aplicação existente (ex: gateway)
3. Ajuste o `backend.tf` com o novo path no S3:
   ```hcl
   key = "apps/[nome-da-app]/terraform.tfstate"
   ```
4. Configure as variáveis no `terraform.tfvars`
5. Execute `terraform init` e `terraform plan`

## Comandos Úteis

Cada aplicação tem um `Makefile` com comandos úteis:

```bash
make init      # Inicializa o Terraform
make plan      # Mostra o plano de execução
make apply     # Aplica as mudanças
make destroy   # Destrói a infraestrutura
make fmt       # Formata os arquivos
make validate  # Valida a configuração
```

## Exemplo

Para trabalhar na aplicação gateway:

```bash
cd apps/gateway
make init
make plan
make apply
```
