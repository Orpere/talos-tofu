# � Talos Kubernetes Cluster on Proxmox

This project automates the deployment of a Talos Kubernetes cluster on Proxmox VE using Terraform/OpenTofu. It includes automated DNS management via RFC2136 and optional Cloudflare integration for Let's Encrypt certificates.

## 📋 Features

- **Automated Talos cluster deployment** on Proxmox VE
- **DNS management** via RFC2136 (TSIG)
- **ArgoCD integration** for GitOps
- **Cert-manager** with Cloudflare DNS01 challenge support
- **MetalLB** for load balancing
- **Nginx Ingress Controller**

## 🔧 Architecture

This configuration deploys:

- <control_plane_count> control plane nodes (<cp_cores> cores, <cp_memory_gb>GB RAM, <cp_disk_gb>GB disk)
- <worker_count> worker nodes (<worker_cores> cores, <worker_memory_gb>GB RAM, <worker_disk_gb>GB disk)
- DNS records for all nodes
- Kubernetes cluster with essential add-ons

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
