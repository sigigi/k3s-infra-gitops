#!/usr/bin/env bash
# ─────────────────────────────────────────────
# CONFIGURABLE VARIABLES
# ─────────────────────────────────────────────
K3S_VERSION="v1.33.1+k3s1"
ARGOCD_VERSION="v3.0.6"
ARGOCD_SERVICE_DOMAIN="argocd.office"

set -euo pipefail

# ─────────────────────────────────────────────
# COLOR LOGGING FUNCTIONS
# ─────────────────────────────────────────────
info()    { echo -e "\033[0;34m▶ $* \033[0m"; }
success() { echo -e "\033[0;32m✅ $* \033[0m"; }
warn()    { echo -e "\033[0;33m⏳ $* \033[0m"; }
error()   { echo -e "\033[0;31m❌ $* \033[0m"; }

info "Installing K3s ${K3S_VERSION}"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

info "Creating 'argocd' namespace"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

info "Downloading Argo CD ${ARGOCD_VERSION} manifest"
curl -sSL -o /tmp/argocd-install.yaml \
  "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

info "Applying Argo CD manifest"
kubectl apply -n argocd -f /tmp/argocd-install.yaml

info "Detecting Traefik version (via CRD group)..."
for i in {1..20}; do
  if kubectl get crd ingressroutes.traefik.io &>/dev/null; then
    TRAEFIK_API_VERSION="traefik.io/v1alpha1"
    break
  elif kubectl get crd ingressroutes.traefik.containo.us &>/dev/null; then
    TRAEFIK_API_VERSION="traefik.containo.us/v1alpha1"
    break
  else
     warn "Waiting for IngressRoute CRDs..."
    sleep 3
  fi
done

if [[ -z "${TRAEFIK_API_VERSION:-}" ]]; then
  error "Failed to detect Traefik CRD. Aborting."
  exit 1
fi

success "Detected Traefik API version: ${TRAEFIK_API_VERSION}"

kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

info "Creating IngressRoute on 'argocd-server' "
cat <<EOF | kubectl apply -f -
apiVersion: ${TRAEFIK_API_VERSION}
kind: IngressRoute
metadata:
  name: argocd-ingress
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host("${ARGOCD_SERVICE_DOMAIN}")
      kind: Rule
      services:
        - name: argocd-server
          port: 80
  tls: {}
EOF

info "Waiting for Argo CD server pod to be ready..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=120s

kubectl -n argocd get configmap argocd-cmd-params-cm -o yaml | grep server.insecure

info "Printing initial admin password"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo

success "Done! Access Argo CD via: https://${ARGOCD_SERVICE_DOMAIN}"

