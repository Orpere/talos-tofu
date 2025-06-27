#!/bin/bash

set -e

# Check for --force flag
FORCE_FLAG=""
if [[ "$1" == "--force" ]]; then
    FORCE_FLAG="--force"
    echo "Force overwrite enabled for talosctl gen config."
fi

# Warn if config files already exist and --force not set
if [[ -f $TALOS_MANIFESTS_DIR/controlplane.yaml && "$FORCE_FLAG" == "" ]]; then
    echo "WARNING: $TALOS_MANIFESTS_DIR/controlplane.yaml already exists."
    echo "Use --force to overwrite existing manifests."
    exit 1
fi

# Generate Talos config
echo "Generating Talos config..."
talosctl gen config $TALOS_CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 --output-dir $TALOS_MANIFESTS_DIR $FORCE_FLAG
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file $TALOS_MANIFESTS_DIR/controlplane.yaml --timeout 5m

# Wait for Talos API to become available before bootstrapping etcd
echo "Waiting for Talos API on $CONTROL_PLANE_IP:50000 to become available..."
for i in {1..30}; do
    if nc -z $CONTROL_PLANE_IP 50000; then
        echo "Talos API is available."
        break
    fi
    echo "Talos API not available yet. Retrying in 10 seconds... ($i/30)"
    command sleep 10
    if [ $i -eq 30 ]; then
        echo "Talos API did not become available in time. Exiting."
        exit 1
    fi
done

# Set Talos config environment variable
export TALOSCONFIG="$TALOS_MANIFESTS_DIR/talosconfig"

# Configure talosctl endpoints and nodes
echo "Configuring talosctl endpoints and nodes..."
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP

# Bootstrap etcd
echo "Bootstrapping etcd..."
talosctl bootstrap
command sleep 300



# Apply config to worker nodes one by one with retry
IFS=',' read -ra WK_IPS <<< "$WORKER_IPS"
for ip in "${WK_IPS[@]}"; do
    echo "Applying config to worker node $ip..."
    until talosctl apply-config --insecure --nodes "$ip" --file $TALOS_MANIFESTS_DIR/worker.yaml --timeout 5m; do
        echo "Failed to apply config to worker node $ip. Retrying in 120 seconds..."
        command sleep 120
    done
done

# Get kubeconfig
echo "Retrieving kubeconfig..."
talosctl kubeconfig $TALOS_MANIFESTS_DIR/.

# Wait for all nodes to be healthy before continuing
ALL_NODES=(${CONTROL_PLANE_IPS//,/ } ${WORKER_IPS//,/ })
echo "Checking health of all nodes: ${ALL_NODES[*]}"
while true; do
    HEALTHY=0
    for ip in "${ALL_NODES[@]}"; do
        STATUS=$(talosctl -n "$ip" health | grep -E 'health: (true|false)' | awk '{print $2}')
        if [[ "$STATUS" == "true" ]]; then
            echo "Node $ip is healthy."
            ((HEALTHY++))
        else
            echo "Node $ip is not healthy yet."
        fi
    done
    if [[ $HEALTHY -eq ${#ALL_NODES[@]} ]]; then
        echo "All nodes are healthy. Continuing..."
        break
    fi
    echo "Waiting 15 seconds before rechecking node health..."
    command sleep 15
done

# Get kubeconfig
echo "Retrieving kubeconfig..."
talosctl kubeconfig $TALOS_MANIFESTS_DIR/.

# Apply config to control plane nodes (excluding the first IP)
IFS=',' read -ra CP_IPS <<< "$CONTROL_PLANE_IPS"
for ((i=1; i<${#CP_IPS[@]}; i++)); do
    ip="${CP_IPS[$i]}"
    echo "Applying config to control plane node $ip..."
    until talosctl apply-config --insecure --nodes "$ip" --file $TALOS_MANIFESTS_DIR/controlplane.yaml --timeout 5m; do
        echo "Failed to apply config to $ip. Retrying in 120 seconds..."
        command sleep 120
    done
done
 
echo "Talos cluster setup complete!"