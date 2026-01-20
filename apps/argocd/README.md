# ArgoCD Secrets - staging

Módulo Terraform para gerenciar secrets do ArgoCD no AWS Secrets Manager.

## 📋 Secrets Criados

| Secret Name | Descrição | Usado Por |
|-------------|-----------|-----------|
| `ne-stg-eks/argocd/github-ssh-key` | SSH private key para acessar GitHub | ArgoCD |

## 🚀 Setup

### 1. Aplicar Terraform

```bash
cd ne-terraform-staging/apps/argocd

terraform init
terraform apply --profile felipe-novaescola-staging
```

### 2. Gerar Chave SSH

```bash
# Gerar nova chave SSH para ArgoCD
ssh-keygen -t ed25519 -C "argocd@ne-stg-eks" -f argocd-github -N ""

# Isso criará dois arquivos:
# - argocd-github (private key)
# - argocd-github.pub (public key)
```

### 3. Adicionar Deploy Key no GitHub

1. Ir para: https://github.com/novaescolaorg/ne-gitops/settings/keys
2. Clicar em "Add deploy key"
3. Copiar conteúdo de `argocd-github.pub`:
   ```bash
   cat argocd-github.pub
   ```
4. Colar no campo "Key"
5. Marcar "Allow write access" (se necessário)
6. Salvar

### 4. Popular Secret no AWS

```bash
# Obter comando completo do Terraform
terraform output -raw setup_instructions

# Ou executar diretamente:
aws secretsmanager put-secret-value \
  --secret-id ne-stg-eks/argocd/github-ssh-key \
  --secret-string "{\"sshPrivateKey\":\"$(cat argocd-github | sed ':a;N;$!ba;s/\n/\\n/g')\"}" \
  --region us-east-1 \
  --profile felipe-novaescola-staging
```

### 5. Verificar Sincronização

```bash
# ExternalSecret status
kubectl get externalsecret github-repo-secret -n argocd

# Secret Kubernetes
kubectl get secret github-repo-secret -n argocd

# Verificar labels (deve ter argocd.argoproj.io/secret-type: repository)
kubectl get secret github-repo-secret -n argocd -o yaml | grep -A 5 labels
```

## 🔍 Verificação

### Testar Acesso do ArgoCD ao Repositório

```bash
# Ver repositories conectados no ArgoCD
argocd repo list

# Deve mostrar: git@github.com:novaescolaorg/ne-gitops.git
```

Ou via UI do ArgoCD:
1. Acessar ArgoCD UI
2. Settings → Repositories
3. Verificar se `ne-gitops` está conectado com sucesso

## 🔄 Atualizar Chave SSH

Se precisar rotacionar a chave SSH:

### 1. Gerar Nova Chave

```bash
ssh-keygen -t ed25519 -C "argocd@ne-stg-eks-new" -f argocd-github-new -N ""
```

### 2. Adicionar Nova Deploy Key no GitHub

Adicionar `argocd-github-new.pub` como nova Deploy Key

### 3. Atualizar Secret

```bash
aws secretsmanager update-secret \
  --secret-id ne-stg-eks/argocd/github-ssh-key \
  --secret-string "{\"sshPrivateKey\":\"$(cat argocd-github-new | sed ':a;N;$!ba;s/\n/\\n/g')\"}" \
  --region us-east-1 \
  --profile felipe-novaescola-staging
```

### 4. Forçar Refresh no Kubernetes

```bash
kubectl annotate externalsecret github-repo-secret \
  force-sync=$(date +%s) \
  --namespace argocd
```

### 5. Remover Chave Antiga do GitHub

Após confirmar que tudo funciona, remover a chave antiga do GitHub.

## 🚨 Troubleshooting

### ArgoCD não consegue acessar repositório

**1. Verificar secret existe:**
```bash
kubectl get secret github-repo-secret -n argocd
```

**2. Verificar conteúdo do secret:**
```bash
kubectl get secret github-repo-secret -n argocd -o yaml
```

Deve ter:
- `type: git`
- `url: git@github.com:novaescolaorg/ne-gitops.git`
- `sshPrivateKey: <base64-encoded-key>`

**3. Verificar label do secret:**
```bash
kubectl get secret github-repo-secret -n argocd -o jsonpath='{.metadata.labels.argocd\.argoproj\.io/secret-type}'
```

Deve retornar: `repository`

**4. Ver logs do ArgoCD:**
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server -f
```

**5. Testar conexão SSH manualmente:**
```bash
# Em um pod dentro do cluster
ssh -T git@github.com
```

### ExternalSecret não sincroniza

Verificar External Secrets Operator:

```bash
# Status do ExternalSecret
kubectl describe externalsecret github-repo-secret -n argocd

# Logs do External Secrets
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets --tail=100
```

### Deploy Key não funciona no GitHub

Verificar:
1. Chave pública foi adicionada corretamente
2. Repository tem acesso (não é necessário "write access" para ArgoCD pull-only)
3. Formato da chave está correto (começar com `ssh-ed25519`)

## 📝 Formato do Secret

O secret no AWS Secrets Manager deve ter este formato:

```json
{
  "sshPrivateKey": "-----BEGIN OPENSSH PRIVATE KEY-----\nbase64content\n-----END OPENSSH PRIVATE KEY-----\n"
}
```

O ExternalSecret transforma isso em um secret Kubernetes com:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
data:
  type: git
  url: git@github.com:novaescolaorg/ne-gitops.git
  sshPrivateKey: <base64-encoded-private-key>
```

## 🔗 Links

- **GitOps**: `ne-gitops/clusters/ne-stg-eks/manifests/argocd/`
- **ExternalSecret**: `ne-gitops/clusters/ne-stg-eks/manifests/argocd/github-repo-secret.yaml`
- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
