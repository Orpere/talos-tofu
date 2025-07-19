module "talos-proxmox" {
  source           = "./talos-proxmox"
  name             = "talos"
  cp_count         = 1
  cp_cores         = 8
  cp_memory        = 8196
  cp_disk_size     = 80
  worker_count     = 3
  worker_cores     = 8
  worker_memory    = 9216
  worker_disk_size = 100
  prox_cir         = "192.168.0"
  talos_image      = "talos-v1.10.5-factory.iso"
}

module "dns" {
  source        = "./tofu-dns"
  dns_server    = "192.168.0.254"
  key_algorithm = "hmac-sha512"
  key_name      = "orp-dns." # <-- trailing dot is correct
  zone          = "orp-dev.eu." # <-- trailing dot is correct
  key_secret    = var.key_secret
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
  tsig_secret          = var.key_secret
  tsig_keyname         = var.tsig_keyname
  cloudflare_api_token = var.cloudflare_api_token
}
