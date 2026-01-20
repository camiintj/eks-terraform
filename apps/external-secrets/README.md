# External Secrets Operator - IRSA Configuration

Este módulo Terraform cria a IAM Role e Policies necessárias para o External Secrets Operator acessar AWS Secrets Manager via IRSA (IAM Roles for Service Accounts).

## 📋 O que é criado

- **IAM Role**: `ne-external-secrets`
  - Trust Policy configurado para OIDC provider do EKS
  - Permite assumeRoleWithWebIdentity do ServiceAccount `external-secrets` no namespace `external-secrets`

- **IAM Policy**: `ne-external-secrets-secretsmanager-read`
  - `secretsmanager:GetSecretValue`
  - `secretsmanager:DescribeSecret`
  - `secretsmanager:ListSecrets`
  - Resource: `arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:ne-stg-eks/*`

## 🔧 Pré-requisitos

1. ✅ Cluster EKS com OIDC provider configurado
2. ✅ Remote state do EKS em `ne-terraform-staging-state` bucket
3. ✅ Terraform >= 1.6.0
4. ✅ AWS Provider >= 6.28

## 🚀 Como Usar

### 1. Inicializar Terraform

```bash
cd ne-terraform-staging/apps/external-secrets
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
- `ne-gitops/clusters/ne-stg-eks/manifests/external-secrets/values.yaml`

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: <ARN_DA_ROLE>
```

### 6. Regenerar Manifesto External Secrets

```bash
cd ne-gitops/clusters/ne-stg-eks/manifests/external-secrets

helm template external-secrets external-secrets/external-secrets \
  --version 1.2.1 \
  --namespace external-secrets \
  --values values.yaml \
  > install.yaml

# Commit e push
git add values.yaml install.yaml
git commit -m "chore: update external-secrets IRSA role ARN"
git push
```

## 📊 Outputs

| Output | Descrição |
|--------|-----------|
| `iam_role_arn` | ARN da IAM Role para External Secrets |
| `iam_role_name` | Nome da IAM Role |
| `secrets_manager_policy_arn` | ARN da policy Secrets Manager |
| `k8s_service_account_annotation` | Annotation completa para ServiceAccount |
| `configuration_summary` | Resumo da configuração |

## 🔐 Permissões

### Secrets Manager (Read-Only)
External Secrets precisa de leitura para sincronizar secrets:

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret",
    "secretsmanager:ListSecrets"
  ],
  "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:ne-stg-eks/*"
}
```

## ⚙️ Variáveis

| Variável | Descrição | Default |
|----------|-----------|---------|
| `aws_region` | Região AWS | `us-east-1` |
| `aws_profile` | AWS CLI profile | `null` (para CI/CD) |
| `environment` | Ambiente | `staging` |
| `create_iam_role` | Criar IAM role | `true` |
| `iam_role_name` | Nome da role | `external-secrets` |
| `secrets_path_pattern` | Padrão de paths | `ne-stg-eks/*` |

## 📝 Customização

### Permitir acesso a outros secrets

Edite `terraform.tfvars`:

```hcl
# Acesso a todos os secrets do cluster
secrets_path_pattern = "ne-stg-eks/*"

# Acesso a secrets específicos
secrets_path_pattern = "ne-stg-eks/gateway/*"

# Múltiplos padrões
secrets_path_pattern = "ne-stg-eks/*"  # Use * e controle via naming convention
```

Para múltiplos padrões específicos, edite `main.tf`:

```hcl
Resource = [
  "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ne-stg-eks/*",
  "arn:aws:secretsmanager:${local.region}:${local.account_id}:shared/*"
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

**ATENÇÃO**: Isso removerá a IAM Role. Certifique-se de que External Secrets não está usando antes de destruir.

## 🔒 Segurança

### Princípio do Menor Privilégio

A policy criada segue o princípio do menor privilégio:
- ✅ Apenas leitura (`Get*`, `Describe*`, `List*`)
- ✅ Sem permissões de escrita
- ✅ Resource limitado ao path `ne-stg-eks/*`

### Naming Convention

Todos os secrets acessíveis pelo External Secrets devem seguir o padrão:
```
ne-stg-eks/{namespace}/{secret-name}
```

Exemplos:
- `ne-stg-eks/argocd/github-ssh-key`
- `ne-stg-eks/gateway/turnio`
- `ne-stg-eks/app-name/database-credentials`

## 📚 Uso no Kubernetes

### ClusterSecretStore

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

### ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: my-namespace
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: my-k8s-secret
  data:
    - secretKey: username
      remoteRef:
        key: ne-stg-eks/my-namespace/my-secret
        property: username
```

## 🔗 Links Relacionados

- **GitOps**: `ne-gitops/clusters/ne-stg-eks/manifests/external-secrets/`
- **External Secrets Docs**: https://external-secrets.io/
- **AWS IRSA**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/
