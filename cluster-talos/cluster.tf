#create a talos cluster 

resource "null_resource" "talos_config" {

  provisioner "local-exec" {
    command = "talosctl gen config ${var.name} https://${var.control_planes_ips[0]}:${var.control_plane_port} --output-dir clusters_configs/${var.name}"
  }
}
resource "null_resource" "talos_apply_controlplane_config" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export TALOSCONFIG=clusters_configs/${var.name}/talosconfig
      talosctl apply-config --insecure --nodes ${var.control_planes_ips[0]} --file clusters_configs/${var.name}/controlplane.yaml
    EOT
  }
  depends_on = [null_resource.talos_config]
}

resource "null_resource" "apply_config_controlplanes" {
  for_each = { for idx, ip in tolist(var.control_planes_ips) : idx => ip if idx != 0 }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export TALOSCONFIG=clusters_configs/${var.name}/talosconfig
      talosctl apply-config --insecure --nodes ${each.value} --file clusters_configs/${var.name}/controlplane.yaml --timeout 5m
    EOT
  }
  depends_on = [null_resource.talos_apply_controlplane_config]
}

resource "null_resource" "apply_config_workers" {
  for_each = { for idx, ip in var.worker_ips : idx => ip }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export TALOSCONFIG=clusters_configs/${var.name}/talosconfig
      until talosctl apply-config --insecure --nodes ${each.value} --file clusters_configs/${var.name}/worker.yaml --timeout 5m; do
        echo "Failed to apply config to worker node ${each.value}. Retrying in 120 seconds..."
        sleep 120
      done
    EOT
  }
  depends_on = [null_resource.talos_apply_controlplane_config]
}
resource "null_resource" "talos_bootstrap" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export TALOSCONFIG=clusters_configs/${var.name}/talosconfig

      # Wait for Talos endpoint to be available on port 50000
      for i in {1..30}; do
        if nc -z ${var.control_planes_ips[0]} 50000; then
          echo "Talos endpoint is available on port 50000."
          talosctl config endpoint ${var.control_planes_ips[0]}
          talosctl config node ${var.control_planes_ips[0]}
          talosctl bootstrap
          exit 0
        fi
        echo "Talos endpoint not available yet on port 50000. Retrying in 10 seconds... ($i/30)"
        sleep 10
      done

      echo "Talos endpoint did not become available on port 50000 in time. Exiting."
      exit 1
    EOT
  }
  depends_on = [null_resource.talos_apply_controlplane_config]
}

resource "null_resource" "talos_kubeconfig" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export TALOSCONFIG=clusters_configs/${var.name}/talosconfig
      talosctl config endpoint ${var.control_planes_ips[0]}
      talosctl kubeconfig  clusters_configs/${var.name}/.
    EOT
  }
  depends_on = [null_resource.talos_bootstrap]
}



