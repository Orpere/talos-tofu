#!/bin/bash
set -e

# Label worker nodes
echo "Labeling worker nodes..."
kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" get nodes --no-headers | grep -v control-plane | awk '{print $1}' | xargs -I{} kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" label node {} node-role.kubernetes.io/worker= --overwrite

echo "install nginx-ingress"
kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
echo "create namespace metallb"
kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" create namespace metallb-system || true
echo "install metallb"
kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
exho "Waiting for MetalLB to be ready..."
command sleep 60
# Create a ConfigMap for MetalLB
echo "Creating MetalLB ConfigMap..."
cat <<EOF | kubectl --kubeconfig="$TALOS_MANIFESTS_DIR/kubeconfig" apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.0.151-192.168.0.220
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: home
  namespace: metallb-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.0.151-192.168.0.220
EOF
echo "MetalLB ConfigMap created."