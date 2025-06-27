module "talos-proxmox" {
  source = "./talos-proxmox"
  # Cluster configuration
  name = "talos"

  # Control Plane Configuration
  cp_count     = 3
  cp_cores     = 8
  cp_memory    = 8196 # in MB
  cp_disk_size = 80   # in GB

  # Worker Node Configuration
  worker_count     = 2
  worker_cores     = 8
  worker_memory    = 8196 # in MB
  worker_disk_size = 100  # in GB
}

output "control-planes" {
  value = module.talos-proxmox.control_plane_info
}

output "workers" {
  value = module.talos-proxmox.worker_info
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
