#!/bin/bash

# OpenBao Auto-Initialization and Unsealing Script
# This script should be run after Helm install/upgrade

set -e

NAMESPACE="${NAMESPACE:-openbao}"
SECRET_NAME="${SECRET_NAME:-openbao-init-keys}"

echo "🔐 OpenBao Auto-Initialization Script"
echo "=================================="

# Wait for OpenBao pods to be running
echo "⏳ Waiting for OpenBao pods to be running..."
while [ $(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=openbao,component=server --field-selector=status.phase=Running --no-headers | wc -l) -lt 3 ]; do
    echo "   Waiting for all 3 OpenBao pods to be running..."
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=openbao,component=server
    sleep 5
done

echo "✅ All OpenBao pods are running"

# Check if already initialized
echo "🔍 Checking OpenBao initialization status..."
if kubectl exec -n $NAMESPACE openbao-0 -- bao operator init -status -address=http://127.0.0.1:8200 2>/dev/null; then
    echo "✅ OpenBao is already initialized"
    
    # Check if secret exists
    if kubectl get secret $SECRET_NAME -n $NAMESPACE >/dev/null 2>&1; then
        echo "✅ Unseal keys secret already exists"
        
        # Try to unseal pods if they're sealed
        echo "🔓 Checking and unsealing pods if needed..."
        for pod in openbao-0 openbao-1 openbao-2; do
            if kubectl exec -n $NAMESPACE $pod -- bao status -address=http://127.0.0.1:8200 2>/dev/null | grep -q "Sealed.*true"; then
                echo "   Unsealing $pod..."
                UNSEAL_KEY_0=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.unseal_key_0}' | base64 -d)
                UNSEAL_KEY_1=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.unseal_key_1}' | base64 -d)
                UNSEAL_KEY_2=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.unseal_key_2}' | base64 -d)
                
                kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_0" >/dev/null 2>&1 || true
                kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_1" >/dev/null 2>&1 || true  
                kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_2" >/dev/null 2>&1 || true
            else
                echo "   $pod is already unsealed"
            fi
        done
    else
        echo "⚠️  OpenBao is initialized but unseal keys secret is missing!"
        exit 1
    fi
else
    echo "🚀 Initializing OpenBao..."
    
    # Initialize OpenBao
    INIT_OUTPUT=$(kubectl exec -n $NAMESPACE openbao-0 -- bao operator init -key-shares=5 -key-threshold=3 -format=json -address=http://127.0.0.1:8200)
    
    # Extract keys and token
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
    UNSEAL_KEY_0=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
    UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[1]')
    UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[2]')
    UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[3]')
    UNSEAL_KEY_4=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[4]')
    
    echo "💾 Storing initialization keys in Kubernetes secret..."
    
    # Create or update the secret
    kubectl create secret generic $SECRET_NAME -n $NAMESPACE \
      --from-literal=root_token="$ROOT_TOKEN" \
      --from-literal=unseal_key_0="$UNSEAL_KEY_0" \
      --from-literal=unseal_key_1="$UNSEAL_KEY_1" \
      --from-literal=unseal_key_2="$UNSEAL_KEY_2" \
      --from-literal=unseal_key_3="$UNSEAL_KEY_3" \
      --from-literal=unseal_key_4="$UNSEAL_KEY_4" \
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo "🔓 Unsealing OpenBao pods..."
    
    # Unseal openbao-0 first (leader)
    echo "   Unsealing openbao-0 (leader)..."
    kubectl exec -n $NAMESPACE openbao-0 -- bao operator unseal "$UNSEAL_KEY_0"
    kubectl exec -n $NAMESPACE openbao-0 -- bao operator unseal "$UNSEAL_KEY_1"  
    kubectl exec -n $NAMESPACE openbao-0 -- bao operator unseal "$UNSEAL_KEY_2"
    
    # Wait a bit for the leader to be ready
    sleep 10
    
    # Join and unseal followers
    for pod in openbao-1 openbao-2; do
        echo "   Joining and unsealing $pod..."
        
        # Join the Raft cluster
        kubectl exec -n $NAMESPACE $pod -- bao operator raft join http://openbao-0.openbao-internal:8200 || true
        sleep 5
        
        # Unseal the follower
        kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_0" || true
        kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_1" || true
        kubectl exec -n $NAMESPACE $pod -- bao operator unseal "$UNSEAL_KEY_2" || true
    done
    
    echo "✅ OpenBao initialization and unsealing completed!"
fi

# Verify cluster status
echo "🔍 Verifying cluster status..."
kubectl get pods -n $NAMESPACE

echo ""
echo "🎯 Checking Raft cluster members..."
ROOT_TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.root_token}' | base64 -d)
kubectl exec -n $NAMESPACE openbao-0 -- env BAO_TOKEN="$ROOT_TOKEN" bao operator raft list-peers -address=http://127.0.0.1:8200

echo ""
echo "🎉 OpenBao is ready! You can retrieve keys using:"
echo "   ./get_bao_keys.sh -n $NAMESPACE -s $SECRET_NAME -f json"
