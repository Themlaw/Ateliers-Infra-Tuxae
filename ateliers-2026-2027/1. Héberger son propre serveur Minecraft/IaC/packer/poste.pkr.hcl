
packer {
  required_plugins {
    openstack = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

variable "os_auth_url" { type = string }
variable "os_username" { type = string }
variable "os_password" {
  type      = string
  sensitive = true
}
variable "os_project_id" { type = string }
variable "os_region" { type = string }
variable "os_ext_net_name" {
  type    = string
  default = "Ext-Net"
}
variable "os_ext_net_id" { type = string }
variable "image_base_name" {
  type    = string
  default = "Ubuntu 24.04"
}
variable "image_poste_name" {
  type    = string
  default = "atelier-poste"
}
variable "packer_flavor" {
  type    = string
  default = "d2-4"
}
variable "minecraft_version" {
  type    = string
  default = "1.21.4"
}

source "openstack" "poste" {
  identity_endpoint = var.os_auth_url
  username          = var.os_username
  password          = var.os_password
  tenant_id         = var.os_project_id
  domain_name       = "Default"
  region            = var.os_region

  source_image_name = var.image_base_name
  flavor            = var.packer_flavor
  networks          = [var.os_ext_net_id]
  ssh_username      = "ubuntu"
  ssh_ip_version    = "4"

  image_name = var.image_poste_name
  metadata = {
    atelier = "tuxae-infra"
  }
}

build {
  sources = ["source.openstack.poste"]

  provisioner "shell" {
    inline = ["mkdir -p /tmp/atelier /tmp/mcgalaxy"]
  }

  provisioner "file" {
    source      = "files/"
    destination = "/tmp/atelier"
  }

  provisioner "file" {
    source      = "../mcgalaxy/"
    destination = "/tmp/mcgalaxy"
  }

  provisioner "shell" {
    execute_command  = "sudo {{ .Vars }} bash '{{ .Path }}'"
    environment_vars = ["MC_VERSION=${var.minecraft_version}"]
    scripts = [
      "scripts/01-base.sh",
      "scripts/02-jeux.sh",
      "scripts/03-quetes.sh",
      "scripts/99-nettoyage.sh",
    ]
  }
}
