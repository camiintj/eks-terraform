# EKS Infrastructure

Repositório de infraestrutura como código (Terraform) para cluster EKS 

## Estrutura do Projeto
```
EKS_EXPRESS/
├── 00-backend/                 # Configuração do backend remoto (S3 + DynamoDB)
├── 01-networking/              # VPC, Subnets, IGW, NAT Gateway
├── 02-cluster/                 # EKS Cluster e Node Groups
└── 03-karpenter-auto-scaling/  # Karpenter para auto-scaling dinâmico
```

## Ordem de Execução

Os módulos devem ser aplicados na ordem numérica:

1. **Backend** → Configura o state remoto
2. **Networking** → Cria a infraestrutura de rede
3. **Cluster** → Provisiona o EKS
4. **Karpenter** → Implementa auto-scaling

## Como Usar
```bash
# Entre no módulo desejado
cd 0X-nome-do-modulo

# Inicialize o Terraform
terraform init

# Planeje as mudanças
terraform plan

# Aplique a configuração
terraform apply
```

## Requisitos

- Terraform >= 1.5

