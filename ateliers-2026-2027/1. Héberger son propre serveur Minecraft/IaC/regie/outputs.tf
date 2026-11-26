output "regie_ip" {
  value = openstack_compute_instance_v2.regie.access_ip_v4
}

output "domain" {
  value = local.domain
}

output "rw_user" {
  value = "postes"
}

output "rw_password" {
  value     = random_password.rw.result
  sensitive = true
}

output "urls" {
  value = {
    mur     = "https://mur.${local.domain}"
    grafana = "https://grafana.${local.domain}"
    jeu     = "https://jeu.${local.domain}"
  }
}
