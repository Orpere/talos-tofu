resource "proxmox_vm_qemu" "control-plane" {
  count       = var.cp_count
  name        = "cp-${var.name}${count.index}"
  target_node = "pve"
  cores       = var.cp_cores
  sockets     = 1
  memory      = var.cp_memory
  agent       = 1
  bios        = "seabios"
  boot        = "order=scsi0;ide2;net0"
  hotplug     = "network,disk,usb"
  qemu_os     = "l26"
  cpu_type    = "x86-64-v2-AES"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  skip_ipv6   = true

  # Network config
  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
  }
  # Disk config
  disks {
    scsi {
      scsi0 {
        disk {
          size      = var.cp_disk_size
          storage   = "local"
          format    = "qcow2"
          iothread  = true
          backup    = true
          replicate = true
        }
      }
    }

    # CD-ROM ISO (cloud-init or installer)
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/talos.iso"
        }
      }
    }
  }
}

