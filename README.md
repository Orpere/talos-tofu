# talos-tofu
to get the iso on this tutorial please follow [talos instructions](https://www.talos.dev/v1.10/talos-guides/install/virtualized-platforms/proxmox/)

[this module use opentofu and the telmate provider for proxmox](https://search.opentofu.org/provider/telmate/proxmox/latest)

follow the instructions on the link above and export yur proxmox credentials

```bash
export PM_USER="terraform-prov@pve"
export PM_PASS="password"
```

change your main vars

```bash
module "talos-proxmox" {
  source = "./talos-proxmox"
  # Cluster configuration
  name = "talos"

  # Control Plane Configuration
  cp_count     = 1
  cp_cores     = 4
  cp_memory    = 2048 # in MB
  cp_disk_size = 80   # in GB

  # Worker Node Configuration
  worker_count     = 1
  worker_cores     = 8
  worker_memory    = 8196 # in MB
  worker_disk_size = 100  # in GB
}
```

run the follow to deploy

```bash
tofu apply 
```

it will give you the output for your control planes and workers with details to reserv ips on your dhcp

```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

control-planes = [
  "cp-talos0 - 192.168.0.78 - bc:24:11:56:02:7f",
]
workers = [
  "worker-talos0 - 192.168.0.56 - bc:24:11:07:57:5f",
]
```

after reserv the ips **you must restart the instances** and they will get the new ips
run tofu refresh and it will add the new ips to the state

```bash
Outputs:

control-planes = [
  "cp-talos0 - 192.168.0.100 - bc:24:11:56:02:7f",
]
workers = [
  "worker-talos0 - 192.168.0.101 - bc:24:11:07:57:5f",
]
```
