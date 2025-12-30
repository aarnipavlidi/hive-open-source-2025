terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  # https://developer.hashicorp.com/terraform/language/backend/s3#example-configuration
  backend "s3" {
    bucket                        = "hive-open-source-2025"
    key                           = "cloudflare.staging.tfstate"
    region                        = "auto" # Options: wnam, enam, weur, eeur, apac, oc, auto
    endpoints = {
        s3                        = "https://c9234561c8f6c105de23b18d16b1d5ba.eu.r2.cloudflarestorage.com"
    }
    skip_credentials_validation   = true
    skip_metadata_api_check       = true
    skip_region_validation        = true
    skip_requesting_account_id    = true
    skip_s3_checksum              = true
    use_path_style                = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type      = string
}

variable "cloudflare_zone_name" {
  type      = string
  default   = "usko.lol"
}

variable "hetzner_server_ip" {
  type      = string
  default   = "95.217.184.122"
}

resource "cloudflare_dns_record" "hive_dokploy" {
  zone_id   = var.cloudflare_zone_id
  name      = "hive-dokploy.${var.cloudflare_zone_name}"
  ttl       = 1
  type      = "A"
  comment   = "Self-hosted Dokploy application. Managed via Terraform (hive-open-source-2025)." ## Maximum 100 characters allowed only.
  content   = var.hetzner_server_ip
  proxied   = true
  tags      = [] ## Not allowed on current plan.
}

resource "cloudflare_dns_record" "hive_stg" {
  zone_id   = var.cloudflare_zone_id
  name      = "hive-stg.${var.cloudflare_zone_name}"
  ttl       = 1
  type      = "A"
  comment   = "Next.js application at staging environment. Managed via Terraform (hive-open-source-2025)." ## Maximum 100 characters allowed only.
  content   = var.hetzner_server_ip
  proxied   = true
  tags      = [] ## Not allowed on current plan.
}

resource "cloudflare_dns_record" "supabase-stg" {
  zone_id   = var.cloudflare_zone_id
  name      = "supabase-stg.${var.cloudflare_zone_name}"
  ttl       = 1
  type      = "A"
  comment   = "Supabase application at staging environment. Managed via Terraform (hive-open-source-2025)." ## Maximum 100 characters allowed only.
  content   = var.hetzner_server_ip
  proxied   = true
  tags      = [] ## Not allowed on current plan.
}

import {
  to = cloudflare_dns_record.hive_dokploy
  id = "${var.cloudflare_zone_id}/4c0c320b5453b18d45468124c539a8b2"
}

import {
  to = cloudflare_dns_record.supabase-stg
  id = "${var.cloudflare_zone_id}/d11678e31fa2e2fdb071e706a33f11ed"
}

resource "cloudflare_ruleset" "api_ratelimit" {
  zone_id     = var.cloudflare_zone_id
  name        = "Protecting API routes via ratelimiting"
  phase       = "http_ratelimit"
  kind        = "zone"

  rules = [
    {
      action = "block"
      action_parameters = {
        response = {
          content      = "You have done too many requests in a short period of time. Please wait and try again later."
          content_type = "application/json"
          status_code  = 429
        }
      }
      categories  = []
      description = "Protecting API routes via ratelimiting. Managed via Terraform (hive-open-source-2025)"
      enabled     = true
      expression  = "(http.request.uri.path wildcard r\"/api/*\")"

      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 10
        requests_per_period = 200
        mitigation_timeout  = 10
        requests_to_origin  = false
      }
    }
  ]
}
