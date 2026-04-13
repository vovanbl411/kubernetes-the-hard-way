k8s_nodes = {
  "controller-0" = { ip = "10.0.0.10", mac = "52:54:00:00:00:10", vcpu = 2, memory = 2048, role = "controller" }
  "controller-1" = { ip = "10.0.0.11", mac = "52:54:00:00:00:11", vcpu = 2, memory = 2048, role = "controller" }
  "controller-2" = { ip = "10.0.0.12", mac = "52:54:00:00:00:12", vcpu = 2, memory = 2048, role = "controller" }
  "worker-0"     = { ip = "10.0.0.20", mac = "52:54:00:00:00:20", vcpu = 2, memory = 2048, role = "worker" }
  "worker-1"     = { ip = "10.0.0.21", mac = "52:54:00:00:00:21", vcpu = 2, memory = 2048, role = "worker" }
  "worker-2"     = { ip = "10.0.0.22", mac = "52:54:00:00:00:22", vcpu = 2, memory = 2048, role = "worker" }
}
