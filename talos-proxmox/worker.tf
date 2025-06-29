resource "proxmox_vm_qemu" "worker" {
  depends_on  = [proxmox_vm_qemu.control-plane]
  count       = var.worker_count
  name        = "worker-${var.name}${count.index}"
  target_node = "pve"
  memory      = var.worker_memory
  agent       = 1
  bios        = "seabios"
  boot        = "order=scsi0;ide2;net0"
  hotplug     = "network,disk,usb"
  qemu_os     = "l26"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  skip_ipv6   = true
  # Cloud-init configuration
  ciupgrade    = true
  nameserver   = var.nameserver
  ipconfig0    = "ip=${var.prox_cir}.${111 + count.index}/24,gw=${var.prox_cir}.1"
  searchdomain = var.prox_domain
  sshkeys      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUYEeHSldG9XylMGNduRhSXSPMWAOnuiWIuSYSEroRm orlando.capoeiraraiz@gmail.com"


  # Network config
  cpu {
    cores = var.worker_cores
    # You can add more CPU options here if needed
  }
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
          size      = var.worker_disk_size
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
      ide1 {
        cloudinit {
          storage = "local"
        }
      }
      ide2 {
        cdrom {
          iso = "local:iso/${var.talos_image}"
        }
      }
    }
  }
}
