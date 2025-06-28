terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.1"
    }
  }
}

# Import the primary IP of this node from our environment
# vars, so we can use it to transfer the file to the destination
# host without being root on the Proxmox host
variable "deployment_host_ip" {}

provider "proxmox" {
  endpoint = "{{ prox_url }}"

  # Needed if using a self-signed Proxmox TLS cert
  insecure = {{ prox_selfsigned }}
}
