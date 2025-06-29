#create a talos cluster 

resource "null_resource" "talos_config" {

  provisioner "local-exec" {
    command = "talosctl gen config ${var.name} https://${var.control_planes_ips[0]}:${var.control_plane_port} --output-dir clusters_configs/${var.name} --force"
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




resource "null_resource" "wait_for_k8s_nodes" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export KUBECONFIG=${path.cwd}/clusters_configs/${var.name}/kubeconfig

      # List of expected nodes (IPs or hostnames)
      expected_nodes="${join(" ", concat(var.control_planes_ips, var.worker_ips))}"

      echo "Waiting for all Kubernetes nodes to be Ready..."
      for i in {1..60}; do
        ready_nodes=$(kubectl get nodes --no-headers | awk '$2 == "Ready" {print $1}' | wc -l)
        total_nodes=$(echo $expected_nodes | wc -w)
        if [ "$ready_nodes" -eq "$total_nodes" ]; then
          echo "All $total_nodes nodes are Ready."
          break
        fi
        echo "Ready nodes: $ready_nodes/$total_nodes. Waiting 10s and retrying... ($i/60)"
        sleep 10
        if [ $i -eq 60 ]; then
          echo "Timeout waiting for all nodes to be Ready."
          exit 1
        fi
      done

      # Run your kubectl command here, for example:
      kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}' | xargs -I{} kubectl label node {} node-role.kubernetes.io/worker-node= --overwrite
    EOT
  }
  depends_on = [null_resource.talos_kubeconfig]
}

resource "null_resource" "install_apps" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export KUBECONFIG=${path.cwd}/clusters_configs/${var.name}/kubeconfig

      # Install a Helm chart (example: nginx-ingress)
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo update
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

      # Apply a Kubernetes manifest
      kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
      kubectl apply -f manifests/metallb_config.yaml
    EOT
  }
  depends_on = [null_resource.wait_for_k8s_nodes]
}