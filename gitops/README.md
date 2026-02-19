# GitOps Repository - ToggleMaster

Este diretório contém os manifestos Kubernetes para deploy via ArgoCD.

## Estrutura

```
gitops/
├── apps/                       # ArgoCD Applications
│   ├── ingress-nginx.yaml
│   ├── analytics-service.yaml
│   ├── auth-service.yaml
│   ├── evaluation-service.yaml
│   ├── flag-service.yaml
│   ├── targeting-service.yaml
│   └── ingress.yaml
├── manifests/                  # Manifestos K8s organizados por serviço
│   ├── analytics-service/
│   ├── auth-service/
│   ├── evaluation-service/
│   ├── flag-service/
│   ├── targeting-service/
│   ├── namespace/
│   └── ingress/
└── argocd/                     # Instalação do ArgoCD
    ├── install.yaml
    └── README.md
```

## Fluxo GitOps

> O Ingress Controller também é gerenciado por GitOps via `apps/ingress-nginx.yaml`.

1. **CI Pipeline** (GitHub Actions) → Build, Test, Security Scan → Push image para ECR
2. **CI atualiza tag** → Abre PR/commit no repositório GitOps com nova imagem
3. **ArgoCD monitora** → Detecta mudança no repositório GitOps
4. **ArgoCD sincroniza** → Aplica as mudanças no cluster EKS automaticamente

## Vantagens

- ✅ Single source of truth (manifests no Git)
- ✅ Rollback fácil (git revert)
- ✅ Auditoria completa (git history)
- ✅ Deploy declarativo e automático
- ✅ Visibilidade via ArgoCD UI
