PLEASE FEEL FREE TO GET YOUR CLUSTER DETAILS BELOW:

   Control plane IP: ${control_plane_ip}
   Kubeconfig path: ${kubeconfig_path}
   Talos configuration path: ${talosconfig_path}
   Cluster name: ${cluster_name}
   Worker IPs: ${worker_ips}
   Control Plane IPs: ${control_plane_ips}

To access your Kubernetes cluster, run:
   export KUBECONFIG=${kubeconfig_path}
   kubectl get nodes

To use the DNS you have configured, your A records are:
${dns_records}