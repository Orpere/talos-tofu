#create a talos cluster 

resource "null_resource" "talos_config" {
  provisioner "local-exec" {
    command = "talosctl gen config talos-cluster https://192.168.0.100:6443 --output-dir _out"
  }
}

resource "null_resource" "talos_apply_controlplane_config" {
  provisioner "local-exec" {
    command = "talosctl apply-config --insecure --nodes 192.168.0.100 --file _out/controlplane.yaml"
  }
}

resource "null_resource" "talos_bootstrap" {
  provisioner "local-exec" {
    command = "talosctl bootstrap"
  }
}

resource "null_resource" "talos_kubeconfig" {
  provisioner "local-exec" {
    command = "talosctl kubeconfig ."
  }
}



#variables

