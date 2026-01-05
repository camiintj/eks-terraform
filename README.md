# EKS Infrastructure

Repositório de infraestrutura como código (Terraform) para cluster EKS 

# Configuração da role 

Os comandos a seguir criam um role de permissão para o terraform com vínculo entre o external uuid e usuário. É necessário ter o usuário configurado no AWS CLI da máquina.


1. Configuração da Role na AWS

Antes de realizar o deployment das stacks do Terraform, crie uma Role na sua conta AWS:

Atenção: Substitua as variáveis, <YOUR_ACCOUNT> e <YOUR_USER>.

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
                    "sts:ExternalId": "20edb746-4470-4314-9777-1c0fd2025b24"
                }
            }
        }]
    }'



2. Anexar Permissões Administrativas

Anexe permissões administrativas à role criada:

aws iam attach-role-policy \
    --role-name terraform_role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess


3. Substituição da String arn:aws:iam::<YOUR_ACCOUNT>:role/terraform_role nos Arquivos Terraform

find . -type f -name "*.tf" -exec sed -i \
    's|arn:aws:iam::<YOUR_ACCOUNT>:role/terraform_role|arn:aws:iam::<YOUR_ACCOUNT>:role/terraform_role|g' {} +



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

