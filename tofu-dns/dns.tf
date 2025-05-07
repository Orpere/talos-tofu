terraform {
  required_providers {
    dns = {
      source  = "opentofu/dns"
      version = "3.4.3"
    }
  }
}

provider "dns" {
  update {
    server        = var.dns_server
    key_name      = var.key_name
    key_algorithm = var.key_algorithm
    key_secret    = var.key_secret
  }
}

resource "dns_a_record_set" "records" {
  for_each = var.records

  zone      = var.zone
  name      = each.key
  addresses = [each.value]
  ttl       = 300
}
