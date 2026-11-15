terraform {
  required_version = ">= 1.10"
  backend "s3" {
    key                         = "homelab/alexa"
    encrypt                     = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 3.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
