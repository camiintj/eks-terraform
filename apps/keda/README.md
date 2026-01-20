# KEDA Operator - IRSA Configuration

Este módulo Terraform cria a IAM Role e Policies necessárias para o KEDA Operator acessar recursos AWS via IRSA (IAM Roles for Service Accounts).

## 📋 O que é criado

- **IAM Role**: `ne-keda-operator`
  - Trust Policy configurado para OIDC provider do EKS
  - Permite assumeRoleWithWebIdentity do ServiceAccount `keda-operator` no namespace `keda`

- **IAM Policy**: `ne-keda-sqs-read`
  - `sqs:GetQueueAttributes`
  - `sqs:GetQueueUrl`
  - `sqs:ListQueues`
  - `sqs:ListQueueTags`
  - Resource: `arn:aws:sqs:us-east-1:ACCOUNT_ID:gateway-*`

## 🔧 Pré-requisitos

1. ✅ Cluster EKS com OIDC provider configurado
2. ✅ Remote state do EKS em `ne-terraform-staging-state` bucket
3. ✅ Terraform >= 1.6.0
4. ✅ AWS Provider >= 6.28

## 🚀 Como Usar

### 1. Inicializar Terraform

```bash
cd ne-terraform-staging/apps/keda
terraform init
```

### 2. Revisar o Plano

```bash
terraform plan --profile felipe-novaescola-staging
```

### 3. Aplicar

```bash
terraform apply --profile felipe-novaescola-staging
```

### 4. Obter ARN da Role

```bash
terraform output -raw iam_role_arn
```

### 5. Atualizar GitOps

Copie o ARN e atualize o arquivo:
- `ne-gitops/clusters/ne-stg-eks/manifests/keda/serviceaccount.yaml`

```yaml
annotations:
  eks.amazonaws.com/role-arn: <ARN_DA_ROLE>
```

## 📊 Outputs

| Output | Descrição |
|--------|-----------|
| `iam_role_arn` | ARN da IAM Role para KEDA Operator |
| `iam_role_name` | Nome da IAM Role |
| `sqs_policy_arn` | ARN da policy SQS |
| `k8s_service_account_annotation` | Annotation completa para ServiceAccount |
| `configuration_summary` | Resumo da configuração |

## 🔐 Permissões

### SQS (Read-Only)
KEDA precisa apenas de leitura para monitorar métricas das filas:

```json
{
  "Effect": "Allow",
  "Action": [
    "sqs:GetQueueAttributes",
    "sqs:GetQueueUrl",
    "sqs:ListQueues",
    "sqs:ListQueueTags"
  ],
  "Resource": "arn:aws:sqs:us-east-1:ACCOUNT_ID:gateway-*"
}
```

### CloudWatch (Opcional - Comentado)
Se precisar usar CloudWatch metrics como trigger, descomentar no `main.tf`:

```hcl
resource "aws_iam_policy" "cloudwatch_read" {
  # ...
}

resource "aws_iam_role_policy_attachment" "cloudwatch_read" {
  # ...
}
```

## ⚙️ Variáveis

| Variável | Descrição | Default |
|----------|-----------|---------|
| `aws_region` | Região AWS | `us-east-1` |
| `aws_profile` | AWS CLI profile | `null` (para CI/CD) |
| `environment` | Ambiente | `staging` |
| `create_iam_role` | Criar IAM role | `true` |
| `iam_role_name` | Nome da role | `keda-operator` |
| `sqs_queue_pattern` | Padrão de filas | `gateway-*` |

## 📝 Customização

### Permitir acesso a outras filas

Edite `terraform.tfvars`:

```hcl
sqs_queue_pattern = "*"  # Todas as filas
# ou
sqs_queue_pattern = "app-*,gateway-*"  # Múltiplos padrões (não suportado, use Resource array)
```

Para múltiplos padrões, edite `main.tf`:

```hcl
Resource = [
  "arn:aws:sqs:${local.region}:${local.account_id}:gateway-*",
  "arn:aws:sqs:${local.region}:${local.account_id}:app-*"
]
```

## 🔄 Atualização

Para atualizar a configuração:

```bash
# Editar terraform.tfvars ou main.tf
terraform plan --profile felipe-novaescola-staging
terraform apply --profile felipe-novaescola-staging
```

## 🗑️ Destroy

Para remover recursos:

```bash
terraform destroy --profile felipe-novaescola-staging
```

**ATENÇÃO**: Isso removerá a IAM Role. Certifique-se de que KEDA não está usando antes de destruir.

## 🔗 Links Relacionados

- **GitOps**: `ne-gitops/clusters/ne-stg-eks/manifests/keda/`
- **KEDA Docs**: https://keda.sh/docs/
- **AWS IRSA**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
