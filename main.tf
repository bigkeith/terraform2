# main.tf

# Define the required providers and their versions
# We specify the 'telmate/proxmox' provider which uses the pm_* syntax.
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07" # Use a specific version for consistency, or a range.
    }
  }
}

# Configure the Proxmox provider
# These are the arguments that were causing the errors before.
# They are correct for the 'telmate/proxmox' provider.
provider "proxmox" {
  pm_api_url          = "https://192.168.1.100:8006/api2/json"
  pm_api_token_id     = "terraform@pve!terraform-token"
  pm_api_token_secret = "25bd465a-43ed-4a08-92d9-72e414f91d31"
  pm_tls_insecure     = true # Warning: Use with caution in production.
}

# This resource block will create three virtual machines.
resource "proxmox_vm_qemu" "kubernetes_node" {
  # This tells Terraform to create 3 instances of this resource.
  count = 3

  # The Proxmox node to deploy the VMs on
  target_node = "hype1"
 
  # Dynamically generate the name for each VM using the count index.
  # This will result in "kub1", "kub2", and "kub3".
  name        = format("kub%d", count.index + 1)
 
  # Dynamically generate a unique VM ID for each server, starting from 120.
  # This will result in VM IDs 120, 121, and 122.
  vmid        = 500 + count.index

  # Clone from an existing template.
  # Using the template name from your previous configuration.
  #template_vm_id = 9001
  clone = "ubuntu-cloud-template"

  memory = 2048
  cpu {
  # Hardware configuration
  cores   = 2
  sockets = 1
}
# Define the scci controller

scsihw = "virtio-scsi-pci"

# Explicitly set scsi0 as the boot disk 

boot = "order=scsi0"

  # Disk configuration
  # Using the storage and disk size from your previous configuration.
  
  disk {
    slot = "scsi0"
    type    = "disk"
    storage = "datastoreHDD1"
    size    = "20G"
  }

  # Define a disk for cloudinit
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "datastoreHDD1"
  }

  ipconfig0 = "ip=dhcp"

  # Cloud-init configuration
  os_type = "cloud-init"
 
  # Enable QEMU guest agent for better communication with the host.
  agent   = 1
 
  # Cloud-init user configuration
  ciuser     = "proxmoxuser"
  cipassword = "secure_password"
 
  # Inject an SSH public key for secure access.
  # Replace with your actual public key.
  sshkeys = <<EOT
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrriQJBn9u10LLSrlLZ7HCFSpYxcHUaJ/iqwTbMDB/2
  EOT

  # Network configuration
  # Connect the VM to the default bridge.
  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}
