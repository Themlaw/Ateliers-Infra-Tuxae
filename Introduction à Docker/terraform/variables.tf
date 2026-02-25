variable "number_vm" {
  description = "Le nombre de machines virtuelles à créer pour l'atelier"
  type        = number
  default     = 2 # Par défaut à 2 pour tester, vous pourrez l'augmenter pour l'atelier
}

variable "cloudflare_api_token" {
  description = "Le token d'API Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "L'ID de la zone Cloudflare pour le domaine"
  type        = string
}

variable "domain_name" {
  description = "Le nom de domaine de base (ex: themlaw.dev)"
  type        = string
  default     = "themlaw.dev"
}

# --- Variables d'authentification OVH ---

variable "OVH_ENDPOINT" {
  description = "Point d'entrée de l'API OVH"
  type        = string
  default     = "ovh-eu"
}

variable "OVH_APPLICATION_KEY" {
  description = "Clé d'application API OVH"
  type        = string
  sensitive   = true
}

variable "OVH_APPLICATION_SECRET" {
  description = "Secret d'application API OVH"
  type        = string
  sensitive   = true
}

variable "OVH_CONSUMER_KEY" {
  description = "Clé consommateur API OVH"
  type        = string
  sensitive   = true
}

# --- Variables d'authentification OpenStack ---

variable "OPENSTACK_TENANT_NAME" {
  description = "Nom du tenant OpenStack (ID du projet OVH)"
  type        = string
}

variable "OPENSTACK_USER_NAME" {
  description = "Nom de l'utilisateur OpenStack"
  type        = string
}

variable "OPENSTACK_REGION" {
  description = "Région de l'infrastructure OpenStack (ex: EU-WEST-PAR)"
  type        = string
  default     = "GRA9"
}

variable "OPEN_STACK_PASSWORD" {
  description = "Mot de passe de l'utilisateur OpenStack"
  type        = string
  sensitive   = true
}

variable "vm_user_number" {
  description = "Le nombre d'utilisateurs par machine virtuelle (tuxae-1, tuxae-2, ...)"
  type        = number
  default     = 1
}

variable "OPEN_STACK_IMAGE_NAME" {
  description = "Type d'image utilisé pour la vm"
  type        = string
  default     = "Debian 12"
}

variable "OPEN_STACK_FLAVOR_NAME" {
  description = "Type de flavor utilisé pour la vm"
  type        = string
  default     = "d2-2"
}