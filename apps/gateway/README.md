# Gateway Infrastructure - staging

Infraestrutura AWS para Gateway de Mensagens WhatsApp (Turn.io) em produção.

## Recursos Provisionados

### SQS FIFO Queues

- **gateway-inbound.fifo**: Mensagens recebidas do Turn.io
  - Dead Letter Queue: gateway-inbound-dlq.fifo
- **gateway-outbound.fifo**: Mensagens a serem enviadas ao Turn.io
  - Dead Letter Queue: gateway-outbound-dlq.fifo

**Configurações:**
- Tipo: FIFO Queue
- ContentBasedDeduplication: Enabled
- MessageRetentionPeriod: 14 dias (1209600 segundos)
- VisibilityTimeout: 5 minutos (300 segundos)
- ReceiveMessageWaitTime: 20 segundos (long polling)
- MaxMessageSize: 256 KB (262144 bytes)
- DLQ MaxReceiveCount: 3 tentativas

### S3 Bucket - Audit Logs

- **gateway-audit-logs-staging-us-east-1**: Armazenamento de logs de auditoria

**Configurações:**
- Versioning: Enabled
- Encryption: SSE-S3 (AES256)
- Public Access: Blocked (all)
- Lifecycle Policy:
  - 90 dias → Standard-IA
  - 365 dias → Glacier
  - 2555 dias (7 anos) → Expiration

**Estrutura de pastas (gerenciada pela aplicação):**
```
s3://ne-gateway-audit-logs-staging-us-east-1/
├── turnio/                           # Inbound logs
│   └── 2026/01/13/
│       └── 20260113-HHMMSS-mmmmmm-<message_id>.jsonl
└── turnio-outbound/                  # Outbound logs
    └── 2026/01/13/
        └── 20260113-HHMMSS-mmmmmm-<wamid>.jsonl
```

### IAM Role e Policies

- **ne-gateway-eks-workload**: IAM Role para workloads EKS (IRSA)
- **ne-gateway-sqs-access**: Policy para acesso às filas SQS
- **ne-gateway-s3-access**: Policy para acesso ao bucket S3

## Pré-requisitos

1. Terraform >= 1.6.0
2. AWS Provider >= 6.28
3. AWS CLI configurado com profile `felipe-novaescola-staging`
4. Módulos Terraform em ne-terraform-modules:
   - modules/sqs
   - modules/s3
5. Backend S3 configurado:
   - Bucket: `ne-terraform-staging-state`
   - DynamoDB Table: `ne-terraform-staging-locks`

## Como Usar

### Inicializar Terraform

```bash
make init
```

### Planejar Mudanças

```bash
make plan
```

### Aplicar Mudanças

```bash
make apply
```

### Destruir Recursos (CUIDADO!)

```bash
make destroy
```

## Outputs Importantes

Após aplicar o Terraform, você obterá os seguintes outputs:

### SQS
- `sqs_inbound_queue_url`: URL da fila inbound
- `sqs_inbound_queue_arn`: ARN da fila inbound
- `sqs_outbound_queue_url`: URL da fila outbound
- `sqs_outbound_queue_arn`: ARN da fila outbound

### S3
- `s3_audit_bucket_id`: Nome do bucket de auditoria
- `s3_audit_bucket_arn`: ARN do bucket de auditoria

### IAM
- `iam_role_arn`: ARN da IAM Role
- `k8s_service_account_annotation`: Anotação para ServiceAccount Kubernetes

## Integração com Kubernetes

### ServiceAccount com IRSA

Crie um ServiceAccount no namespace `gateway` com a anotação IRSA:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gateway-sa
  namespace: gateway
  annotations:
    eks.amazonaws.com/role-arn: <output: iam_role_arn>
```

### Deployment com ServiceAccount

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-api
  namespace: gateway
spec:
  template:
    spec:
      serviceAccountName: gateway-sa
      containers:
      - name: gateway-api
        image: gateway-api:latest
        env:
        - name: AWS_REGION
          value: us-east-1
        - name: SQS_INBOUND_QUEUE_URL
          value: <output: sqs_inbound_queue_url>
        - name: SQS_OUTBOUND_QUEUE_URL
          value: <output: sqs_outbound_queue_url>
        - name: S3_AUDIT_BUCKET
          value: <output: s3_audit_bucket_id>
```

## Monitoramento

### Verificar mensagens nas filas

```bash
make sqs-inbound-messages
make sqs-outbound-messages
```

### Verificar tamanho do bucket S3

```bash
make s3-bucket-size
```

### Listar recursos AWS

```bash
make aws-sqs-list
make aws-s3-list
make aws-iam-roles
```

## Estrutura de Arquivos

```
gateway/
├── backend.tf           # Configuração do backend S3
├── data.tf             # Data sources AWS
├── locals.tf           # Variáveis locais
├── main.tf             # Recursos principais (SQS, S3, IAM)
├── outputs.tf          # Outputs do Terraform
├── provider.tf         # Configuração do provider AWS
├── terraform.tfvars    # Valores das variáveis
├── variables.tf        # Declaração de variáveis
├── versions.tf         # Versões do Terraform e providers
├── Makefile           # Comandos úteis
└── README.md          # Esta documentação
```

## Segurança

- **Encryption at Rest**:
  - SQS: SSE-SQS (SQS Managed Encryption)
  - S3: SSE-S3 (AES256)
- **Public Access**: Bloqueado em todos os recursos
- **IAM Roles**: Princípio do menor privilégio (IRSA)
- **Versioning**: Habilitado no bucket S3

## Compliance

- **Retenção**: 7 anos (2555 dias)
- **Auditoria**: Logs imutáveis com versioning
- **Lifecycle**: Transição automática para storage classes mais econômicas

## Custos Estimados

### SQS
- Primeiras 1M requisições/mês: GRÁTIS
- Após: $0.40 por milhão de requisições

### S3
- Standard: $0.023/GB/mês
- Standard-IA (após 90 dias): $0.0125/GB/mês
- Glacier (após 1 ano): $0.004/GB/mês

### IAM
- GRÁTIS

## Troubleshooting

### Erro: "Backend not initialized"
```bash
make init
```

### Erro: "Access Denied"
Verificar se o profile AWS está configurado:
```bash
aws sts get-caller-identity --profile felipe-novaescola-staging
```

### DLQ com mensagens
Mensagens na DLQ indicam falhas após 3 tentativas. Investigar:
1. Logs da aplicação
2. CloudWatch Metrics
3. Mensagem na DLQ (via console ou CLI)

## Suporte

Time: Backend + Infra  
Projeto: Gateway WhatsApp (Turn.io)  
Ambiente: staging
