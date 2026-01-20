# YACE (Yet Another CloudWatch Exporter) - IRSA

## 📋 Visão Geral

Configuração de IRSA (IAM Roles for Service Accounts) para o YACE CloudWatch Exporter no namespace `monitoring` do cluster `ne-stg-eks`.

YACE exporta métricas do AWS CloudWatch (incluindo SQS) para o Prometheus.

---

## 🎯 O que este módulo cria

### IAM Role
- **Nome:** `ne-stg-eks-yace`
- **Tipo:** IRSA (Web Identity)
- **ServiceAccount:** `monitoring/yace`

### IAM Policies (3)

1. **CloudWatch Read** (`ne-yace-cloudwatch-read`)
   - `cloudwatch:GetMetricData`
   - `cloudwatch:GetMetricStatistics`
   - `cloudwatch:ListMetrics`

2. **Resource Discovery** (`ne-yace-resource-discovery`)
   - `tag:GetResources` - Descobrir recursos via tags

3. **SQS Metadata** (`ne-yace-sqs-metadata`)
   - `sqs:GetQueueAttributes`
   - `sqs:GetQueueUrl`
   - `sqs:ListQueues`
   - `sqs:ListQueueTags`

---

## 🚀 Como usar

### 1. Inicializar Terraform

```bash
cd apps/yace
terraform init
```

### 2. Planejar mudanças

```bash
terraform plan
```

**Saída esperada:**
```
Plan: 7 to add, 0 to change, 0 to destroy.
  + aws_iam_role.yace
  + aws_iam_policy.cloudwatch_read
  + aws_iam_policy.resource_discovery
  + aws_iam_policy.sqs_metadata
  + aws_iam_role_policy_attachment.cloudwatch_read
  + aws_iam_role_policy_attachment.resource_discovery
  + aws_iam_role_policy_attachment.sqs_metadata
```

### 3. Aplicar

```bash
terraform apply
```

### 4. Verificar outputs

```bash
terraform output
```

**Outputs esperados:**
```hcl
iam_role_arn = "arn:aws:iam::545865198937:role/ne-stg-eks-yace"
k8s_namespace = "monitoring"
k8s_service_account = "yace"
k8s_service_account_annotation = "eks.amazonaws.com/role-arn: arn:aws:iam::545865198937:role/ne-stg-eks-yace"
```

---

## ✅ Validação

### No Terraform

```bash
# Ver role criado
aws iam get-role --role-name ne-stg-eks-yace

# Ver policies anexadas
aws iam list-attached-role-policies --role-name ne-stg-eks-yace

# Ver trust policy
aws iam get-role --role-name ne-stg-eks-yace --query 'Role.AssumeRolePolicyDocument'
```

### No Kubernetes

```bash
# Verificar ServiceAccount
kubectl get sa yace -n monitoring -o yaml

# Esperado:
# annotations:
#   eks.amazonaws.com/role-arn: arn:aws:iam::545865198937:role/ne-stg-eks-yace

# Verificar pod do YACE
kubectl get pods -n monitoring -l app.kubernetes.io/name=yace

# Testar credenciais no pod
kubectl exec -it -n monitoring <yace-pod> -- aws sts get-caller-identity

# Esperado:
# {
#   "UserId": "AROA...:...",
#   "Account": "545865198937",
#   "Arn": "arn:aws:sts::545865198937:assumed-role/ne-stg-eks-yace/..."
# }
```

### Testar acesso ao CloudWatch

```bash
# Dentro do pod YACE
kubectl exec -it -n monitoring <yace-pod> -- aws cloudwatch list-metrics \
  --namespace AWS/SQS \
  --region us-east-1

# Deve retornar métricas SQS disponíveis
```

---

## 📊 Métricas Exportadas

YACE vai exportar métricas do CloudWatch com prefixo `aws_`:

### SQS Metrics
- `aws_sqs_approximate_number_of_messages_visible_average`
- `aws_sqs_number_of_messages_sent_sum`
- `aws_sqs_number_of_messages_received_sum`
- `aws_sqs_number_of_messages_deleted_sum`
- `aws_sqs_approximate_age_of_oldest_message_maximum`

### Exemplo de Query no Prometheus
```promql
# Mensagens visíveis nas filas gateway
aws_sqs_approximate_number_of_messages_visible_average{queue_name=~"gateway.*"}

# Idade da mensagem mais antiga
aws_sqs_approximate_age_of_oldest_message_maximum{queue_name="gateway-outbound.fifo"}
```

---

## 🔧 Troubleshooting

### Erro: "AccessDenied" no pod

**Causa:** Role não existe ou policy incorreta

**Solução:**
```bash
# Verificar se role existe
terraform output iam_role_arn

# Verificar policies
aws iam list-attached-role-policies --role-name ne-stg-eks-yace
```

### Erro: "WebIdentityErr: failed to retrieve credentials"

**Causa:** Trust policy incorreta ou ServiceAccount annotation errada

**Solução:**
```bash
# Verificar annotation do SA
kubectl get sa yace -n monitoring -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

# Deve retornar: arn:aws:iam::545865198937:role/ne-stg-eks-yace

# Verificar trust policy
aws iam get-role --role-name ne-stg-eks-yace \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition'
```

### Pod não consegue ler métricas SQS

**Causa:** Filas não têm tags ou policy sem permissão

**Solução:**
```bash
# Verificar tags da fila
aws sqs list-queue-tags \
  --queue-url https://sqs.us-east-1.amazonaws.com/545865198937/gateway-outbound.fifo

# Deve ter: Application=gateway

# Verificar permissão SQS
aws iam get-policy-version \
  --policy-arn $(terraform output -raw sqs_metadata_policy_arn) \
  --version-id v1
```

---

## 🔗 Referências

- **GitOps:** `ne-gitops/clusters/ne-stg-eks/manifests/monitoring/yace/`
- **ServiceAccount:** `monitoring/yace`
- **Documentação YACE:** https://github.com/nerdswords/yet-another-cloudwatch-exporter

---

## 📝 Notas

1. **Remote State:** Este módulo usa remote state do EKS para obter OIDC provider
2. **Permissões:** Apenas leitura - YACE não modifica recursos AWS
3. **Scope:** Acessa **TODAS** filas SQS - considerar restringir por tags se necessário
4. **Custo:** Cada request do CloudWatch API tem custo - scrape interval configurado para 5min

---

**Criado:** 2026-01-14  
**Autor:** SRE Team
