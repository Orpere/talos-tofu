variable "control_plane_ip" {
  description = "The IP address of the first control plane node"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Talos cluster"
  type        = string
  default     = "my-talos-cluster"
}
variable "talos_config_path" {
  description = "The version of Talos to use"
  type        = string
  default     = "~/.talos/config"

}

variable "control_planes" {
  description = "List of control plane nodes with their IPs"
  type = list(object({
    ip = string
  }))
}
variable "client_certificate" {
  description = "Path to the client certificate for Kubernetes API access"
  type        = string
  default     = "~/.talos/client.crt"
}
variable "client_key" {
  description = "Path to the client key for Kubernetes API access"
  type        = string
  default     = "~/.talos/client.key"
}
variable "cluster_ca_certificate" {
  description = "Path to the cluster CA certificate for Kubernetes API access"
  type        = string
  default     = "~/.talos/ca.crt"
}

variable "workers" {
  description = "List of worker nodes with their IPs"
  type = list(object({
    ip = string
  }))

}
