packer {
  required_version = ">= 1.7.0"
  required_plugins {
    ansible = {
      version = ">= 1.1.0"
      source: "github.com/hashicorp/ansible"
    }
    vmware = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/vmware"
    }
    vsphere = {
      version = ">= 1.2.1"
      source: "github.com/hashicorp/vsphere"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = ">= 1.0.3"
    }
  }
}

variable "vagrant_box" { type = string }
variable "output_directory" { type = string }

// Ansible provisioning settings
variable "artifactory_api_key" {
  type = string
  default = env("ARTIFACTORY_API_KEY")
}
variable "artifactory_username" {
  type = string
  default =  env("USER")
}
variable "user_password" {
  type = string
  default = "vagrant"
}
variable "user_username" {
  type = string
  default = "vagrant"
}

// Basic hardware specs
variable "cpu_count" {
  type = number
  default =  "2"
}
variable "ram_gb" {
  type = number
  default =  "4"
}
variable "disk_size" {
  type = string
  default =  "500000"
}
variable "headless" {
  type    = bool
  default = false
}

// VSphere settings
variable "vmware_center_cluster_name" {
  type    = string
  default = "${env("VMWARECENTER_CLUSTER_NAME")}"
}
variable "vmware_center_datacenter" {
  type    = string
  default = "${env("VMWARECENTER_DATACENTER")}"
}
variable "vmware_center_datastore" {
  type    = string
  default = "${env("VMWARECENTER_DATASTORE")}"
}
variable "vmware_center_esxi_host" {
  type    = string
  default = "${env("VMWARECENTER_ESXI_HOST")}"
}
variable "vmware_center_host" {
  type    = string
  default = "${env("VMWARECENTER_HOST")}"
}
variable "vmware_center_password" {
  type      = string
  default   = "${env("VMWARECENTER_PASSWORD")}"
  sensitive = true
}
variable "vmware_center_username" {
  type    = string
  default = "${env("VMWARECENTER_USERNAME")}"
}
variable "vmware_center_vm_folder" {
  type    = string
  default = "${env("VMWARECENTER_VM_FOLDER")}"
}
variable "vmware_center_vm_name" {
  type    = string
  default = "${env("VMWARECENTER_VM_NAME")}"
}
variable "vmware_center_vm_network" {
  type    = string
  default = "${env("VMWARECENTER_VM_NETWORK")}"
}

// Hyper-V settings
variable "hyperv_generation" {
  type    = string
  default = "2"
}
variable "hyperv_switch" {
  type    = string
  default = "${env("hyperv_switch")}"
}

variable "preseed_path" {
  type    = string
  default = "autoinstall.yaml"
}
variable "vagrant_user_final_password" {
  type      = string
  default   = "${env("VAGRANT_USER_FINAL_PASSWORD")}"
  sensitive = true
}

source "hyperv-iso" "ubuntu" {
  boot_command       = ["<esc><wait>", "c<wait>", "set gfxpayload=keep<wait><enter>", "linux /casper/vmlinuz autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<wait><enter>", "initrd /casper/initrd<wait><enter>", "boot<enter>"]
  boot_wait          = "10s"
  communicator       = "ssh"
  cpus               = "${var.cpus}"
  disk_size          = "${var.disk_size}"
  enable_secure_boot = false
  generation         = "${var.hyperv_generation}"
  http_directory     = "${local.http_directory}"
  iso_checksum       = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url            = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory             = "${var.memory}"
  output_directory   = "${var.build_directory}/packer-${var.template}-hyperv"
  shutdown_command   = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password       = "vagrant"
  ssh_port           = 22
  ssh_timeout        = "1h"
  ssh_username       = "vagrant"
  switch_name        = "${var.hyperv_switch}"
  vm_name            = "${var.template}"
}

source "virtualbox-iso" "ubuntu" {
  boot_command            = ["<esc><wait>", "c<wait>", "set gfxpayload=keep<wait><enter>", "linux /casper/vmlinuz autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<wait><enter>", "initrd /casper/initrd<wait><enter>", "boot<enter>"]
  boot_wait               = "4s"
  cpus                    = "${var.cpus}"
  disk_size               = "${var.disk_size}"
  guest_additions_path    = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_additions_url     = "${var.guest_additions_url}"
  guest_os_type           = "Ubuntu_64"
  hard_drive_interface    = "sata"
  headless                = "${var.headless}"
  http_directory          = "${local.http_directory}"
  iso_checksum            = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url                 = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory                  = "${var.memory}"
  output_directory        = "${var.build_directory}/packer-${var.template}-virtualbox"
  shutdown_command        = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_handshake_attempts  = 20
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_timeout             = "1h"
  ssh_username            = "vagrant"
  vboxmanage              = [["modifyvm", "{{ .Name }}", "--clipboard-mode", "bidirectional"], ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"], ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"], ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "emptydrive"]]
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "${var.template}"
}

source "vmware-iso" "ubuntu" {
  boot_command         = ["<esc><wait>", "c<wait>", "set gfxpayload=keep<wait><enter>", "linux /casper/vmlinuz autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<wait><enter>", "initrd /casper/initrd<wait><enter>", "boot<enter>"]
  boot_wait            = "4s"
  cpus                 = "${var.cpus}"
  disk_size            = "${var.disk_size}"
  guest_os_type        = "ubuntu-64"
  headless             = "${var.headless}"
  http_directory       = "${local.http_directory}"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url              = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory               = "${var.memory}"
  network_adapter_type = "VMXNET3"
  output_directory     = "${var.build_directory}/packer-${var.template}-vmware"
  shutdown_command     = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password         = "vagrant"
  ssh_port             = 22
  ssh_timeout          = "1h"
  ssh_username         = "vagrant"
  tools_upload_flavor  = ""
  vm_name              = "${var.template}"
  vmx_data = {
    "cpuid.coresPerSocket"    = "1"
    "disk.EnableUUID"         = "TRUE"
    "ethernet0.pciSlotNumber" = "32"
    "virtualHW.version"       = "13"
  }
 // vmx_remove_ethernet_interfaces = "${var.vmx_remove_ethernet_interfaces}"
}

source "vsphere-iso" "ubuntu" {
  boot_command         = ["<esc><wait>", "c<wait>", "set gfxpayload=keep<wait><enter>", "linux /casper/vmlinuz autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<wait><enter>", "initrd /casper/initrd<wait><enter>", "boot<enter>"]
  vcenter_server       = "${var.vmware_center_host}"
  host                 = "${var.vmware_center_esxi_host}"
  username             = "${var.vmware_center_username}"
  password             = "${var.vmware_center_password}"
  insecure_connection  = false
  datacenter           = "${var.vmware_center_datacenter}"
  datastore            = "${var.vmware_center_datastore}"
  cluster              = "${var.vmware_center_cluster_name}"
  http_port_max        = 65535
  http_port_min        = 49152
  convert_to_template  = true
  CPUs                 = "${var.cpus}"
  disk_controller_type = ["pvscsi"]
  storage {
      disk_size = "${var.disk_size}"
      disk_thin_provisioned = true
  }
  guest_os_type        = "ubuntu64Guest"
  http_directory       = "${local.http_directory}"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url              = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  RAM                  = "${var.memory}"
  shutdown_command     = "echo 'vagrant' | sudo -S /sbin/halt -h -p"
  ssh_password         = "vagrant"
  ssh_port             = 22
  ssh_timeout          = "10000s"
  ssh_username         = "vagrant"
  vm_name              = "${var.vmware_center_vm_name}"
  network_adapters {
      network = "${var.vmware_center_vm_network}"
      network_card = "vmxnet3"
  }
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = [
    "source.hyperv-iso.ubuntu",
    "source.virtualbox-iso.ubuntu",
    "source.vmware-iso.ubuntu",
    "source.vsphere-iso.ubuntu"
  ]


  provisioner "ansible" {
    playbook_file = "./ansible_provisioning/playbook.yaml"
    galaxy_file = "./ansible_provisioning/requirements.yaml"
    roles_path = "./ansible_provisioning/roles"
    galaxy_force_install = true
    user            = "vagrant"
    use_proxy       = false
    extra_arguments = [
      "-v",
      "-e", "ansible_ssh_password=vagrant"
    ]
  }

  post-processors {

    post-processor "vagrant" {
      except = ["vsphere-iso.ubuntu"]
      output = "${var.output_directory}/${ var.vagrant_box }.${ replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop") }.box"
    }

    # Once box has been created, upload it to Artifactory
    post-processor "shell-local" {
      except = ["vsphere-iso.ubuntu"]
      command = join(" ", [
        "jf rt upload",
        "--target-props \"box_name=${ var.vagrant_box };box_provider=${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")};box_version=${ formatdate("YYYYMMDD", timestamp()) }.0\"",
        "--retries 10",
        "--access-token ${ var.artifactory_api_key }",
        "--user ${ var.artifactory_username }",
        "--url \"https://artifactory.ccdc.cam.ac.uk/artifactory\"",
        "${var.output_directory}/${var.vagrant_box}.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box",
        "ccdc-vagrant-repo/${var.vagrant_box}.${formatdate("YYYYMMDD", timestamp())}.0.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box"
      ])
    }
  }
}