
variable "name" {
  type    = string
  default = "talos-cluster"
}

variable "control_plane_port" {
  type    = number
  default = 6443
}

variable "control_planes_ips" {
  type    = list(string)
  default = []
}
variable "worker_ips" {
  type    = list(string)
  default = []
}
