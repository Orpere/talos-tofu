variable "dns_server" {
  type        = string
  description = "The DNS server address (e.g., ns.orp-dev.eu)"
}

variable "key_algorithm" {
  type        = string
  description = "TSIG key algorithm (e.g., hmac-sha512)"
}

variable "key_name" {
  type        = string
  description = "TSIG key name (e.g., orp-dns.)"

  validation {
    condition     = can(regex("\\.$", var.key_name))
    error_message = "The key_name must be a fully-qualified name ending with a dot (e.g., 'orp-dns.')."
  }
}


variable "key_secret" {
  type        = string
  description = "TSIG key secret"
  sensitive   = true
}

variable "zone" {
  type        = string
  description = "DNS zone (e.g., orp-dev.eu.)"
}

variable "records" {
  type        = map(string)
  description = "Map of A records (e.g., name = IP)"
}
