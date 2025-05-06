terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://pve.orp-dev.eu:8006/api2/json"
  pm_tls_insecure = true # i have gen my certs on letsencrypt using cf plugin and acme
}

