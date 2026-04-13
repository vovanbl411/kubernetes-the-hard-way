resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24-04-base"
  pool   = "default"
  source = var.base_image_path
  format = "qcow2"
}

resource "libvirt_volume" "k8s_disk" {
  for_each       = var.k8s_nodes
  name           = "${each.key}-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 21474836480
}

resource "libvirt_cloudinit_disk" "commoninit" {
  for_each  = var.k8s_nodes
  name      = "commoninit-${each.key}.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_key  = file(var.ssh_public_key_path)
    hostname = each.key
  })
}

resource "libvirt_domain" "k8s_node" {
  for_each = var.k8s_nodes
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  network_interface {
    network_name   = libvirt_network.k8s_network.name
    hostname       = each.key
    mac            = each.value.mac
    addresses      = [each.value.ip]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.k8s_disk[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  depends_on = [libvirt_network.k8s_network]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    nodes = var.k8s_nodes
  })
  filename = "${path.module}/../ansible/inventory.ini"

  # Ждем, пока домены будут созданы, прежде чем писать файл
  depends_on = [libvirt_domain.k8s_node]
}
