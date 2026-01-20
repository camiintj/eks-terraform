# 🚀 Como Aplicar o Terraform do YACE

## ⚠️ Pré-requisitos

1. **Credenciais AWS configuradas**
   - AWS CLI configurado com credenciais de produção
   - Ou variáveis de ambiente: `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`

2. **Terraform instalado**
   - Versão >= 1.6.0

3. **Acesso ao S3 backend**
   - Bucket: `ne-terraform-staging-state`
   - Key: `apps/yace/terraform.tfstate`

---

## 📋 Passo a Passo

### 1. Navegar para o diretório

```bash
cd /root/repositorios/ne-terraform-staging/apps/yace
```

### 2. Inicializar Terraform

```bash
terraform init
```

**Output esperado:**
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 3. Validar configuração

```bash
terraform validate
```

**Output esperado:**
```
Success! The configuration is valid.
```

### 4. Planejar mudanças

```bash
terraform plan
```

**Output esperado:**
```
Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + iam_role_arn = "arn:aws:iam::545865198937:role/ne-stg-eks-yace"
  + k8s_namespace = "monitoring"
  + k8s_service_account = "yace"
```

**Recursos que serão criados:**
- 1x aws_iam_role.yace
- 3x aws_iam_policy (cloudwatch_read, resource_discovery, sqs_metadata)
- 3x aws_iam_role_policy_attachment

### 5. Aplicar mudanças

```bash
terraform apply
```

Revisar o plano e digitar `yes` quando solicitado.

**Output esperado:**
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

iam_role_arn = "arn:aws:iam::545865198937:role/ne-stg-eks-yace"
k8s_namespace = "monitoring"
k8s_service_account = "yace"
k8s_service_account_annotation = "eks.amazonaws.com/role-arn: arn:aws:iam::545865198937:role/ne-stg-eks-yace"
```

### 6. Verificar outputs

```bash
terraform output
```

ou

```bash
terraform output iam_role_arn
```

---

## ✅ Validação

### No AWS

```bash
# Verificar se role foi criado
aws iam get-role --role-name ne-stg-eks-yace

# Ver policies anexadas
aws iam list-attached-role-policies --role-name ne-stg-eks-yace

# Ver trust policy
aws iam get-role --role-name ne-stg-eks-yace \
  --query 'Role.AssumeRolePolicyDocument' \
  --output json
```

### No Kubernetes (depois que YACE for deployado)

```bash
# Verificar ServiceAccount
kubectl get sa yace -n monitoring -o yaml | grep eks.amazonaws.com

# Verificar pod
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

---

## 🔧 Troubleshooting

### Erro: "No valid credential sources found"

**Solução:** Configurar credenciais AWS

```bash
aws configure
# ou
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### Erro: "Error acquiring the state lock"

**Causa:** Outra execução em andamento ou lock travado

**Solução:**
```bash
# Ver locks
aws dynamodb scan --table-name ne-terraform-staging-locks

# Se necessário, forçar unlock (CUIDADO!)
terraform force-unlock <LOCK_ID>
```

### Erro: "AccessDenied" ao criar role

**Causa:** Credenciais AWS sem permissão IAM

**Solução:** Usar credenciais com permissões:
- `iam:CreateRole`
- `iam:CreatePolicy`
- `iam:AttachRolePolicy`

---

## 📊 Estado Atual

- **Backend:** S3 (`ne-terraform-staging-state/apps/yace/terraform.tfstate`)
- **Lock:** DynamoDB (`ne-terraform-staging-locks`)
- **Região:** us-east-1
- **Role ARN:** `arn:aws:iam::545865198937:role/ne-stg-eks-yace`

---

## 🚨 IMPORTANTE

Após aplicar o Terraform:

1. **ArgoCD vai detectar automaticamente** as mudanças no GitOps
2. **YACE vai subir** e usar o IRSA criado
3. **Validar logs do YACE** para garantir que não há erros de permissão
4. **Verificar métricas no Prometheus** (`aws_sqs_*`)

---

**Data de criação:** 2026-01-14  
**Última atualização:** 2026-01-14
