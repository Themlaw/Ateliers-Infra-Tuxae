terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
    }

    random = {
      source  = "hashicorp/random"
    }

    ovh = {
      source  = "ovh/ovh"
    }

    local = {
      source  = "hashicorp/local"
    }
    
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3/"
  domain_name = "default"
  
  tenant_name = var.OPENSTACK_TENANT_NAME
  user_name   = var.OPENSTACK_USER_NAME
  region      = var.OPENSTACK_REGION
  password    = var.OPEN_STACK_PASSWORD
}

provider "ovh" {
  endpoint           = var.OVH_ENDPOINT
  application_key    = var.OVH_APPLICATION_KEY
  application_secret = var.OVH_APPLICATION_SECRET
  consumer_key       = var.OVH_CONSUMER_KEY
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}