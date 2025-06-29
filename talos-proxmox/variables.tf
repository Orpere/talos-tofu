variable "packages" {
  type    = list(string)
  default = ["git", "curl", "htop", "talosctl"]
}


variable "name" {
  description = "cluster name"
  type        = string
  default     = "talos"
}
# control-plane
variable "cp_count" {
  description = "number of control plane nodes"
  type        = number
  default     = 1
}
variable "cp_cores" {
  description = "number of cores"
  type        = number
  default     = 4
}
variable "cp_memory" {
  description = "memory in MB"
  type        = number
  default     = 2048
}
variable "cp_disk_size" {
  description = "disk size in GB"
  type        = number
  default     = 80
}
# worlkers
variable "worker_count" {
  description = "number of control plane nodes"
  type        = number
  default     = 1
}
variable "worker_cores" {
  description = "number of cores"
  type        = number
  default     = 4
}
variable "worker_memory" {
  description = "memory in MB"
  type        = number
  default     = 2048
}
variable "worker_disk_size" {
  description = "disk size in GB"
  type        = number
  default     = 80
}

variable "prox_cir" {
  description = "Proxmox range for IP allocation"
  type        = string
  default     = "192.168.0"
}

variable "nameserver" {
  description = "Nameserver for server"
  type        = string
  default     = "192.168.0.254"
}

variable "talos_image" {
  description = "Talos image to use"
  type        = string
  default     = "nocloud-amd64.iso"
  
}