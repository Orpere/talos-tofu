terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc01"  # Use the available RC version
      # Note: telmate/proxmox provider doesn't have GPG keys in registry
      # Signature validation warnings are expected and safe to ignore
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://pve.${var.prox_domain}:8006/api2/json"
  pm_tls_insecure = true # i have gen my certs on letsencrypt using cf plugin and acme
}

