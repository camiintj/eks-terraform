# EKS Express

Infraestrutura como codigo (Terraform) para um cluster EKS production-ready na AWS, com auto-scaling, seguranca (WAF) e observabilidade (Prometheus + Grafana).

## Estrutura do Projeto

```
EKS_EXPRESS/
├── 00-backend/                 # Backend remoto (S3 + DynamoDB)
├── 01-networking/              # VPC, Subnets, IGW, NAT Gateway
├── 02-cluster/                 # EKS Cluster, Node Groups, Add-ons, Helm Charts
├── 03-karpenter-auto-scaling/  # Karpenter para auto-scaling dinamico
├── 04-security/                # WAF Web ACL (OWASP, Bot, SQLi, Geo)
└── 05-monitoring/              # Amazon Managed Prometheus + Grafana
```

## Arquitetura

```
Internet
   │
Route53 (DNS)
   │
WAFv2 (8 regras: Geo, IP Reputation, Bot, SQLi, OWASP)
   │
ALB (HTTPS:443 + ACM Certificate)
   │
┌──────────────── VPC 10.0.0.0/24 ────────────────┐
│                                                    │
│  Public Subnets (2 AZs)                           │
│  ├── ALB                                           │
│  └── NAT Gateway x2                               │
│                                                    │
│  Private Subnets (2 AZs)                          │
│  ├── EKS Control Plane (K8s 1.34)                 │
│  ├── Managed Node Group (Bottlerocket, t3.small)  │
│  ├── Karpenter Dynamic Nodes (t/m families)       │
│  │                                                 │
│  ├── kube-system:                                  │
│  │   ├── AWS Load Balancer Controller              │
│  │   ├── Karpenter v1.9.0                          │
│  │   ├── EBS CSI Driver                            │
│  │   ├── Metrics Server                            │
│  │   └── Prometheus Node Exporter                  │
│  │                                                 │
│  └── external-dns:                                 │
│      └── External DNS (Route53)                    │
└────────────────────────────────────────────────────┘
         │
   Observability
   ├── Amazon Managed Prometheus (scrape 30s)
   └── Amazon Managed Grafana (SSO Auth)
```

## Tecnologias

| Categoria | Servicos |
|-----------|----------|
| Compute | EKS, EC2, Bottlerocket |
| Networking | VPC, ALB, Route53, NAT Gateway, ACM |
| Security | WAFv2, IAM (IRSA/OIDC), Security Groups |
| Storage | EBS (CSI Driver), S3 |
| Scaling | Karpenter (consolidacao automatica, rotacao 8h) |
| Observability | Amazon Managed Prometheus, Managed Grafana, CloudWatch |
| IaC | Terraform (>= 1.5), Helm |

## Pre-requisitos

- Terraform >= 1.5
- AWS CLI configurado
- kubectl
- Helm

## Configuracao Inicial

### 1. Criar a IAM Role para o Terraform

Substitua `<YOUR_ACCOUNT>`, `<YOUR_USER>` e `<YOUR_EXTERNAL_ID>` pelos seus valores.

```bash
aws iam create-role \
    --role-name terraform_role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<YOUR_ACCOUNT>:user/<YOUR_USER>"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "<YOUR_EXTERNAL_ID>"
                }
            }
        }]
    }'
```

### 2. Anexar permissoes administrativas

```bash
aws iam attach-role-policy \
    --role-name terraform_role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 3. Substituir os placeholders nos arquivos

Procure por `<ALTERAR VALOR>` em todos os arquivos `.tf` e `.yaml` e substitua pelos valores da sua conta:

| Placeholder | Descricao | Exemplo |
|-------------|-----------|---------|
| Role ARN | ARN da role do Terraform | `arn:aws:iam::123456789:role/terraform_role` |
| External ID | UUID para assume role | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| S3 Bucket | Bucket do state do Terraform | `meu-terraform-state` |
| DynamoDB Table | Tabela de lock do state | `meu-terraform-lock` |
| Admin User ARN | ARN do usuario admin do EKS | `arn:aws:iam::123456789:user/meu-user` |
| Custom Domain | Dominio para DNS e certificado | `meudominio.com.br` |
| Certificate ARN | ARN do certificado ACM | `arn:aws:acm:us-east-1:123456789:certificate/...` |
| WAF ACL ARN | ARN do Web ACL (apos criar o modulo 04) | `arn:aws:wafv2:us-east-1:123456789:regional/webacl/...` |

Substituicao rapida via CLI:

```bash
find . -type f \( -name "*.tf" -o -name "*.yaml" -o -name "*.yml" \) -exec sed -i \
    's|<ALTERAR VALOR>|SEU_VALOR_AQUI|g' {} +
```

## Ordem de Execucao

Os modulos devem ser aplicados na ordem numerica, pois possuem dependencias entre si via remote state:

```bash
# 1. Backend - Cria S3 bucket e DynamoDB para state
cd 00-backend && terraform init && terraform apply

# 2. Networking - VPC, subnets, IGW, NAT Gateway
cd ../01-networking && terraform init && terraform apply

# 3. Cluster - EKS, node group, add-ons, ALB Controller, External DNS
cd ../02-cluster && terraform init && terraform apply

# 4. Karpenter - Auto-scaling dinamico de nos
cd ../03-karpenter-auto-scaling && terraform init && terraform apply

# 5. Security - WAF Web ACL com regras gerenciadas e customizadas
cd ../04-security && terraform init && terraform apply

# 6. Monitoring - Prometheus + Grafana
cd ../05-monitoring && terraform init && terraform apply
```

## Modulos em Detalhe

### 00-backend
- S3 bucket com versionamento para armazenar o state
- DynamoDB table para state locking (previne deploys concorrentes)

### 01-networking
- VPC com CIDR 10.0.0.0/24
- 2 subnets publicas + 2 privadas (us-east-1a / us-east-1b)
- Internet Gateway + 2 NAT Gateways (um por AZ)
- Route tables segregadas (publica e privada)

### 02-cluster
- EKS com Kubernetes 1.34 e logging completo
- Managed Node Group: 2x t3.small, Bottlerocket, on-demand
- OIDC Provider para IRSA (IAM Roles for Service Accounts)
- Add-ons: EBS CSI Driver, Metrics Server
- Helm: AWS Load Balancer Controller, External DNS
- ACM Certificate com validacao DNS via Route53

### 03-karpenter-auto-scaling
- Karpenter v1.9.0 com NodePool e EC2NodeClass
- Familias t e m (geracao > 2), on-demand
- Consolidacao automatica de nos subutilizados (delay 1min)
- Rotacao de nos a cada 8 horas
- CPU limit: 1000 cores

### 04-security
- WAF Web ACL regional com 8 regras:
  - Filtro geografico (Brasil)
  - AWS Managed Rules: IP Reputation, Anonymous IP, SQLi, Bot Control, Common Rules (OWASP Top 10)
  - Regras customizadas: flagging de requests suspeitos + bloqueio com resposta 403 personalizada
- Associacao ao ALB via annotation no Ingress

### 05-monitoring
- Amazon Managed Prometheus com scraper (30s interval)
- Prometheus Node Exporter como add-on do EKS
- Amazon Managed Grafana com autenticacao AWS SSO
- Grafana deployado nas private subnets com acesso ao Prometheus

## Samples

Exemplos de deployment com Ingress ALB estao disponiveis em:
- `02-cluster/samples/ingress-deployment.yml`
- `03-karpenter-auto-scaling/samples/nginx-alb-sample.yaml` (3 replicas + HTTPS + WAF)
