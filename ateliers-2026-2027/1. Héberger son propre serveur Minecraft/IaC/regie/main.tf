
terraform {
  required_version = ">= 1.6"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "openstack" {
  auth_url         = var.os_auth_url
  user_name        = var.os_username
  password         = var.os_password
  tenant_id        = var.os_project_id
  user_domain_name = "Default"
  region           = var.os_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  domain = "${var.dns_sub}.${var.dns_zone}"
}

resource "random_password" "rw" {
  length  = 32
  special = false
}

resource "openstack_compute_keypair_v2" "admin" {
  name       = "atelier-admin"
  public_key = var.admin_ssh_public_key
}

locals {
  admin_cidrs_v4 = join(", ", [for c in var.admin_cidrs : c if !strcontains(c, ":")])
}

data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_base_name
  most_recent = true
}

resource "openstack_compute_instance_v2" "regie" {
  name            = "atelier-regie"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_name     = var.regie_flavor
  key_pair        = openstack_compute_keypair_v2.admin.name
  security_groups = ["default"]

  network {
    name = var.os_ext_net_name
  }

  user_data = <<-EOT
    #cloud-config
    hostname: regie
    package_update: true
    packages: [python3, python3-apt, nftables]
    write_files:
      - path: /etc/nftables.conf
        permissions: "0644"
        content: |
          #!/usr/sbin/nft -f
          table inet atelier
          delete table inet atelier
          table inet atelier {
            chain input {
              type filter hook input priority 0; policy drop;
              ct state established,related accept
              iif lo accept
              iifname "docker0" accept
              iifname "br-*" accept
              meta l4proto { icmp, ipv6-icmp } accept
              ip saddr { ${local.admin_cidrs_v4} } tcp dport 22 accept
              tcp dport { 80, 443 } accept
            }
          }
    runcmd:
      - [systemctl, enable, --now, nftables]
  EOT

  lifecycle {
    ignore_changes = [image_id, user_data]
  }
}

resource "cloudflare_dns_record" "apex" {
  zone_id = var.cloudflare_zone_id
  name    = local.domain
  type    = "A"
  ttl     = 60
  proxied = false
  content = openstack_compute_instance_v2.regie.access_ip_v4
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${local.domain}"
  type    = "A"
  ttl     = 60
  proxied = false
  content = openstack_compute_instance_v2.regie.access_ip_v4
}

resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/generated/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [regie]
    regie-vm ansible_host=${openstack_compute_instance_v2.regie.access_ip_v4} ansible_user=ubuntu ansible_ssh_private_key_file=${var.admin_ssh_private_key_path}
  EOT
}

resource "local_sensitive_file" "regie_vars" {
  filename        = "${path.module}/../ansible/generated/regie_vars.yml"
  file_permission = "0600"
  content = yamlencode({
    domain                 = local.domain
    acme_email             = var.acme_email
    acme_staging           = var.acme_staging
    cloudflare_api_token   = var.cloudflare_api_token
    grafana_admin_password = var.grafana_admin_password
    mur_admin_password     = var.mur_admin_password
    rw_user                = "postes"
    rw_password            = random_password.rw.result
  })
}
