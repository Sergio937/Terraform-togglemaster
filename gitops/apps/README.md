# ArgoCD Applications (`gitops/apps`)

Este diretório contém os manifests `Application` do ArgoCD que apontam para os manifests Kubernetes do projeto.

## Objetivo

- Declarar **o que** o ArgoCD deve sincronizar
- Garantir deploy automático com:
  - `prune: true`
  - `selfHeal: true`
  - `CreateNamespace=true`

## Applications deste diretório

### Serviços da plataforma

- `auth-service.yaml` → `gitops/manifests/auth-service`
- `flag-service.yaml` → `gitops/manifests/flag-service`
- `evaluation-service.yaml` → `gitops/manifests/evaluation-service`
- `analytics-service.yaml` → `gitops/manifests/analytics-service`
- `targeting-service.yaml` → `gitops/manifests/targeting-service`

Todos sincronizam para o namespace `togglemaster`.

### Ingress

- `ingress-nginx.yaml`
  - Instala o chart `ingress-nginx` (Helm)
  - Namespace: `ingress-nginx`
  - Service do controller em `LoadBalancer`
  - Cria `IngressClass` chamada `nginx`

- `ingress.yaml`
  - Aplica o ingress da aplicação em `gitops/manifests/ingress`
  - Namespace: `togglemaster`

## Como aplicar

Na raiz do repositório:

```bash
kubectl apply -f gitops/apps/
```

## Como validar

```bash
kubectl get applications -n argocd
kubectl get pods -n togglemaster
kubectl get svc -n ingress-nginx ingress-nginx-controller
kubectl get ingress -n togglemaster -o wide
```

## Ordem recomendada (primeiro deploy)

1. Aplicar `gitops/apps/`
2. Aguardar `ingress-nginx` ficar `Healthy`
3. Validar serviços no namespace `togglemaster`
4. Validar se o Ingress recebeu `ADDRESS`

## Operação diária

Após qualquer alteração em `gitops/manifests/*` ou em `gitops/apps/*`:

- Faça commit + push para `main`
- O ArgoCD detecta e sincroniza automaticamente

## Troubleshooting rápido

- `Application` em `OutOfSync`:
  - `kubectl describe application <app> -n argocd`

- `Ingress` sem `ADDRESS`:
  - Verifique `ingress-nginx-controller` e `IngressClass nginx`

- Pods com `ErrImagePull`/`ImagePullBackOff`:
  - Confirmar imagem/tag no ECR e tag usada em `gitops/manifests/*/deployment.yaml`
