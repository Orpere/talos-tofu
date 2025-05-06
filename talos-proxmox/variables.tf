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
