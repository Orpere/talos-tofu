module "talos-proxmox" {
  source = "./talos-proxmox"
  # Cluster configuration
  name = "talos"

  # Control Plane Configuration
  cp_count     = 1
  cp_cores     = 8
  cp_memory    = 8196 # in MB
  cp_disk_size = 80   # in GB

  # Worker Node Configuration
  worker_count     = 3
  worker_cores     = 8
  worker_memory    = 8196 # in MB
  worker_disk_size = 100  # in GB
}
# DNS Configuration
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

# Talos Cluster
module "cluster-talos" {
  source             = "./cluster-talos"
  name               = "talos-cluster"
  depends_on         = [module.talos-proxmox, module.dns]
  control_planes_ips = module.talos-proxmox.control_plane_info[*].ip
  control_plane_port = 6443
  worker_ips         = module.talos-proxmox.worker_info[*].ip
}
