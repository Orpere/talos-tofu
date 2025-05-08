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

## dns

## Install tallos

create dns with tofu

```bash
export TF_VAR_key_secret="your_real_secret_here"
tofu init 
tofu apply
```

check your dns

```zsh
ping worker-talos0.orp-dev.eu                                                                                                                                                                                                                                   ✔  13:51:58  
PING worker-talos0.orp-dev.eu (192.168.0.103): 56 data bytes
64 bytes from 192.168.0.103: icmp_seq=0 ttl=63 time=120.798 ms
64 bytes from 192.168.0.103: icmp_seq=1 ttl=63 time=5.557 ms
64 bytes from 192.168.0.103: icmp_seq=2 ttl=63 time=13.288 ms
64 bytes from 192.168.0.103: icmp_seq=3 ttl=63 time=61.285 ms
^C
--- worker-talos0.orp-dev.eu ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 5.557/50.232/120.798/45.996 ms
```

## create a cluster  

```txt
control-planes
cp-talos0 - 192.168.0.100 - bc:24:11:6d:81:07
cp-talos1 - 192.168.0.101 - bc:24:11:3a:4c:7a
cp-talos2 - 192.168.0.102 - bc:24:11:12:9f:5d
workers
worker-talos0 - 192.168.0.103 - bc:24:11:53:3b:10
worker-talos1 - 192.168.0.104 - bc:24:11:64:ab:3e
```

## create a config
