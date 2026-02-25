output "instances_info" {
  description = "Informations de connexion pour chaque instance"
  # Utilisation de nonsensitive() pour forcer l'affichage dans le terminal
  value = var.vm_user_number == 1 ? [
    # Cas 1 utilisateur : utilisateur root
    for i in range(var.number_vm) : {
      name     = openstack_compute_instance_v2.docker_vm_instance[i].name
      domain   = "${cloudflare_dns_record.docker_instances[i].name}.${var.domain_name}"
      ip       = openstack_compute_instance_v2.docker_vm_instance[i].access_ip_v4
      user     = "root"
      password = nonsensitive(random_password.tuxae_passwords[i].result)
    }
  ] : flatten([
    # Cas plusieurs utilisateurs : utilisateurs tuxae-1, tuxae-2, etc.
    for i in range(var.number_vm) : [
      for j in range(var.vm_user_number) : {
        name     = "${openstack_compute_instance_v2.docker_vm_instance[i].name}-user-${j + 1}"
        domain   = "${cloudflare_dns_record.docker_instances[i].name}.${var.domain_name}"
        ip       = openstack_compute_instance_v2.docker_vm_instance[i].access_ip_v4
        user     = "tuxae-${j + 1}"
        password = nonsensitive(random_password.tuxae_passwords[i * var.vm_user_number + j].result)
      }
    ]
  ])
}

# Génération automatique d'un fichier CSV contenant les accès
resource "local_sensitive_file" "instances_csv" {
  filename = "${path.module}/instances_config.csv"
  content = var.vm_user_number == 1 ? (
    # Cas 1 utilisateur : utilisateur root
    "Nom,Domaine,IP,Utilisateur,Mot de passe\n${join("\n", [
      for i in range(var.number_vm) :
      "${openstack_compute_instance_v2.docker_vm_instance[i].name},${cloudflare_dns_record.docker_instances[i].name}.${var.domain_name},${openstack_compute_instance_v2.docker_vm_instance[i].access_ip_v4},root,${random_password.tuxae_passwords[i].result}"
    ])}"
  ) : (
    # Cas plusieurs utilisateurs : utilisateurs tuxae-1, tuxae-2, etc.
    "Nom,Domaine,IP,Utilisateur,Mot de passe\n${join("\n", flatten([
      for i in range(var.number_vm) : [
        for j in range(var.vm_user_number) :
        "${openstack_compute_instance_v2.docker_vm_instance[i].name}-user-${j + 1},${cloudflare_dns_record.docker_instances[i].name}.${var.domain_name},${openstack_compute_instance_v2.docker_vm_instance[i].access_ip_v4},tuxae-${j + 1},${random_password.tuxae_passwords[i * var.vm_user_number + j].result}"
      ]
    ]))}"
  )
}