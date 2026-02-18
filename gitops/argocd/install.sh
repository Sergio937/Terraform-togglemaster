#!/bin/bash
# Script de instalação e configuração do ArgoCD

set -euo pipefail

ARGOCD_NAMESPACE="argocd"
ARGOCD_INSTALL_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

decode_base64() {
    if command -v base64 >/dev/null 2>&1; then
        if base64 --help 2>/dev/null | grep -q -- "-d"; then
            base64 -d
        else
            base64 --decode
        fi
    else
        python3 - <<'PY'
import base64
import sys
print(base64.b64decode(sys.stdin.read()).decode(), end="")
PY
    fi
}

echo "=========================================="
echo "  ArgoCD Installation & Setup"
echo "=========================================="
echo ""

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Instale kubectl primeiro."
    exit 1
fi

# Verificar conexão com cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Não foi possível conectar ao cluster Kubernetes."
    echo "Configure o kubectl com: aws eks update-kubeconfig --name <cluster-name> --region <region>"
    exit 1
fi

echo "✅ Conectado ao cluster Kubernetes"
echo ""

# 1. Criar namespace argocd
echo "1️⃣  Criando namespace 'argocd'..."
kubectl create namespace "$ARGOCD_NAMESPACE" 2>/dev/null || echo "   Namespace já existe"
echo ""

# 2. Instalar ArgoCD
echo "2️⃣  Instalando ArgoCD..."
kubectl apply --server-side --force-conflicts -n "$ARGOCD_NAMESPACE" -f "$ARGOCD_INSTALL_MANIFEST_URL"

echo "   Validando CRDs do ArgoCD..."
kubectl wait --for=condition=Established --timeout=180s crd/applications.argoproj.io
kubectl wait --for=condition=Established --timeout=180s crd/appprojects.argoproj.io
kubectl wait --for=condition=Established --timeout=180s crd/applicationsets.argoproj.io

echo "   Aguardando pods do ArgoCD ficarem prontos (isso pode levar alguns minutos)..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n "$ARGOCD_NAMESPACE"
kubectl wait --for=condition=available --timeout=600s deployment/argocd-applicationset-controller -n "$ARGOCD_NAMESPACE"

echo "✅ ArgoCD instalado com sucesso!"
echo ""

# 3. Obter senha do admin
echo "3️⃣  Obtendo senha inicial do admin..."
ARGOCD_PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | decode_base64)

echo ""
echo "=========================================="
echo "  Credenciais do ArgoCD"
echo "=========================================="
echo "Usuário: admin"
echo "Senha: $ARGOCD_PASSWORD"
echo ""
echo "⚠️  IMPORTANTE: Salve esta senha!"
echo "=========================================="
echo ""

# 4. Perguntar sobre exposição do serviço
echo "4️⃣  Como deseja acessar o ArgoCD?"
echo "   1) Port Forward (desenvolvimento - localhost:8080)"
echo "   2) LoadBalancer (produção - IP externo)"
echo "   3) Pular por enquanto"
echo ""
read -p "Escolha uma opção (1-3): " EXPOSE_OPTION

case $EXPOSE_OPTION in
    1)
        echo ""
        echo "Iniciando port-forward..."
        echo "ArgoCD estará disponível em: https://localhost:8080"
        echo "Use Ctrl+C para parar"
        echo ""
        kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443
        ;;
    2)
        echo ""
        echo "Configurando LoadBalancer..."
        kubectl patch svc argocd-server -n "$ARGOCD_NAMESPACE" -p '{"spec": {"type": "LoadBalancer"}}'
        
        echo "Aguardando IP externo..."
        sleep 10
        
        EXTERNAL_HOSTNAME=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        EXTERNAL_IP=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        if [ -n "$EXTERNAL_HOSTNAME" ]; then
            echo "✅ ArgoCD disponível em: https://$EXTERNAL_HOSTNAME"
        elif [ -n "$EXTERNAL_IP" ]; then
            echo "✅ ArgoCD disponível em: https://$EXTERNAL_IP"
        else
            echo "⏳ LoadBalancer ainda está sendo provisionado."
            echo "Execute para verificar: kubectl get svc argocd-server -n argocd"
        fi
        ;;
    3)
        echo "Você pode acessar mais tarde com:"
        echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
        ;;
    *)
        echo "Opção inválida"
        ;;
esac

echo ""
echo "=========================================="
echo "  Próximos Passos"
echo "=========================================="
echo ""
echo "1. Acesse a UI do ArgoCD e faça login"
echo ""
echo "2. Edite as Applications em gitops/apps/ com a URL do seu repositório:"
echo "   sed -i 's|<seu-usuario>/<seu-repo>|seu-usuario/seu-repo|g' gitops/apps/*.yaml"
echo ""
echo "3. Aplique as Applications:"
echo "   kubectl apply -f gitops/apps/"
echo ""
echo "4. Verifique no ArgoCD UI ou com:"
echo "   kubectl get applications -n argocd"
echo ""
echo "=========================================="
echo "  Instalação Concluída! 🎉"
echo "=========================================="
