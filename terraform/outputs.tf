output "k8s_nodes_ips" {
  description = "IP addresses of the provisioned Kubernetes nodes"
  value = {
    for k, v in libvirt_domain.k8s_node : k => v.network_interface[0].addresses[0]
  }
}
