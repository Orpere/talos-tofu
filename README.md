# � Talos Kubernetes Cluster on Proxmox

This project automates the deployment of a Talos Kubernetes cluster on Proxmox VE using Terraform/OpenTofu. It includes automated DNS management via RFC2136 and optional Cloudflare integration for Let's Encrypt certificates.

## 🆕 What's New

### Recent Updates & Features

- **🔐 External Secrets Operator**: Added comprehensive secrets management with support for multiple backends (AWS, Azure, GCP, HashiCorp Vault, etc.)
- **📊 Interactive Architecture Diagrams**: Complete C4 model diagrams with Mermaid that render automatically in VS Code
- **📖 Enhanced Documentation**:
  - Detailed architecture documentation (`ARCHITECTURE.md`)
  - Interactive C4 diagrams (`architecture-c4-diagram.md`)
  - Comprehensive CLI command guides for Talos and ArgoCD
- **🔧 Improved Helm Management**: Helmfile-based deployment for consistent application management
- **🧪 Test Environment**: Added test manifests for SSL/non-SSL configurations and sample applications
- **⚙️ Automation Scripts**: Proxmox template creator script for streamlined setup
- **🔄 Lifecycle Management**: Enhanced cluster lifecycle management and configuration handling
- **📝 Template Improvements**: Dynamic placeholders for easier customization

### Latest Integrations

- **External Secrets v0.18.2**: Advanced secret synchronization and management
- **Cert-Manager v1.18.0**: Latest certificate automation and management
- **Nginx Ingress v4.10.1**: Updated ingress controller with latest features
- **External DNS v1.16.1**: Enhanced DNS automation and provider support

## 📋 Features

- **Automated Talos cluster deployment** on Proxmox VE
- **DNS management** via RFC2136 (TSIG)
- **ArgoCD integration** for GitOps
- **Cert-manager** with Cloudflare DNS01 challenge support
- **External Secrets Operator** for secure secrets management
- **External DNS** for automatic DNS record management
- **MetalLB** for load balancing
- **Nginx Ingress Controller**
- **Comprehensive documentation** with interactive C4 diagrams

## 🔧 Architecture

This configuration deploys:

- <control_plane_count> control plane nodes (<cp_cores> cores, <cp_memory_gb>GB RAM, <cp_disk_gb>GB disk)
- <worker_count> worker nodes (<worker_cores> cores, <worker_memory_gb>GB RAM, <worker_disk_gb>GB disk)
- DNS records for all nodes
- Kubernetes cluster with essential add-ons

### 📊 Architecture Diagrams

For detailed architecture visualization and component relationships, see:

- **[📋 Architecture Overview](./ARCHITECTURE.md)** - Complete architecture documentation with setup guide
- **[🎯 C4 Diagrams](./architecture-c4-diagram.md)** - Interactive Mermaid diagrams showing system context, containers, and components

**💡 Quick View:** Open the diagram files in VS Code and press `Ctrl+Shift+V` (Windows/Linux) or `Cmd+Shift+V` (macOS) to see interactive diagrams with automatic rendering.

### `main.tf` Overview

```hcl
module "talos-proxmox" {
  source           = "./talos-proxmox"
  name             = "<cluster_name>"
  cp_count         = <control_plane_node_count>
  cp_cores         = <control_plane_cpu_cores>
  cp_memory        = <control_plane_memory_mb>
  cp_disk_size     = <control_plane_disk_gb>
  worker_count     = <worker_node_count>
  worker_cores     = <worker_cpu_cores>
  worker_memory    = <worker_memory_mb>
  worker_disk_size = <worker_disk_gb>
}

module "dns" {
  source        = "./tofu-dns"
  dns_server    = "<dns_server_ip>"
  key_algorithm = "<tsig_algorithm>"
  key_name      = "<tsig_key_name>"
  zone          = "<dns_zone>"
  key_secret    = var.key_secret
  records = merge(
    { for idx, obj in module.talos-proxmox.control_plane_info : "cp-talos${idx}" => obj.ip },
    { for idx, obj in module.talos-proxmox.worker_info : "worker-talos${idx}" => obj.ip }
  )
}

module "cluster-talos" {
  source               = "./cluster-talos"
  name                 = "<cluster_name>"
  control_plane_port   = <kubernetes_api_port>
  control_planes_ips   = module.talos-proxmox.control_plane_info[*].ip
  worker_ips           = module.talos-proxmox.worker_info[*].ip
  depends_on           = [module.talos-proxmox, module.dns]
  tsig_secret          = var.key_secret
  tsig_keyname         = var.tsig_keyname
  cloudflare_api_token = var.cloudflare_api_token
}
```

## 🔧 Prerequisites

- **Proxmox VE** with API access
- **Talos OS template** available in Proxmox
- **DNS server** supporting RFC2136 (TSIG) updates
- **Terraform/OpenTofu** installed
- **kubectl** and **talosctl** CLI tools

---

## 🔐 Required Variables

The following variables need to be set as environment variables with the `TF_VAR_` prefix:

### 📄 Environment Variables

```bash
# Required: DNS TSIG configuration
export TF_VAR_key_secret="<your_base64_tsig_secret>"
export TF_VAR_tsig_keyname="<your_tsig_key_name>"

# Optional: Cloudflare API token for cert-manager DNS01 challenge
export TF_VAR_cloudflare_api_token="<your_cloudflare_api_token>"
```

### 📄 Alternative: `.env` File Example

```dotenv
# DNS (RFC2136) - Required
TF_VAR_key_secret=<your_base64_tsig_secret>
TF_VAR_tsig_keyname=<your_tsig_key_name>

# Cloudflare - Optional (for SSL certificates)
TF_VAR_cloudflare_api_token=<your_cloudflare_api_token>
```

Load the `.env` file:

```bash
set -a
source .env
set +a
```

---

## 🛠️ Usage

### Step 1: Initialize Terraform/OpenTofu

```bash
tofu init
```

### Step 2: Plan the Deployment

```bash
tofu plan
```

### Step 3: Deploy the Infrastructure

```bash
tofu apply -auto-approve
```

---

## 🧪 Validate Cluster

After successful deployment:

### Access the Cluster

```bash
export KUBECONFIG=./clusters_configs/<cluster_name>/kubeconfig
kubectl get nodes
```

### Verify Talos Configuration

```bash
export TALOSCONFIG=./clusters_configs/<cluster_name>/talosconfig
talosctl get members
```

### Check ArgoCD

```bash
kubectl get pods -n argocd
```

### ArgoCD CLI Commands

After the cluster is deployed, you can use these useful ArgoCD CLI commands:

#### Initial Setup and Login

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI (use admin and the password from above)
argocd login localhost:8080 --username admin --password <admin-password> --insecure
```

#### Application Management

```bash
# List all applications
argocd app list

# Get application details
argocd app get <app-name>

# Sync an application
argocd app sync <app-name>

# Create a new application
argocd app create <app-name> \
  --repo <git-repo-url> \
  --path <path-to-manifests> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace <namespace>

# Delete an application
argocd app delete <app-name>
```

#### Configuration and Context

```bash
# View current ArgoCD config
argocd config get-contexts

# Switch ArgoCD context
argocd context <context-name>

# View cluster information
argocd cluster list

# Add a new cluster
argocd cluster add <cluster-context-name>
```

#### Monitoring and Troubleshooting

```bash
# View application logs
argocd app logs <app-name>

# View application history
argocd app history <app-name>

# Rollback application
argocd app rollback <app-name> <revision-id>

# View application resources
argocd app resources <app-name>

# Refresh application (fetch latest from Git)
argocd app refresh <app-name>
```

#### Repository Management

```bash
# List repositories
argocd repo list

# Add a repository
argocd repo add <repo-url> --username <username> --password <password>

# Remove a repository
argocd repo rm <repo-url>
```

**ArgoCD UI Access:** `https://localhost:8080` (after port-forward)

### Talos CLI Commands

Useful Talos commands for cluster management and troubleshooting:

#### Talos Configuration and Context

```bash
# Set Talos config (if not using environment variable)
export TALOSCONFIG=./clusters_configs/<cluster_name>/talosconfig

# View current Talos config
talosctl config info

# List available contexts
talosctl config contexts

# Switch context
talosctl config context <context-name>

# Set endpoint and node
talosctl config endpoint <control-plane-ip>
talosctl config node <node-ip>
```

#### Cluster Information

```bash
# Get cluster members
talosctl get members

# Check cluster health
talosctl health

# Get cluster info
talosctl cluster show

# View etcd members
talosctl etcd members

# Get Kubernetes version
talosctl version
```

#### Node Management

```bash
# List all nodes
talosctl get nodes

# Get node details
talosctl get node <node-name>

# Reboot a node
talosctl reboot --nodes <node-ip>

# Shutdown a node
talosctl shutdown --nodes <node-ip>

# Upgrade Talos on nodes
talosctl upgrade --nodes <node-ip> --image <talos-image>
```

#### System Information

```bash
# View system information
talosctl get system-info

# Check running services
talosctl get services

# View system logs
talosctl logs

# Follow logs for a specific service
talosctl logs --follow <service-name>

# Get disk usage
talosctl get disks

# View network interfaces
talosctl get links
```

#### Kubernetes Integration

```bash
# Generate kubeconfig
talosctl kubeconfig <output-directory>

# Get kubeconfig and set KUBECONFIG
talosctl kubeconfig ~/.kube/config

# Bootstrap etcd cluster (only run once)
talosctl bootstrap

# Apply machine configuration
talosctl apply-config --file <config-file> --nodes <node-ip>
```

#### Troubleshooting

```bash
# View all resources
talosctl get all

# Check network connectivity
talosctl get routes
talosctl get addresses

# View container logs
talosctl logs kubelet
talosctl logs etcd

# Interactive shell (if enabled)
talosctl shell --nodes <node-ip>

# Copy files to/from node
talosctl cp <local-file> <node-ip>:<remote-path>
talosctl cp <node-ip>:<remote-path> <local-file>
```

#### Configuration Files Locations

**Talos Configuration:**

- **Local project config:** `./clusters_configs/<cluster_name>/talosconfig`
- **Global user config:** `~/.talos/config`
- **Environment variable:** `$TALOSCONFIG`

**Generated Files:**

- **Control plane config:** `./clusters_configs/<cluster_name>/controlplane.yaml`
- **Worker config:** `./clusters_configs/<cluster_name>/worker.yaml`
- **Kubernetes config:** `./clusters_configs/<cluster_name>/kubeconfig`

**Config Priority (highest to lowest):**

1. `--talosconfig` CLI flag
2. `$TALOSCONFIG` environment variable
3. `~/.talos/config`

---

## 📁 Project Structure

```text
├── main.tf                    # Main configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── cluster-info.tpl           # Cluster info template
├── talos-proxmox/            # Proxmox VM provisioning
├── tofu-dns/                 # DNS management (RFC2136)
├── cluster-talos/            # Talos cluster configuration
├── clusters_configs/         # Generated cluster configs
│   └── <cluster_name>/
│       ├── kubeconfig        # Kubernetes config
│       ├── talosconfig       # Talos config
│       └── *.yaml           # Node configurations
└── apps/                     # Kubernetes applications
    ├── argocd/              # ArgoCD configuration
    ├── helm/                # Helm charts
    └── manifests/           # Kubernetes manifests
```

---

## 🗑️ Cleanup

To destroy all resources:

```bash
tofu destroy -auto-approve
```

---

## 🔧 Troubleshooting

### Common Issues

1. **DNS Resolution Issues**: Ensure your DNS server supports RFC2136 and TSIG keys are correctly configured
2. **Proxmox Connection**: Verify Proxmox API credentials and network connectivity
3. **Talos Bootstrap**: Check if the Talos template is available in Proxmox

### Useful Commands

```bash
# Check Talos cluster health
talosctl health

# Get cluster info
kubectl cluster-info

# Check all pods across namespaces
kubectl get pods -A
```
