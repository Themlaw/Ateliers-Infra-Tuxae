
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

data "terraform_remote_state" "regie" {
  backend = "local"
  config = {
    path = "${path.module}/../regie/terraform.tfstate"
  }
}

locals {
  domain   = "${var.dns_sub}.${var.dns_zone}"
  regie_ip = data.terraform_remote_state.regie.outputs.regie_ip
  postes   = { for i in range(1, var.nb_postes + 1) : format("poste-%02d", i) => format("%02d", i) }
}

locals {
  regions   = length(var.postes_regions) > 0 ? var.postes_regions : [var.os_region]
  region_de = { for nom, num in local.postes : nom => lookup(var.poste_region, nom, local.regions[0]) }
}

data "openstack_images_image_v2" "poste" {
  for_each    = toset(values(local.region_de))
  region      = each.key
  name        = var.image_poste_name
  most_recent = true
}

resource "random_password" "eleve" {
  for_each = local.postes
  length   = 10
  special  = false
  upper    = false
}

resource "random_password" "token" {
  for_each = local.postes
  length   = 32
  special  = false
}

resource "openstack_compute_instance_v2" "poste" {
  for_each        = local.postes
  name            = each.key
  region          = local.region_de[each.key]
  image_id        = data.openstack_images_image_v2.poste[local.region_de[each.key]].id
  flavor_name     = var.poste_flavor
  security_groups = ["default"]

  network {
    name = var.os_ext_net_name
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    poste             = each.key
    regie_ip          = local.regie_ip
    password          = random_password.eleve[each.key].result
    token             = random_password.token[each.key].result
    domain            = local.domain
    jeu               = var.jeu
    minecraft_version = var.minecraft_version
    tls_insecure      = var.acme_staging
    rw_user           = data.terraform_remote_state.regie.outputs.rw_user
    rw_password       = data.terraform_remote_state.regie.outputs.rw_password
  })
}

resource "cloudflare_dns_record" "poste" {
  for_each = local.postes
  zone_id  = var.cloudflare_zone_id
  name     = "${each.key}.${local.domain}"
  type     = "A"
  ttl      = 60
  proxied  = false
  content  = openstack_compute_instance_v2.poste[each.key].access_ip_v4
}

locals {
  liste = [for nom, num in local.postes : {
    nom       = nom
    num       = num
    ip        = openstack_compute_instance_v2.poste[nom].access_ip_v4
    password  = random_password.eleve[nom].result
    token_sha = sha256(random_password.token[nom].result)
  }]
}

resource "local_file" "postes_json" {
  filename        = "${path.module}/../ansible/generated/postes.json"
  file_permission = "0644"
  content = jsonencode({
    jeu    = var.jeu
    domain = local.domain
    postes = [for p in local.liste : { nom = p.nom, num = p.num, ip = p.ip, token_sha256 = p.token_sha }]
  })
}

resource "local_file" "traefik_postes" {
  filename        = "${path.module}/../ansible/generated/traefik-postes.yml"
  file_permission = "0644"
  content = templatefile("${path.module}/traefik-postes.yml.tftpl", {
    domain            = local.domain
    jeu               = var.jeu
    minecraft_version = var.minecraft_version
    postes            = local.liste
  })
}

resource "local_sensitive_file" "identifiants_csv" {
  filename        = "${path.module}/../identifiants.csv"
  file_permission = "0600"
  content = join("\n", concat(
    ["poste;terminal;utilisateur;mot_de_passe;jeu"],
    [for p in local.liste : join(";", [
      p.nom,
      "https://term-${p.num}.${local.domain}",
      "eleve",
      p.password,
      var.jeu == "classicube" ? "https://jeu.${local.domain}/?serveur=${p.num}" : "https://jeu-${p.num}.${local.domain}",
    ])]
  ))
}

resource "local_sensitive_file" "fiches_html" {
  filename        = "${path.module}/../fiches.html"
  file_permission = "0600"
  content = templatefile("${path.module}/fiches.html.tftpl", {
    domain = local.domain
    jeu    = var.jeu
    postes = local.liste
  })
}
