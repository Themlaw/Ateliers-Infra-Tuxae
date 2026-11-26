
variable "os_auth_url" { type = string }
variable "os_username" { type = string }
variable "os_password" {
  type      = string
  sensitive = true
}
variable "os_project_id" { type = string }
variable "os_region" { type = string }
variable "postes_regions" {
  type    = list(string)
  default = []
}
variable "poste_region" {
  type    = map(string)
  default = {}
}
variable "os_ext_net_name" {
  type    = string
  default = "Ext-Net"
}
variable "os_ext_net_id" {
  type    = string
  default = ""
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
variable "cloudflare_zone_id" { type = string }

variable "dns_zone" { type = string }
variable "dns_sub" { type = string }
variable "acme_email" { type = string }
variable "acme_staging" {
  type    = bool
  default = true
}

variable "admin_ssh_public_key" { type = string }
variable "admin_ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}
variable "admin_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "regie_flavor" {
  type    = string
  default = "d2-8"
}
variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
variable "mur_admin_password" {
  type      = string
  sensitive = true
}

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

variable "nb_postes" {
  type    = number
  default = 25
}
variable "poste_flavor" {
  type    = string
  default = "d2-4"
}
variable "jeu" {
  type    = string
  default = "classicube"
  validation {
    condition     = contains(["classicube", "minecraft"], var.jeu)
    error_message = "jeu doit valoir \"classicube\" ou \"minecraft\"."
  }
}
variable "minecraft_version" {
  type    = string
  default = "1.21.4"
}
