resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# Apply configuration to all control plane nodes
resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = { for idx, cp in var.control_planes : idx => cp }
  node                        = each.value.ip
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  client_configuration        = talos_machine_secrets.this.client_configuration
}

# Apply configuration to all worker nodes
resource "talos_machine_configuration_apply" "worker" {
  for_each                    = { for idx, worker in var.workers : idx => worker }
  node                        = each.value.ip
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.this.client_configuration
}


# Bootstrap the Kubernetes cluster on the first control plane node
resource "talos_machine_bootstrap" "main" {
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "main" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for cp in var.control_planes : cp.ip]
}

resource "talos_cluster_kubeconfig" "main" {
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = "https://${var.control_plane_ip}:6443"
  depends_on = [
    talos_machine_bootstrap.main,
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ] 
}