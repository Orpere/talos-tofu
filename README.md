# talos-tofu

to get the iso on this tutorial please follow [talos instructions](https://www.talos.dev/v1.10/talos-guides/install/virtualized-platforms/proxmox/)

[this module use opentofu and the telmate provider for proxmox](https://search.opentofu.org/provider/telmate/proxmox/latest)

follow the instructions on the link above and export yur proxmox credentials

```bash
export PM_USER="terraform-prov@pve"
export PM_PASS="password"
```
# Talos Proxmox Terraform Module

This module provisions Talos Linux control plane and worker nodes as Proxmox VMs, with support for cloud-init and static IP assignment.

## Requirements

- Proxmox VE
- Terraform >= 1.0
- Proxmox Terraform Provider (latest)
- Talos Linux image (optionally with cloud-init extension)
- ISO uploaded to Proxmox storage (e.g. `local:iso/nocloud-amd64.iso`)

## Usage

```hcl
module "talos-proxmox" {
  source = "./talos-proxmox"
  name = "talos"

  # Control Plane
  cp_count     = 3
  cp_cores     = 8
  cp_memory    = 8196
  cp_disk_size = 80

  # Worker Nodes
  worker_count     = 2
  worker_cores     = 8
  worker_memory    = 8196
  worker_disk_size = 100
}

module "dns" {
  source        = "./tofu-dns"
  dns_server    = "ns.orp-dev.eu"
  key_algorithm = "hmac-sha512"
  key_name      = "orp-dns."
  zone          = "orp-dev.eu."
  key_secret    = var.key_secret

  records = merge(
    { for idx, obj in module.talos-proxmox.control_plane_info : "cp-talos${idx}" => obj.ip },
    { for idx, obj in module.talos-proxmox.worker_info : "worker-talos${idx}" => obj.ip }
  )
}
```

## Notable Changes

- **CPU configuration**:  
  Use the `cpu` block with `cores` for both control-plane and worker VMs:
  ```hcl
  cpu {
    cores = var.cp_cores
  }
  ```
  Remove any top-level `cores`, `vcpus`, or `sockets` arguments.

- **Static IP assignment**:  
  IPs are assigned using:
  ```hcl
  ipconfig0 = "ip=192.168.0.${100 + count.index}/24,gw=192.168.0.1"
  ```
  Adjust the range as needed.

- **Cloud-init**:  
  The VM attaches a cloud-init ISO and uses the `cloudinit` block for SSH keys and network config.

- **IPv6**:  
  Disabled by default with `skip_ipv6 = true` and no `ip6=dhcp` in `ipconfig0`.

## Formatting

To format all Terraform files recursively:
```sh
terraform fmt -recursive
```

## Outputs

- `control_plane_info`: List of objects with at least an `ip` attribute for each control plane node.
- `worker_info`: List of objects with at least an `ip` attribute for each worker node.

## Example Output

```hcl
output "control-planes" {
  value = module.talos-proxmox.control_plane_info
}

output "workers" {
  value = module.talos-proxmox.worker_info
}
```

---

**Tip:**  
If you see errors about unsupported attributes or deprecation warnings, ensure your module and provider versions are up to date and that you use the correct block/argument structure as shown above.