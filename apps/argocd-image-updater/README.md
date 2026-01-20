# ArgoCD Image Updater - Terraform IRSA

Configuração Terraform para criar IAM Role e Policies necessárias para o ArgoCD Image Updater acessar o ECR via IRSA (IAM Roles for Service Accounts).

## O que este módulo cria?

1. **IAM Role**: `ne-argocd-image-updater`
   - Trust policy configurada para IRSA com o OIDC provider do EKS
   - Vinculada ao ServiceAccount `argocd-image-updater-controller` no namespace `argocd`

2. **IAM Policy**: `ne-argocd-image-updater-ecr-read`
   - Permissões para autenticar no ECR (`ecr:GetAuthorizationToken`)
   - Permissões para ler imagens e metadados do ECR

## Pré-requisitos

- Cluster EKS já provisionado
- Remote state do EKS configurado em `eks/terraform.tfstate`
- Terraform >= 1.6.0
- AWS Provider >= 6.28

## Estrutura de Arquivos

```
argocd-image-updater/
├── README.md              # Este arquivo
├── main.tf                # Recursos principais (IAM Role e Policy)
├── variables.tf           # Declaração de variáveis
├── terraform.tfvars       # Valores das variáveis
├── data.tf                # Data sources (remote state, account, etc)
├── locals.tf              # Variáveis locais (OIDC, namespace, etc)
├── outputs.tf             # Outputs (ARNs, nomes, etc)
├── versions.tf            # Versões do Terraform e providers
├── provider.tf            # Configuração do provider AWS
└── backend.tf             # Configuração do backend S3
```

## Configuração

### 1. Revisar variáveis

Edite `terraform.tfvars` conforme necessário:

```hcl
# Região AWS
aws_region = "us-east-1"

# Criar IAM role
create_iam_role = true

# Nome da role (sem prefixo, será adicionado "ne-")
iam_role_name = "argocd-image-updater"

# Repositórios ECR permitidos
# null = permite todos (*)
# ou especifique ARNs específicos:
ecr_repository_arns = [
  "arn:aws:ecr:us-east-1:545865198937:repository/ne-gateway-api",
  "arn:aws:ecr:us-east-1:545865198937:repository/ne-gateway-worker-outbound",
]
```

### 2. Inicializar Terraform

```bash
cd /root/repositorios/ne-terraform-staging/apps/argocd-image-updater

# Inicializar (baixar providers e configurar backend)
terraform init

# Ver plano de execução
terraform plan

# Aplicar mudanças
terraform apply
```

### 3. Obter ARN da Role

Após aplicar, o Terraform retorna o ARN da role:

```bash
terraform output iam_role_arn
# Saída: arn:aws:iam::545865198937:role/ne-argocd-image-updater
```

### 4. Atualizar ServiceAccount no GitOps

Use o ARN retornado para atualizar o ServiceAccount no repositório GitOps:

**Arquivo**: `/root/repositorios/ne-gitops/clusters/ne-stg-eks/manifests/argocd-image-updater/serviceaccount.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-image-updater-controller
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::545865198937:role/ne-argocd-image-updater
```

## Permissões IAM Criadas

### ECR Authentication
```json
{
  "Effect": "Allow",
  "Action": ["ecr:GetAuthorizationToken"],
  "Resource": "*"
}
```

### ECR Read Access
```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:DescribeImages",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:GetRepositoryPolicy"
  ],
  "Resource": "arn:aws:ecr:us-east-1:545865198937:repository/*"
}
```

## Outputs Disponíveis

```bash
# ARN da IAM Role
terraform output iam_role_arn

# Nome da IAM Role
terraform output iam_role_name

# ARN da IAM Policy
terraform output iam_policy_arn

# Annotation para ServiceAccount
terraform output service_account_annotation
```

## Troubleshooting

### Erro: Remote state não encontrado

```
Error: error reading S3 Bucket (ne-terraform-staging-state) Object: NoSuchKey
```

**Solução**: Certifique-se que o remote state do EKS existe:
```bash
aws s3 ls s3://ne-terraform-staging-state/eks/
```

### Erro: OIDC provider não existe

```
Error: OIDC provider arn not found
```

**Solução**: Verifique se o OIDC provider está criado no remote state do EKS:
```bash
terraform -chdir=../eks output oidc_provider_arn
```

### Testar permissões ECR

Após aplicar, teste se o ServiceAccount tem acesso ao ECR:

```bash
# Port-forward para o pod do Image Updater
kubectl port-forward -n argocd deployment/argocd-image-updater-controller 8080:8080

# Ver logs
kubectl logs -n argocd -l control-plane=argocd-image-updater-controller
```

## Limpeza

Para remover todos os recursos criados:

```bash
terraform destroy
```

**ATENÇÃO**: Isso irá remover a IAM Role e Policy. Certifique-se que não há mais ServiceAccounts usando esta role.

## Variáveis de Ambiente (CI/CD)

Para execução em CI/CD, configure as seguintes variáveis:

```bash
# Credenciais AWS (via GitHub Secrets ou similar)
AWS_ACCESS_KEY_ID=<seu-access-key>
AWS_SECRET_ACCESS_KEY=<seu-secret-key>
AWS_REGION=us-east-1

# Terraform
TF_VAR_aws_profile=null  # Não usar profile em CI/CD
```

## Referências

- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [ECR IAM Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
