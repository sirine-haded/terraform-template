##Provider

provider "vsphere" {

  user           = var.user
  password       = var.password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

##Data

data "vsphere_datacenter" "dc" {
  name = var.name_dc
}

# If you don't have any resource pools, put "/Resources" after cluster name
data "vsphere_resource_pool" "pool" {
  name          = var.name_rp
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = var.name_vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name          = var.name_vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = "Ubuntu-Template-S"
  datacenter_id = data.vsphere_datacenter.dc.id
}



##vSphere VMs

# Set vm parameters
resource "vsphere_virtual_machine" "demo" {
  count = "3"
  name             = "VM-Test_pfe-${count.index + 1}"
  num_cpus         = 4
  memory           = 4096
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type


  network_interface {
    network_id = data.vsphere_network.network.id


  }



  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
  }


  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        domain    = "cloud-temple.lan"
        host_name = "VM-Test-pfe"
      }
      network_interface {
        ipv4_address = "10.203.18.${20 +count.index}"
        ipv4_netmask = "24"
        dns_domain = "8.8.8.8"
      }
      ipv4_gateway = "10.203.18.254"
    }
}

 

  }





