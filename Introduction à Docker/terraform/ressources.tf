resource "random_password" "tuxae_passwords" {
  count            = var.number_vm * var.vm_user_number
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "openstack_compute_instance_v2" "docker_vm_instance" {
  count       = var.number_vm
  name        = "docker_instance_${count.index + 1}"
  image_name  = var.OPEN_STACK_IMAGE_NAME
  flavor_name = var.OPEN_STACK_FLAVOR_NAME

  # On utilise uniquement le groupe de sécurité par défaut existant, sans le modifier
  security_groups = ["default"]

  network {
    name = "Ext-Net" 
  }

  # cloud-init permet de configurer l'instance au démarrage (utilisateurs, paquets, scripts)
  user_data = var.vm_user_number == 1 ? templatefile("${path.module}/docker-cloud-init.yaml.tftpl", {
    root_password = random_password.tuxae_passwords[count.index].result
    admin_email   = "tuxae@ensae.fr" # Facile à changer ici
  }) : templatefile("${path.module}/docker-cloud-init-multiple-user.yaml.tftpl", {
    passwords   = [for i in range(var.vm_user_number) : random_password.tuxae_passwords[count.index * var.vm_user_number + i].result]
    admin_email = "tuxae@ensae.fr"
  })
  lifecycle {
    ignore_changes = [
      image_name
    ]
  }
}

resource "cloudflare_dns_record" "docker_instances" {
  count   = var.number_vm
  zone_id = var.cloudflare_zone_id
  name    = "*.docker-${count.index + 1}"
  content = openstack_compute_instance_v2.docker_vm_instance[count.index].access_ip_v4
  type    = "A"
  proxied = false # Non proxy pour que le SSH fonctionne sur ce domaine (IP directe)
  ttl     = 1     # 1 équivaut à un TTL 'Automatique' sur Cloudflare
}