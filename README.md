## 🔧 Terraform/OpenTofu Configuration

### `main.tf` Overview

```hcl
module "talos-proxmox" {
  source           = "./talos-proxmox"
  name             = "talos"
  cp_count         = 3
  cp_cores         = 8
  cp_memory        = 8196
  cp_disk_size     = 80
  worker_count     = 3
  worker_cores     = 8
  worker_memory    = 8196
  worker_disk_size = 100
}

module "dns" {
  source        = "./tofu-dns"
  dns_server    = var.dns_server
  key_algorithm = var.dns_key_algorithm
  key_name      = var.dns_key_name
  key_secret    = var.dns_key_secret
  zone          = var.dns_zone

  records = merge(
    { for idx, obj in module.talos-proxmox.control_plane_info : "cp-talos${idx}" => obj.ip },
    { for idx, obj in module.talos-proxmox.worker_info : "worker-talos${idx}" => obj.ip }
  )
}

module "cluster-talos" {
  source               = "./cluster-talos"
  name                 = "talos-cluster"
  control_plane_port   = 6443
  control_planes_ips   = module.talos-proxmox.control_plane_info[*].ip
  worker_ips           = module.talos-proxmox.worker_info[*].ip
  depends_on           = [module.talos-proxmox, module.dns]
  tsig_secret          = var.dns_key_secret
  tsig_keyname         = var.dns_key_name
  cloudflare_api_token = var.cloudflare_api_token
}
```

---

## 🔐 Required Variables

Create a `.env` file with the following content (or export as `TF_VAR_` environment variables):

### 📄 `.env` Example

```dotenv
# Proxmox
TF_VAR_proxmox_api_url=https://proxmox.local:8006
TF_VAR_proxmox_user=root@pam
TF_VAR_proxmox_password=your_password
TF_VAR_proxmox_node=proxmox-node
TF_VAR_vm_template=talos-template

# DNS (RFC2136)
TF_VAR_dns_server=192.168.0.254
TF_VAR_dns_zone=orp-dev.eu.
TF_VAR_dns_key_name=orp-dns.
TF_VAR_dns_key_algorithm=hmac-sha512
TF_VAR_dns_key_secret=your_base64_secret

# Cluster configuration
TF_VAR_cluster_name=talos-cluster
TF_VAR_k8s_version=v1.30.0

# Optional (Cloudflare DNS01 challenge for cert-manager)
TF_VAR_cloudflare_api_token=your_cf_token
```

Load the file:

```bash
set -a
source .env
set +a
```

---

## 🛠️ Usage

```bash
tofu init
tofu plan
tofu apply -auto-approve
```

---

## 🧪 Validate Cluster

After apply:

```bash
export KUBECONFIG=./clusters_configs/talos-cluster/kubeconfig
kubectl get nodes
```

---