variable "key_secret" {
  type        = string
  description = "TSIG key secret"
  sensitive   = true
}

variable "tsig_keyname" {
  type        = string
  description = "TSIG key name"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
}