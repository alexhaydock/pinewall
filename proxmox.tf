terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.1"
    }
  }
}

# Import the image name from our environment
#
# This gets passed in by our wrapper script and identifies
# the EFI file we want to copy over and configure the VM to boot
variable "image_name" {}

provider "proxmox" {
  endpoint = "https://cursedrouter.infected.systems:8006/"

  # Uncomment if using a self-signed Proxmox TLS cert
  # insecure = true

  # We need this configured for our file copy operations
  tmp_dir = "/tmp"
}

resource "proxmox_virtual_environment_file" "pinewall_image" {
  content_type = "iso"
  datastore_id = "local"

  # Specify node to deploy to
  node_name = "proxnet"

  source_file {
    path = "images/${var.image_name}"
  }
}

resource "proxmox_virtual_environment_vm" "pinewall_vm" {
  name        = "pinewall"
  description = "Managed by Terraform"
  tags        = ["alpine", "terraform", "direct-efi-boot"]

  # Specify node to deploy to, VMID and auto-boot status
  node_name       = "proxnet"
  vm_id           = 200
  on_boot         = true
  stop_on_destroy = true

  # Ensure we copy our EFI image first before trying to start the VM
  depends_on = [proxmox_virtual_environment_file.pinewall_image]

  # The magic that allows us to do direct EFI boot in Proxmox
  kvm_arguments = "-kernel /var/lib/vz/template/iso/${var.image_name}"

  # Enables UEFI firmware (needed to boot an EFI binary)
  bios = "ovmf"

  cpu {
    cores = 4
    type  = "x86-64-v3" # defaults to `qemu64` if we don't specify
  }

  memory {
    dedicated = 2048
    floating  = 0 # disables ballooning
  }

  # WAN Interface
  network_device {
    bridge = "vmbr3"
  }

  # LAN Interface
  network_device {
    bridge = "vmbr4"
  }

  operating_system {
    type = "l26" # Linux 2.6+
  }

  # Attach a VirtIO RNG to the VM
  # We seemingly need to be "root@pam" to do this
  rng {
    source = "/dev/urandom"
  }

  # Attach a serial device and use it as our console output
  # in the Proxmox WebUI
  serial_device {}
  vga {
    type = "serial0"
  }
}
