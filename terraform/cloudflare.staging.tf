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
    region                        = "eu-west-2"
    endpoint                      = "https://c9234561c8f6c105de23b18d16b1d5ba.eu.r2.cloudflarestorage.com"
    skip_credentials_validation   = true
    skip_metadata_api_check       = true
    skip_region_validation        = true
    skip_requesting_account_id    = true
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
  type = string
}

import {
  to = cloudflare_ruleset.api_ratelimit
  id = "zones/${var.cloudflare_zone_id}/f815655909da4a60b8fd95d8d539a78b"
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
